const mongoose = require('mongoose');

const bedSchema = new mongoose.Schema(
  {
    bedNumber: {
      type: Number,
      required: true,
      unique: true,
      min: 1,
      max: 50,
      index: true
    },
    bedCode: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true
    },
    status: {
      type: String,
      enum: ['occupied', 'vacant', 'alert', 'delayed'],
      default: 'vacant',
      required: true,
      index: true
    },
    currentPatientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PatientProfile',
      default: null,
      index: true
    },
    assignedNurseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    alertReason: {
      type: String,
      trim: true,
      default: null
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Bed', bedSchema);