const PatientProfile = require('../models/PatientProfile');
const PatientSequence = require('../models/PatientSequence');
const User = require('../models/User');
const mongoose = require('mongoose');

const validationError = message => Object.assign(new Error(message), { statusCode: 400, code: 'VALIDATION_ERROR' });

const nextMedicalId = async session => {
  const year = new Date().getFullYear();
  const sequence = await PatientSequence.findOneAndUpdate(
    { year },
    { $inc: { value: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: true, session }
  );
  return `PT-${year}-${String(sequence.value).padStart(4, '0')}`;
};

const list = async (req, res, next) => {
  try {
    const patients = await PatientProfile.find()
      .populate('assignedBedId', 'bedNumber bedCode status')
      .sort({ fullName: 1 });
    res.json({ success: true, data: { patients }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const create = async (req, res, next) => {
  let session;
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

    session = await mongoose.startSession();
    let createdUser;
    let createdProfile;
    let medicalId;
    await session.withTransaction(async () => {
      medicalId = await nextMedicalId(session);
      [createdUser] = await User.create([{
        medicalId,
        passwordHash: password,
        role: 'patient',
        displayName: fullName.trim(),
        isActive: true
      }], { session });
      [createdProfile] = await PatientProfile.create([{
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
      }], { session });
      createdUser.patientProfileId = createdProfile._id;
      await createdUser.save({ session });
    });

    res.status(201).json({
      success: true,
      data: {
        medicalId,
        password,
        patient: createdProfile,
        user: { id: createdUser._id, role: createdUser.role, displayName: createdUser.displayName }
      },
      requestId: req.requestId
    });
  } catch (error) {
    if (error.code === 11000) {
      error.statusCode = 409;
      error.message = 'A patient with those credentials already exists.';
    }
    next(error);
  } finally {
    if (session) await session.endSession();
  }
};

module.exports = { list, create };