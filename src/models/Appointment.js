const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    recurringScheduleId: { type: mongoose.Schema.Types.ObjectId, ref: 'RecurringSchedule', required: true, index: true },
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'PatientProfile', required: true, index: true },
    bedId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bed', required: true, index: true },
    startsAt: { type: Date, required: true, index: true },
    endsAt: { type: Date, required: true },
    shift: { type: String, enum: ['Morning', 'Afternoon', 'Evening'], required: true },
    status: { type: String, enum: ['scheduled', 'preparing_for_pickup', 'patient_notified', 'active', 'completed', 'cancelled'], default: 'scheduled', index: true },
    notification30MinuteSentAt: { type: Date, default: null }
  },
  { timestamps: true }
);

appointmentSchema.index({ bedId: 1, startsAt: 1, endsAt: 1 });

module.exports = mongoose.model('Appointment', appointmentSchema);