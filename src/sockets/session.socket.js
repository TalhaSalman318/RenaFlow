const Session = require('../models/Session');
const Appointment = require('../models/Appointment');

let io;
let ticker;
let alertTicker;

const registerSessionSocket = socketIo => {
  io = socketIo;
  if (ticker) return;
  ticker = setInterval(async () => {
    const sessions = await Session.find({ status: { $in: ['running', 'delayed'] } }).populate('bedId', 'bedNumber');
    sessions.forEach(broadcastSessionTick);
  }, 1000);
  ticker.unref();
  alertTicker = setInterval(async () => {
    const now = new Date();
    const upperBound = new Date(now.getTime() + 30 * 60 * 1000);
    const appointments = await Appointment.find({
      status: 'scheduled',
      startsAt: { $gt: now, $lte: upperBound },
      notification30MinuteSentAt: null
    });
    for (const appointment of appointments) {
      appointment.notification30MinuteSentAt = new Date();
      appointment.status = 'preparing_for_pickup';
      await appointment.save();
      broadcastPreSessionAlert(appointment);
    }
  }, 60 * 1000);
  alertTicker.unref();
};

const broadcastSessionTick = session => {
  if (!io || !session) return;
  const currentElapsed = session.startedAt && ['running', 'delayed'].includes(session.status)
    ? session.elapsedSeconds + Math.floor((Date.now() - session.startedAt.getTime()) / 1000) - session.pauseSeconds
    : session.elapsedSeconds;
  const bedId = session.bedId && session.bedId.bedNumber
    ? `Bed ${session.bedId.bedNumber}`
    : session.bedId;
  io.emit('session:tick', {
    sessionId: session._id,
    appointmentId: session.appointmentId,
    bedId,
    elapsedSeconds: Math.max(0, currentElapsed),
    remainingSeconds: Math.max(0, session.plannedDurationMinutes * 60 + session.delayMinutes * 60 - currentElapsed),
    status: session.status
  });
};

const broadcastPreSessionAlert = appointment => {
  if (io) io.emit('appointment:pre-session-alert', { appointment });
};

module.exports = { registerSessionSocket, broadcastSessionTick, broadcastPreSessionAlert };