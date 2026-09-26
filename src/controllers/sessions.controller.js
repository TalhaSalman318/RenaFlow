const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const Bed = require('../models/Bed');
const PatientProfile = require('../models/PatientProfile');
const Session = require('../models/Session');
const { broadcastBedStatus } = require('../sockets/bed.socket');
const { broadcastSessionEvent } = require('../sockets/session.socket');

const requestError = (message, statusCode = 400) => Object.assign(new Error(message), { statusCode });
const activeStatuses = ['active', 'running', 'paused', 'delayed'];
const elapsed = (session, now = Date.now()) => {
  const segmentStart = session.resumedAt || session.startedAt;
  const active = ['active', 'running', 'delayed'].includes(session.status);
  if (!active || !segmentStart) return Math.max(0, session.elapsedSeconds || 0);
  return Math.max(0, (session.elapsedSeconds || 0) + Math.floor((now - segmentStart.getTime()) / 1000));
};
const getSession = async req => {
  const id = req.params.sessionId || req.body.sessionId;
  if (id) return Session.findById(id);
  const rawBedId = req.body.bedId;
  if (!rawBedId) return null;
  const bed = await Bed.findOne({ bedNumber: Number(String(rawBedId).replace(/^Bed\\s+/i, '')) });
  return bed ? Session.findOne({ bedId: bed._id }).sort({ updatedAt: -1 }) : null;
};

const timerData = session => {
  const elapsedSeconds = elapsed(session);
  const totalDurationMinutes = session.totalDurationMinutes || session.plannedDurationMinutes || 240;
  const bed = session.bedId;
  const patient = session.patientId;
  const rawPatientId = patient?._id || patient;
  const rawBedId = bed?.bedNumber ? `Bed ${bed.bedNumber}` : bed?._id || bed;
  return {
    sessionId: session._id,
    appointmentId: session.appointmentId,
    patientId: rawPatientId == null ? null : String(rawPatientId),
    patientMedicalId: patient?.patientId || null,
    bedId: rawBedId == null ? null : String(rawBedId),
    startTime: session.startTime || session.startedAt,
    pausedAt: session.pausedAt,
    totalDurationMinutes,
    elapsedSeconds,
    remainingSeconds: Math.max(0, totalDurationMinutes * 60 + (session.delayMinutes || 0) * 60 - elapsedSeconds),
    delayMinutes: session.delayMinutes || 0,
    delayReason: session.delayReason,
    status: session.status === 'running' ? 'active' : session.status
  };
};

const emitSessionEvent = async (session, eventName) => {
  const populatedSession = await Session.findById(session._id)
    .populate('bedId', 'bedNumber')
    .populate('patientId', 'patientId fullName');
  broadcastSessionEvent(populatedSession, eventName);
};

const start = async (req, res, next) => {
  try {
    let appointmentId = req.params.appointmentId || req.body.appointmentId;
    if (!appointmentId && req.body.bedId) {
      const bedNumber = Number(String(req.body.bedId).replace(/^Bed\\s+/i, ''));
      const bed = await Bed.findOne({ bedNumber });
      if (bed) {
        const appointmentQuery = { bedId: bed._id, status: { $in: ['scheduled', 'active'] } };
        if (req.body.patientId) {
          const patient = await PatientProfile.findOne({
            $or: [
              ...(mongoose.isValidObjectId(req.body.patientId) ? [{ _id: req.body.patientId }] : []),
              { patientId: String(req.body.patientId).toUpperCase() }
            ]
          }).select('_id');
          if (!patient) throw requestError('Patient profile was not found.', 404);
          appointmentQuery.patientId = patient._id;
        }
        const appointment = await Appointment.findOne(appointmentQuery).sort({ startsAt: 1 });
        appointmentId = appointment?._id;
      }
    }
    const appointment = appointmentId ? await Appointment.findById(appointmentId) : null;
    if (!appointment) throw requestError('Appointment was not found.', 404);
    if (appointment.status === 'cancelled') throw requestError('Cancelled appointments cannot be started.', 409);

    const activeSession = await Session.findOne({
      appointmentId: appointment._id,
      patientId: appointment.patientId,
      status: { $in: activeStatuses },
    })
      .sort({ updatedAt: -1 })
      .populate('bedId', 'bedNumber')
      .populate('patientId', 'patientId fullName');
    if (activeSession) {
      return res.status(200).json({
        success: true,
        data: { session: activeSession, timer: timerData(activeSession) },
        requestId: req.requestId,
      });
    }

    const bedSession = await Session.findOne({
      bedId: appointment.bedId,
      status: { $in: activeStatuses },
    })
      .sort({ updatedAt: -1 })
      .populate('patientId', 'patientId fullName');
    if (bedSession &&
        String(bedSession.patientId?._id || bedSession.patientId) !==
          String(appointment.patientId)) {
      throw requestError('This bed already has an active dialysis session.', 409);
    }

    let session = await Session.findOne({ appointmentId: appointment._id });
    if (session && session.status !== 'not_started') {
      const message = session.status === 'completed'
        ? 'This appointment session has already been completed.'
        : 'This appointment already has a started session.';
      throw requestError(message, 409);
    }
    session = session || new Session({ appointmentId: appointment._id, patientId: appointment.patientId, bedId: appointment.bedId });
    const now = new Date();
    const durationMinutes = Number(req.body.totalDurationMinutes) || session.totalDurationMinutes || session.plannedDurationMinutes || 240;
    session.startTime = now;
    session.startedAt = now;
    session.resumedAt = now;
    session.pausedAt = null;
    session.endedAt = null;
    session.elapsedSeconds = 0;
    session.pauseSeconds = 0;
    session.totalDurationMinutes = durationMinutes;
    session.plannedDurationMinutes = durationMinutes;
    session.status = 'active';
    await session.save();
    const bed = await Bed.findByIdAndUpdate(appointment.bedId, { status: 'occupied', currentPatientId: appointment.patientId, alertReason: null }, { new: true }).populate('currentPatientId', 'patientId fullName');
    appointment.status = 'active'; await appointment.save();
    broadcastBedStatus(bed);
    await emitSessionEvent(session, 'session_started');
    res.status(201).json({ success: true, data: { session, bed, timer: timerData(session) }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const getActiveByPatient = async (req, res, next) => {
  try {
    const identifier = String(req.params.patientId || '').trim();
    const patientConditions = [
      ...(mongoose.isValidObjectId(identifier) ? [{ _id: identifier }] : []),
      { patientId: identifier.toUpperCase() },
    ];
    const patient = await PatientProfile.findOne({ $or: patientConditions })
      .select('_id patientId userId');
    if (!patient) throw requestError('Patient profile was not found.', 404);
    if (req.user?.role === 'patient' &&
        patient.userId.toString() !== req.user._id.toString()) {
      throw requestError('Patients may only view their own sessions.', 403);
    }

    const session = await Session.findOne({
      patientId: patient._id,
      status: { $in: activeStatuses },
    })
      .sort({ updatedAt: -1 })
      .populate('bedId', 'bedNumber')
      .populate('patientId', 'patientId fullName');

    res.json({
      success: true,
      data: {
        session,
        timer: session ? timerData(session) : null,
      },
      requestId: req.requestId,
    });
  } catch (error) { next(error); }
};

const patientHistory = async (req, res, next) => {
  try {
    const identifier = String(req.params.patientId || '').trim();
    const conditions = [
      ...(mongoose.isValidObjectId(identifier) ? [{ _id: identifier }] : []),
      { patientId: identifier.toUpperCase() },
    ];
    const patient = req.user?.role === 'patient'
      ? await PatientProfile.findOne({ userId: req.user._id }).select('_id patientId userId')
      : await PatientProfile.findOne({ $or: conditions }).select('_id patientId userId');
    if (!patient) throw requestError('Patient profile was not found.', 404);
    if (req.user?.role === 'patient' &&
        patient.userId.toString() !== req.user._id.toString()) {
      throw requestError('Patients may only view their own sessions.', 403);
    }
    if (req.user?.role === 'patient' &&
        identifier !== patient._id.toString() &&
        identifier.toUpperCase() !== patient.patientId) {
      throw requestError('Patients may only view their own sessions.', 403);
    }

    const sessions = await Session.find({
      patientId: patient._id,
      status: { $in: ['active', 'running', 'paused', 'delayed', 'completed'] },
    })
      .sort({ startTime: -1, startedAt: -1, createdAt: -1 })
      .populate('bedId', 'bedNumber');

    res.json({
      success: true,
      data: {
        sessions: sessions.map(session => ({
          sessionId: session._id,
          patientId: patient._id,
          patientMedicalId: patient.patientId,
          bedId: session.bedId?.bedNumber
            ? `Bed ${session.bedId.bedNumber}`
            : session.bedId,
          startTime: session.startTime || session.startedAt,
          endTime: session.endedAt,
          elapsedSeconds: elapsed(session),
          totalDurationMinutes: session.totalDurationMinutes || session.plannedDurationMinutes || 240,
          status: session.status === 'running' ? 'active' : session.status,
        })),
      },
      requestId: req.requestId,
    });
  } catch (error) { next(error); }
};

const pause = async (req, res, next) => {
  try {
    const session = await getSession(req);
    if (!session) throw requestError('Session was not found.', 404);
    if (!['active', 'running', 'delayed'].includes(session.status)) throw requestError('Only an active session can be paused.', 409);
    const pausedAt = new Date();
    session.elapsedSeconds = elapsed(session, pausedAt.getTime());
    session.pausedAt = pausedAt;
    session.resumedAt = null;
    session.status = 'paused';
    await session.save();
    await emitSessionEvent(session, 'session_paused');
    res.json({ success: true, data: { session, timer: timerData(session) }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const resume = async (req, res, next) => {
  try {
    const session = await getSession(req);
    if (!session) throw requestError('Session was not found.', 404);
    if (session.status !== 'paused') throw requestError('Only a paused session can be resumed.', 409);
    const resumedAt = new Date();
    if (session.pausedAt) {
      session.pauseSeconds += Math.floor((resumedAt.getTime() - session.pausedAt.getTime()) / 1000);
    }
    session.pausedAt = null;
    session.startedAt = resumedAt;
    session.resumedAt = resumedAt;
    session.status = 'active';
    await session.save();
    await emitSessionEvent(session, 'session_resumed');
    res.json({ success: true, data: { session, timer: timerData(session) }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const delay = async (req, res, next) => {
  try {
    const session = await getSession(req);
    const delayMinutes = Number(req.body.delayMinutes);
    if (!session) throw requestError('Session was not found.', 404);
    if (![15, 30].includes(delayMinutes)) throw requestError('delayMinutes must be 15 or 30.');
    if (!['active', 'running', 'paused', 'delayed'].includes(session.status)) throw requestError('Only an active session can be delayed.', 409);
    if (['active', 'running', 'delayed'].includes(session.status)) {
      session.elapsedSeconds = elapsed(session);
      session.startedAt = new Date();
      session.resumedAt = session.startedAt;
    }
    session.delayMinutes += delayMinutes; session.delayReason = req.body.reason || session.delayReason;
    if (session.status !== 'paused') session.status = 'delayed';
    await session.save();
    const bed = await Bed.findByIdAndUpdate(session.bedId, { status: 'delayed' }, { new: true }).populate('currentPatientId', 'patientId fullName');
    broadcastBedStatus(bed); await emitSessionEvent(session, 'timer_tick');
    res.json({ success: true, data: { session, bed, timer: timerData(session) }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const complete = async (req, res, next) => {
  try {
    const session = await getSession(req);
    if (!session) throw requestError('Session was not found.', 404);
    session.elapsedSeconds = elapsed(session); session.endedAt = new Date(); session.pausedAt = null; session.resumedAt = null; session.status = 'completed'; await session.save();
    const bed = await Bed.findByIdAndUpdate(session.bedId, { status: 'vacant', currentPatientId: null }, { new: true });
    await Appointment.findByIdAndUpdate(session.appointmentId, { status: 'completed' });
    broadcastBedStatus(bed); await emitSessionEvent(session, 'session_stopped');
    res.json({ success: true, data: { session, bed, timer: timerData(session) }, requestId: req.requestId });
  } catch (error) { next(error); }
};

module.exports = {
  start,
  getActiveByPatient,
  patientHistory,
  pause,
  resume,
  delay,
  complete,
  stop: complete,
};