const mongoose = require('mongoose');

const Appointment = require('../models/Appointment');
const Bed = require('../models/Bed');
const PatientProfile = require('../models/PatientProfile');
const RecurringSchedule = require('../models/RecurringSchedule');
const User = require('../models/User');
const logger = require('../config/logger');

const requestError = (message, statusCode = 400) => Object.assign(new Error(message), { statusCode, code: 'VALIDATION_ERROR' });
const asObjectId = value => (mongoose.isValidObjectId(value) ? new mongoose.Types.ObjectId(value) : null);
const shiftKeys = ['Morning', 'Afternoon', 'Evening'];
const shiftTimes = {
  Morning: { start: 8 * 60, end: 12 * 60 },
  Afternoon: { start: 13 * 60, end: 17 * 60 },
  Evening: { start: 18 * 60, end: 22 * 60 }
};

const normalizeShift = value => shiftKeys.find(shift => shift.toLowerCase() === String(value || '').trim().toLowerCase()) || null;
const shiftVariants = shift => [shift, shift.toLowerCase()];
const timeInMinutes = value => {
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
};

const dayValues = value => {
  const values = Array.isArray(value) ? value : (typeof value === 'string' ? value.split(',') : []);
  const names = {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7
  };
  return values
    .map(value => {
      if (typeof value === 'number') return value;
      const text = String(value).trim().toLowerCase();
      return names[text] || Number(text);
    })
    .filter(day => Number.isInteger(day) && day >= 1 && day <= 7)
    .filter((day, index, days) => days.indexOf(day) === index);
};

const getBed = async value => {
  const objectId = asObjectId(value);
  return Bed.findOne(objectId ? { _id: objectId } : { bedNumber: Number(value) });
};

const getDate = (value, fallback) => {
  const date = value ? new Date(value) : fallback;
  if (Number.isNaN(date.getTime())) throw requestError('Invalid date supplied.');
  return date;
};

const dateWithTime = (date, time) => {
  const [hours, minutes] = time.split(':').map(Number);
  const result = new Date(date);
  result.setHours(hours, minutes, 0, 0);
  return result;
};

const availability = async (req, res, next) => {
  try {
    const selectedDays = dayValues(req.query.selectedDays || req.body.selectedDays);
    const shift = normalizeShift(req.query.shift || req.body.shift);
    if (!selectedDays.length || !shift) {
      throw requestError('selectedDays and a valid shift are required.');
    }

    const schedules = await RecurringSchedule.find({
      status: 'active',
      shift: { $in: shiftVariants(shift) },
      selectedDays: { $in: selectedDays }
    }).select('bedId');
    const reservedBedIds = new Set(schedules.map(schedule => schedule.bedId.toString()));
    const beds = await Bed.find({ status: 'vacant' }).sort({ bedNumber: 1 }).select('bedNumber bedCode status');
    const availableBeds = beds.filter(bed => !reservedBedIds.has(bed._id.toString()));

    res.json({
      success: true,
      data: {
        selectedDays,
        shift,
        bedIds: availableBeds.map(bed => bed.bedNumber),
        beds: availableBeds
      },
      requestId: req.requestId
    });
  } catch (error) { next(error); }
};

const schedule = async (req, res, next) => {
  try {
    const { patientId, bedId, selectedDays, startTimeLocal, endTimeLocal, startDate, endDate, startsAt, endsAt, plannedWeeks = 12 } = req.body;
    const shift = normalizeShift(req.body.shift);
    const missing = [];
    if (!patientId) missing.push('patientId');
    if (!bedId) missing.push('bedId');
    if (!selectedDays) missing.push('selectedDays');
    if (!req.body.shift) missing.push('shift');
    if (!startTimeLocal) missing.push('startTimeLocal');
    if (!endTimeLocal) missing.push('endTimeLocal');
    if (missing.length) return res.status(400).json({ success: false, message: `Missing required fields: ${missing.join(', ')}` });

    const days = dayValues(selectedDays);
    if (!days.length) return res.status(400).json({ success: false, message: 'selectedDays must contain numbers 1-7 or weekday names.' });
    if (!shift) return res.status(400).json({ success: false, message: 'shift must be Morning, Afternoon, or Evening.' });
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(startTimeLocal) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(endTimeLocal)) return res.status(400).json({ success: false, message: 'startTimeLocal and endTimeLocal must use HH:mm format.' });
    const startMinutes = timeInMinutes(startTimeLocal);
    const endMinutes = timeInMinutes(endTimeLocal);
    const timeWindow = shiftTimes[shift];
    if (startMinutes >= endMinutes || startMinutes < timeWindow.start || endMinutes > timeWindow.end) {
      return res.status(400).json({ success: false, message: `Times must fall within the ${shift} shift window.` });
    }

    const patientObjectId = asObjectId(patientId);
    const bedObjectId = asObjectId(bedId);
    if (patientObjectId === null && typeof patientId !== 'string') return res.status(400).json({ success: false, message: 'patientId must be a valid MongoDB ObjectId or patient ID.' });
    if (bedObjectId === null && !Number.isInteger(Number(bedId))) return res.status(400).json({ success: false, message: 'bedId must be a valid MongoDB ObjectId or bed number.' });

    let patient = patientObjectId ? await PatientProfile.findById(patientObjectId) : await PatientProfile.findOne({ patientId: String(patientId).toUpperCase() });
    if (!patient && patientObjectId) {
      const user = await User.findById(patientObjectId).select('patientProfileId role');
      if (user?.patientProfileId) patient = await PatientProfile.findById(user.patientProfileId);
    }
    const bed = await getBed(bedObjectId || bedId);
    if (!patient) return res.status(400).json({ success: false, message: 'Patient profile or patient user was not found.' });
    if (!bed) return res.status(400).json({ success: false, message: 'Bed was not found.' });
    if (bed.status !== 'vacant') throw requestError('The selected bed is not vacant.', 409);

    const firstDate = getDate(startDate || startsAt, new Date());
    const lastDate = getDate(endDate || endsAt, new Date(firstDate.getTime() + Number(plannedWeeks) * 7 * 24 * 60 * 60 * 1000));
    if (lastDate < firstDate) throw requestError('endDate must be after startDate.');

    const collision = await RecurringSchedule.findOne({ status: 'active', bedId: bed._id, shift: { $in: shiftVariants(shift) }, selectedDays: { $in: days } });
    if (collision) throw requestError('The selected bed is already allocated for one or more of those slots.', 409);

    const createdSchedule = await RecurringSchedule.create({
      patientId: patient._id,
      bedId: bed._id,
      selectedDays: days,
      shift,
      startTimeLocal,
      endTimeLocal
    });

    const appointments = [];
    for (const date = new Date(firstDate); date <= lastDate; date.setDate(date.getDate() + 1)) {
      const day = date.getDay() === 0 ? 7 : date.getDay();
      if (days.includes(day)) {
        appointments.push({
          recurringScheduleId: createdSchedule._id,
          patientId: patient._id,
          bedId: bed._id,
          startsAt: dateWithTime(date, startTimeLocal),
          endsAt: dateWithTime(date, endTimeLocal),
          shift
        });
      }
    }

    const createdAppointments = appointments.length ? await Appointment.insertMany(appointments) : [];
    await PatientProfile.updateOne({ _id: patient._id }, { $set: { assignedBedId: bed._id } });

    res.status(201).json({ success: true, data: { recurringSchedule: createdSchedule, appointments: createdAppointments }, requestId: req.requestId });
  } catch (error) {
    logger.error('Appointment scheduling failed', { error: error.message, stack: error.stack, requestId: req.requestId });
    if (error.statusCode === 400 || error.name === 'CastError' || error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const unassign = async (req, res, next) => {
  try {
    const scheduleId = req.body.scheduleId || req.body.recurringScheduleId;
    if (!mongoose.isValidObjectId(scheduleId)) {
      throw requestError('A valid recurring schedule ID is required.');
    }

    const recurringSchedule = await RecurringSchedule.findOneAndUpdate(
      { _id: scheduleId, status: 'active' },
      { $set: { status: 'cancelled' } },
      { new: true }
    );
    if (!recurringSchedule) {
      return res.status(404).json({
        success: false,
        message: 'Active recurring schedule was not found.',
        requestId: req.requestId
      });
    }

    await Appointment.updateMany(
      { recurringScheduleId: recurringSchedule._id, status: { $nin: ['completed', 'cancelled'] } },
      { $set: { status: 'cancelled' } }
    );

    const remainingSchedules = await RecurringSchedule.countDocuments({
      patientId: recurringSchedule.patientId,
      status: 'active'
    });
    if (remainingSchedules === 0) {
      await PatientProfile.updateOne(
        { _id: recurringSchedule.patientId },
        { $set: { assignedBedId: null } }
      );
    }

    res.json({
      success: true,
      data: { recurringSchedule, remainingSchedules },
      requestId: req.requestId
    });
  } catch (error) {
    if (error.statusCode === 400 || error.name === 'CastError') {
      return res.status(400).json({ success: false, message: error.message });
    }
    next(error);
  }
};

module.exports = { availability, schedule, unassign };