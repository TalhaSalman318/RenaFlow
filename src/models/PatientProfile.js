const mongoose = require('mongoose');

const patientProfileSchema = new mongoose.Schema(
  {
    patientId: {
      type: String,
      unique: true,
      required: true,
      uppercase: true,
      trim: true,
      index: true
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true
    },
    fullName: {
      type: String,
      required: true,
      trim: true
    },
    phone: { type: String, required: true, trim: true },
    bloodGroup: { type: String, trim: true, default: 'Unknown' },
    age: {
      type: Number,
      required: true,
      min: 0,
      max: 130
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'other', 'not_provided'],
      required: true
    },
    dryWeightKg: {
      type: Number,
      required: true,
      min: 0
    },
    vascularAccessType: {
      type: String,
      enum: ['av_fistula', 'av_graft', 'catheter', 'other'],
      required: true
    },
    baselineBloodPressure: {
      systolic: { type: Number, required: true, min: 40, max: 300 },
      diastolic: { type: Number, required: true, min: 20, max: 200 }
    },
    nephrologistName: {
      type: String,
      trim: true
    },
    emergencyContact: {
      name: { type: String, required: true, trim: true },
      phone: { type: String, required: true, trim: true }
    },
    assignedBedId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Bed',
      default: null
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('PatientProfile', patientProfileSchema);