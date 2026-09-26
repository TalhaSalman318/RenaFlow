const PatientProfile = require('../models/PatientProfile');
const Bed = require('../models/Bed');
const Appointment = require('../models/Appointment');
const RecurringSchedule = require('../models/RecurringSchedule');
const Session = require('../models/Session');
const User = require('../models/User');
const mongoose = require('mongoose');
const { broadcastBedStatus } = require('../sockets/bed.socket');

const validationError = message => Object.assign(new Error(message), { statusCode: 400, code: 'VALIDATION_ERROR' });

const me = async (req, res, next) => {
  try {
    if (req.user.role !== 'patient') {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'A patient account is required.' },
        requestId: req.requestId
      });
    }
    const authenticatedUserId = req.user.id || req.user._id;
    const patient = await PatientProfile.findOne({
      userId: authenticatedUserId,
    })
      .populate('assignedBedId', 'bedNumber bedCode status')
      .populate({
        path: 'recurringSchedules',
        match: { status: 'active' },
        populate: { path: 'bedId', select: 'bedNumber bedCode' }
      });
    if (!patient) {
      return res.status(404).json({
        success: false,
        error: { code: 'PATIENT_NOT_FOUND', message: 'Patient profile was not found.' },
        requestId: req.requestId
      });
    }
    res.json({ success: true, data: { patient }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const nextMedicalId = async () => {
  const year = new Date().getFullYear();
  const count = await PatientProfile.countDocuments();
  const nextIdNumber = count + 1;
  return `PT-${year}-${String(nextIdNumber).padStart(4, '0')}`;
};

const list = async (req, res, next) => {
  try {
    const patients = await PatientProfile.find()
      .populate('userId', 'fullName email medicalId phone')
      .populate('assignedBedId', 'bedNumber bedCode status')
      .populate('recurringSchedules')
      .sort({ fullName: 1 });
    res.json({ success: true, data: { patients }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const create = async (req, res, next) => {
  try {
    const { fullName, phone, gender, bloodGroup = 'Unknown', password } = req.body;
    if (!fullName?.trim() || !phone?.trim() || !gender || !password) {
      throw validationError('fullName, phone, gender, and password are required.');
    }
    if (password.length < 8) throw validationError('Password must be at least 8 characters long.');
    const normalizedGender = gender.toLowerCase().replace(/\s+/g, '_');
    if (!['male', 'female', 'other', 'not_provided'].includes(normalizedGender)) {
      throw validationError('gender must be male, female, other, or not_provided.');
    }

    const medicalId = await nextMedicalId();

    const createdUser = await User.create({
      medicalId,
      passwordHash: password,
      role: 'patient',
      displayName: fullName.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      isActive: true
    });

    const createdProfile = await PatientProfile.create({
      patientId: medicalId,
      userId: createdUser._id,
      fullName: fullName.trim(),
      phone: phone.trim(),
      bloodGroup: bloodGroup.trim(),
      gender: normalizedGender,
      age: 0,
      dryWeightKg: 0,
      vascularAccessType: 'other',
      baselineBloodPressure: { systolic: 120, diastolic: 80 },
      emergencyContact: { name: fullName.trim(), phone: phone.trim() }
    });

    createdUser.patientProfileId = createdProfile._id;
    await createdUser.save();

    const populatedProfile = await PatientProfile.findById(createdProfile._id)
      .populate('userId', 'fullName email medicalId phone')
      .populate('assignedBedId', 'bedNumber bedCode status')
      .populate('recurringSchedules');
    const populatedUser = await User.findById(createdUser._id)
      .select('fullName email medicalId phone role displayName patientProfileId');

    res.status(201).json({
      success: true,
      data: {
        medicalId,
        password,
        patient: populatedProfile,
        user: { id: populatedUser._id, role: populatedUser.role, displayName: populatedUser.displayName, fullName: populatedUser.fullName, email: populatedUser.email, medicalId: populatedUser.medicalId, phone: populatedUser.phone }
      },
      requestId: req.requestId
    });
  } catch (error) {
    if (error.code === 11000) {
      error.statusCode = 409;
      error.message = 'A patient with those credentials already exists.';
    }
    next(error);
  }
};

const update = async (req, res, next) => {
  try {
    const patientQuery = mongoose.isValidObjectId(req.params.patientId)
      ? { _id: req.params.patientId }
      : { patientId: String(req.params.patientId).toUpperCase() };
    const patient = await PatientProfile.findOne(patientQuery);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient was not found.', requestId: req.requestId });
    }

    const { fullName, phone, bloodGroup, emergencyContact, notes } = req.body;
    if (fullName !== undefined) {
      if (!String(fullName).trim()) throw validationError('fullName cannot be empty.');
      patient.fullName = String(fullName).trim();
    }
    if (phone !== undefined) {
      if (!String(phone).trim()) throw validationError('phone cannot be empty.');
      patient.phone = String(phone).trim();
    }
    if (bloodGroup !== undefined) patient.bloodGroup = String(bloodGroup).trim();
    if (notes !== undefined) patient.notes = String(notes).trim();
    if (emergencyContact !== undefined) {
      const contact = typeof emergencyContact === 'string'
        ? { name: patient.emergencyContact.name, phone: emergencyContact.trim() }
        : emergencyContact;
      if (!contact?.name?.trim() || !contact?.phone?.trim()) {
        throw validationError('Emergency contact name and phone are required.');
      }
      patient.emergencyContact = { name: contact.name.trim(), phone: contact.phone.trim() };
    }

    if (Object.prototype.hasOwnProperty.call(req.body, 'assignedBedId')) {
      const oldBedId = patient.assignedBedId;
      const requestedBed = req.body.assignedBedId;
      let nextBed = null;
      if (requestedBed !== null && requestedBed !== '') {
        const isObjectId = mongoose.isValidObjectId(requestedBed);
        nextBed = await Bed.findOne(isObjectId
          ? { _id: requestedBed }
          : { bedNumber: Number(String(requestedBed).replace(/^Bed\\s+/i, '')) });
        if (!nextBed) throw validationError('The selected bed was not found.');
        if (nextBed.currentPatientId && nextBed.currentPatientId.toString() !== patient._id.toString()) {
          throw Object.assign(validationError('The selected bed is assigned to another patient.'), { statusCode: 409 });
        }
        if (nextBed.status !== 'vacant' && nextBed.currentPatientId?.toString() !== patient._id.toString()) {
          throw Object.assign(validationError('The selected bed is not available.'), { statusCode: 409 });
        }
      }

      const activeSchedules = await RecurringSchedule.find({ patientId: patient._id, status: 'active' })
        .select('_id shift selectedDays');
      const previousBedId = oldBedId?.toString() || null;
      const selectedBedId = nextBed?._id.toString() || null;
      const bedIsChanging = previousBedId !== selectedBedId;
      if (bedIsChanging) {
        const activeSession = await Session.exists({
          patientId: patient._id,
          status: { $in: ['active', 'running', 'paused', 'delayed'] }
        });
        if (activeSession) {
          throw Object.assign(validationError('Stop the active dialysis session before changing the assigned bed.'), { statusCode: 409 });
        }
      }
      if (bedIsChanging && activeSchedules.length && !nextBed) {
        throw Object.assign(validationError('Cancel active schedules before removing the assigned bed.'), { statusCode: 409 });
      }
      if (bedIsChanging && nextBed) {
        for (const schedule of activeSchedules) {
          const shiftVariants = [schedule.shift, schedule.shift.toLowerCase(), schedule.shift[0].toUpperCase() + schedule.shift.slice(1).toLowerCase()];
          const collision = await RecurringSchedule.findOne({
            _id: { $ne: schedule._id },
            status: 'active',
            bedId: nextBed._id,
            shift: { $in: shiftVariants },
            selectedDays: { $in: schedule.selectedDays }
          });
          if (collision) {
            throw Object.assign(validationError('The selected bed conflicts with an existing shift schedule.'), { statusCode: 409 });
          }
        }
      }

      if (bedIsChanging && oldBedId) {
        const releasedBed = await Bed.findOneAndUpdate(
          { _id: oldBedId, currentPatientId: patient._id },
          { $set: { currentPatientId: null, status: 'vacant' } },
          { new: true }
        );
        if (releasedBed) broadcastBedStatus(releasedBed);
      }
      patient.assignedBedId = nextBed?._id || null;
      if (nextBed) {
        if (bedIsChanging) {
          for (const schedule of activeSchedules) {
            await RecurringSchedule.updateOne({ _id: schedule._id }, { $set: { bedId: nextBed._id } });
            await Appointment.updateMany(
              { recurringScheduleId: schedule._id, status: { $nin: ['completed', 'cancelled'] } },
              { $set: { bedId: nextBed._id } }
            );
          }
        }
        nextBed.currentPatientId = patient._id;
        nextBed.status = 'occupied';
        nextBed.alertReason = null;
        await nextBed.save();
      }
    }

    await patient.save();
    await User.updateOne(
      { _id: patient.userId },
      { $set: { fullName: patient.fullName, displayName: patient.fullName, phone: patient.phone } }
    );

    const updatedPatient = await PatientProfile.findById(patient._id)
      .populate('userId', 'fullName email medicalId phone')
      .populate('assignedBedId', 'bedNumber bedCode status')
      .populate('recurringSchedules');
    if (patient.assignedBedId) {
      const assignedBed = await Bed.findById(patient.assignedBedId)
        .populate('currentPatientId', 'patientId fullName phone gender bloodGroup');
      if (assignedBed) broadcastBedStatus(assignedBed);
    }
    res.json({ success: true, data: { patient: updatedPatient }, requestId: req.requestId });
  } catch (error) {
    if (error.statusCode === 400 || error.statusCode === 409 || error.name === 'ValidationError' || error.name === 'CastError') {
      const statusCode = error.statusCode || 400;
      return res.status(statusCode).json({
        success: false,
        error: { code: statusCode === 409 ? 'CONFLICT' : 'VALIDATION_ERROR', message: error.message },
        requestId: req.requestId
      });
    }
    next(error);
  }
};

module.exports = { me, list, create, update };