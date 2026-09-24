const Appointment = require('../models/Appointment');
const Bed = require('../models/Bed');
const Session = require('../models/Session');
const { broadcastBedStatus } = require('../sockets/bed.socket');
const { broadcastSessionTick } = require('../sockets/session.socket');

const requestError = (message, statusCode = 400) => Object.assign(new Error(message), { statusCode });
const elapsed = session => {
  if (!session.startedAt) return session.elapsedSeconds;
  const end = session.status === 'running' || session.status === 'delayed' ? new Date() : (session.pausedAt || session.endedAt || new Date());
  return Math.max(0, session.elapsedSeconds + Math.floor((end - session.startedAt) / 1000) - session.pauseSeconds);
};
const getSession = async id => Session.findById(id);

const start = async (req, res, next) => {
  try {
    const appointment = await Appointment.findById(req.params.appointmentId);
    if (!appointment) throw requestError('Appointment was not found.', 404);
    if (appointment.status === 'cancelled') throw requestError('Cancelled appointments cannot be started.', 409);
    let session = await Session.findOne({ appointmentId: appointment._id });
    if (session && session.status !== 'not_started') throw requestError('This appointment already has a started session.', 409);
    session = session || new Session({ appointmentId: appointment._id, patientId: appointment.patientId, bedId: appointment.bedId });
    session.startedAt = session.startedAt || new Date();
    session.pausedAt = null;
    session.status = 'running';
    await session.save();
    const bed = await Bed.findByIdAndUpdate(appointment.bedId, { status: 'occupied', currentPatientId: appointment.patientId, alertReason: null }, { new: true }).populate('currentPatientId', 'patientId fullName');
    appointment.status = 'active'; await appointment.save();
    broadcastBedStatus(bed);
    broadcastSessionTick(session);
    res.status(201).json({ success: true, data: { session, bed }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const pause = async (req, res, next) => {
  try {
    const session = await getSession(req.params.sessionId);
    if (!session) throw requestError('Session was not found.', 404);
    if (!['running', 'delayed'].includes(session.status)) throw requestError('Only a running session can be paused.', 409);
    session.elapsedSeconds = elapsed(session); session.pausedAt = new Date(); session.status = 'paused'; await session.save();
    broadcastSessionTick(session); res.json({ success: true, data: { session }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const resume = async (req, res, next) => {
  try {
    const session = await getSession(req.params.sessionId);
    if (!session) throw requestError('Session was not found.', 404);
    if (session.status !== 'paused') throw requestError('Only a paused session can be resumed.', 409);
    session.pauseSeconds += Math.floor((Date.now() - session.pausedAt.getTime()) / 1000); session.pausedAt = null; session.status = 'running'; await session.save();
    broadcastSessionTick(session); res.json({ success: true, data: { session }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const delay = async (req, res, next) => {
  try {
    const session = await getSession(req.params.sessionId);
    const delayMinutes = Number(req.body.delayMinutes);
    if (!session) throw requestError('Session was not found.', 404);
    if (![15, 30].includes(delayMinutes)) throw requestError('delayMinutes must be 15 or 30.');
    if (!['running', 'paused', 'delayed'].includes(session.status)) throw requestError('Only an active session can be delayed.', 409);
    session.delayMinutes += delayMinutes; session.delayReason = req.body.reason || session.delayReason; session.status = 'delayed'; await session.save();
    const bed = await Bed.findByIdAndUpdate(session.bedId, { status: 'delayed' }, { new: true }).populate('currentPatientId', 'patientId fullName');
    broadcastBedStatus(bed); broadcastSessionTick(session);
    res.json({ success: true, data: { session, bed }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const complete = async (req, res, next) => {
  try {
    const session = await getSession(req.params.sessionId);
    if (!session) throw requestError('Session was not found.', 404);
    session.elapsedSeconds = elapsed(session); session.endedAt = new Date(); session.pausedAt = null; session.status = 'completed'; await session.save();
    const bed = await Bed.findByIdAndUpdate(session.bedId, { status: 'sanitizing', currentPatientId: null }, { new: true });
    await Appointment.findByIdAndUpdate(session.appointmentId, { status: 'completed' });
    broadcastBedStatus(bed); broadcastSessionTick(session);
    res.json({ success: true, data: { session, bed }, requestId: req.requestId });
  } catch (error) { next(error); }
};

module.exports = { start, pause, resume, delay, complete };