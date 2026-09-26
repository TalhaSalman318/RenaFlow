const Session = require('../models/Session');
const Appointment = require('../models/Appointment');
const RecurringSchedule = require('../models/RecurringSchedule');
const Bed = require('../models/Bed');
const PatientProfile = require('../models/PatientProfile');
const { broadcastBedStatus } = require('./bed.socket');
const { send30MinAlert } = require('../services/whatsapp.service');

let io;
let ticker;
let roomListenerIo;
const shiftOrder = ['Morning', 'Afternoon', 'Evening'];

const nextShiftAfter = shift => {
  const currentIndex = shiftOrder.findIndex(value => value.toLowerCase() === String(shift || '').toLowerCase());
  return currentIndex < 0 ? null : shiftOrder[(currentIndex + 1) % shiftOrder.length];
};

const emitToSessionRooms = (eventName, payload) => {
  if (!io) return;
  const patientId = payload.patientId == null
    ? null
    : String(payload.patientId);
  if (patientId) io.to(`patient_${patientId}`).emit(eventName, payload);
  io.to('admin_room').emit(eventName, payload);
};

const registerSessionSocket = socketIo => {
  io = socketIo;
  if (roomListenerIo !== socketIo) {
    roomListenerIo = socketIo;
    socketIo.on('connection', socket => {
      const user = socket.user;
      if (!user) return;
      if (user.role === 'admin' || user.role === 'nurse') {
        socket.join('admin_room');
      }
      if (user.role === 'patient' && user.sub) {
        void PatientProfile.findOne({ userId: user.sub })
          .select('_id')
          .then(patient => {
            if (patient) socket.join(`patient_${String(patient._id)}`);
          })
          .catch(() => {});
      }
    });
  }
  if (ticker) return;
  ticker = setInterval(async () => {
    try {
      const sessions = await Session.find({ status: { $in: ['active', 'running', 'delayed'] } })
        .populate('bedId', 'bedNumber')
        .populate('patientId', 'patientId fullName')
        .populate('appointmentId', 'shift startsAt');
      for (const session of sessions) {
        const segmentStart = session.resumedAt || session.startedAt;
        const elapsedSeconds = session.elapsedSeconds + (segmentStart
          ? Math.floor((Date.now() - segmentStart.getTime()) / 1000)
          : 0);
        const targetDurationMinutes = (session.totalDurationMinutes || session.plannedDurationMinutes || 240)
          + (session.delayMinutes || 0);
        const totalDuration = targetDurationMinutes * 60;
        const remainingSeconds = Math.max(0, totalDuration - elapsedSeconds);
        if (session.status === 'active' && remainingSeconds === 1800 && !session.alert30MinSent) {
          await triggerNextShiftAlert(session);
        }
        if (elapsedSeconds >= totalDuration) {
          const completed = await Session.findOneAndUpdate(
            { _id: session._id, status: { $in: ['active', 'running', 'delayed'] } },
            { $set: { elapsedSeconds: totalDuration, endedAt: new Date(), resumedAt: null, status: 'completed' } },
            { new: true }
          ).populate('bedId', 'bedNumber').populate('patientId', 'patientId fullName');
          if (!completed) continue;
          const bed = await Bed.findByIdAndUpdate(
            completed.bedId._id,
            { $set: { status: 'vacant', currentPatientId: null } },
            { new: true }
          );
          await Appointment.findByIdAndUpdate(completed.appointmentId, { status: 'completed' });
          broadcastBedStatus(bed);
          broadcastSessionEvent(completed, 'session_stopped');
        } else {
          broadcastSessionTick(session);
        }
      }
    } catch (_) {}
  }, 1000);
  ticker.unref();
};

const triggerNextShiftAlert = async session => {
  if (session.status !== 'active' || session.alert30MinSent) return;
  const bedId = session.bedId?._id || session.bedId;
  const bedNumber = session.bedId?.bedNumber;
  const currentShift = session.appointmentId?.shift;
  const nextShift = nextShiftAfter(currentShift);
  if (!bedId || !bedNumber || !nextShift) return;

  const nextSchedules = await RecurringSchedule.find({
    bedId,
    shift: nextShift,
    status: 'active'
  }).select('_id');
  if (!nextSchedules.length) return;

  const nextAppointment = await Appointment.findOne({
    bedId,
    recurringScheduleId: { $in: nextSchedules.map(schedule => schedule._id) },
    status: 'scheduled',
    startsAt: { $gt: session.appointmentId.startsAt || new Date() }
  })
    .sort({ startsAt: 1 })
    .populate('patientId', 'phone fullName');
  const nextPatient = nextAppointment?.patientId;
  if (!nextPatient?.phone) return;

  const claimedSession = await Session.findOneAndUpdate(
    { _id: session._id, status: 'active', alert30MinSent: { $ne: true } },
    { $set: { alert30MinSent: true } },
    { new: true }
  );
  if (!claimedSession) return;

  await send30MinAlert(nextPatient.phone, nextPatient.fullName, bedNumber);
};

const broadcastSessionTick = session => {
  if (!io || !session) return;
  const segmentStart = session.resumedAt || session.startedAt;
  const isActive = ['active', 'running', 'delayed'].includes(session.status);
  const currentElapsed = isActive && segmentStart
    ? session.elapsedSeconds + Math.floor((Date.now() - segmentStart.getTime()) / 1000)
    : session.elapsedSeconds;
  const bedId = session.bedId && session.bedId.bedNumber
    ? `Bed ${session.bedId.bedNumber}`
    : session.bedId;
  const rawPatientId = session.patientId && session.patientId._id
    ? session.patientId._id
    : session.patientId;
  const patientId = rawPatientId == null ? null : String(rawPatientId);
  const patientMedicalId = session.patientId && session.patientId.patientId
    ? session.patientId.patientId
    : null;
  const payload = {
    sessionId: session._id,
    appointmentId: session.appointmentId,
    patientId,
    patientMedicalId,
    bedId,
    elapsedSeconds: Math.max(0, currentElapsed),
    totalDurationMinutes: session.totalDurationMinutes || session.plannedDurationMinutes || 240,
    durationMinutes: session.totalDurationMinutes || session.plannedDurationMinutes || 240,
    remainingSeconds: Math.max(0, (session.totalDurationMinutes || session.plannedDurationMinutes || 240) * 60 + (session.delayMinutes || 0) * 60 - currentElapsed),
    delayMinutes: session.delayMinutes || 0,
    delayReason: session.delayReason,
    status: session.status === 'running' ? 'active' : session.status
  };
  emitToSessionRooms('timer_tick', payload);
  emitToSessionRooms('session:tick', payload);
};

const broadcastSessionEvent = (session, eventName) => {
  if (!io || !session) return;
  const segmentStart = session.resumedAt || session.startedAt;
  const isActive = ['active', 'running', 'delayed'].includes(session.status);
  const elapsedSeconds = isActive && segmentStart
    ? session.elapsedSeconds + Math.floor((Date.now() - segmentStart.getTime()) / 1000)
    : session.elapsedSeconds;
  const bedId = session.bedId && session.bedId.bedNumber
    ? `Bed ${session.bedId.bedNumber}`
    : session.bedId;
  const rawPatientId = session.patientId && session.patientId._id
    ? session.patientId._id
    : session.patientId;
  const patientId = rawPatientId == null ? null : String(rawPatientId);
  const payload = {
    sessionId: session._id,
    appointmentId: session.appointmentId,
    patientId,
    patientMedicalId: session.patientId?.patientId || null,
    bedId,
    startTime: session.startTime || session.startedAt,
    pausedAt: session.pausedAt,
    totalDurationMinutes: session.totalDurationMinutes || session.plannedDurationMinutes || 240,
    durationMinutes: session.totalDurationMinutes || session.plannedDurationMinutes || 240,
    elapsedSeconds: Math.max(0, elapsedSeconds),
    remainingSeconds: Math.max(0, (session.totalDurationMinutes || session.plannedDurationMinutes || 240) * 60 + (session.delayMinutes || 0) * 60 - elapsedSeconds),
    delayMinutes: session.delayMinutes || 0,
    delayReason: session.delayReason,
    status: session.status === 'running' ? 'active' : session.status
  };
  emitToSessionRooms(eventName, payload);
  broadcastSessionTick(session);
};

const broadcastPreSessionAlert = appointment => {
  if (io) io.emit('appointment:pre-session-alert', { appointment });
};

module.exports = {
  registerSessionSocket,
  broadcastSessionTick,
  broadcastSessionEvent,
  broadcastPreSessionAlert,
  triggerNextShiftAlert,
};