const mongoose = require('mongoose');

const patientSequenceSchema = new mongoose.Schema({
  year: { type: Number, required: true, unique: true },
  value: { type: Number, default: 0, min: 0 }
});

module.exports = mongoose.model('PatientSequence', patientSequenceSchema);