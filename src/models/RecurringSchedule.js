const mongoose = require('mongoose');

const recurringScheduleSchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'PatientProfile', required: true, index: true },
    bedId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bed', required: true, index: true },
    selectedDays: {
      type: [{ type: Number, min: 1, max: 7 }],
      required: true,
      validate: { validator: days => days.length > 0 && new Set(days).size === days.length, message: 'selectedDays must contain unique days from 1 to 7' }
    },
    shift: { type: String, enum: ['Morning', 'Afternoon', 'Evening'], required: true },
    startTimeLocal: { type: String, required: true, match: /^([01]\d|2[0-3]):[0-5]\d$/ },
    endTimeLocal: { type: String, required: true, match: /^([01]\d|2[0-3]):[0-5]\d$/ },
    status: { type: String, enum: ['active', 'cancelled'], default: 'active', index: true }
  },
  { timestamps: true }
);

module.exports = mongoose.model('RecurringSchedule', recurringScheduleSchema);