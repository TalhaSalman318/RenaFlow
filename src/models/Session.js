const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema(
  {
    appointmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment', required: true, unique: true, index: true },
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'PatientProfile', required: true, index: true },
    bedId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bed', required: true, index: true },
    startTime: { type: Date, default: null },
    startedAt: { type: Date, default: null },
    resumedAt: { type: Date, default: null },
    pausedAt: { type: Date, default: null },
    endedAt: { type: Date, default: null },
    totalDurationMinutes: { type: Number, default: 240, min: 1 },
    plannedDurationMinutes: { type: Number, default: 240, min: 1 },
    elapsedSeconds: { type: Number, default: 0, min: 0 },
    pauseSeconds: { type: Number, default: 0, min: 0 },
    alert30MinSent: { type: Boolean, default: false },
    delayMinutes: { type: Number, default: 0, min: 0 },
    delayReason: { type: String, trim: true, default: null },
    status: { type: String, enum: ['not_started', 'active', 'running', 'paused', 'delayed', 'completed'], default: 'not_started', index: true }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Session', sessionSchema);