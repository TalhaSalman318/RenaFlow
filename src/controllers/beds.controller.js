const Bed = require('../models/Bed');
const { broadcastBedStatus } = require('../sockets/bed.socket');

const updateStatus = async (req, res, next) => {
  try {
    const bed = await Bed.findOne({ bedNumber: Number(req.params.bedId) }).populate('currentPatientId', 'patientId fullName');
    if (!bed) return res.status(404).json({ success: false, error: { code: 'BED_NOT_FOUND', message: 'Bed was not found.' }, requestId: req.requestId });
    const { status, alertReason, patientId } = req.body;
    if (!['occupied', 'sanitizing', 'vacant', 'alert', 'delayed'].includes(status)) {
      const error = new Error('Invalid bed status.'); error.statusCode = 400; throw error;
    }
    bed.status = status;
    bed.alertReason = status === 'alert' ? (alertReason || null) : null;
    if (patientId) bed.currentPatientId = patientId;
    if (status === 'vacant') bed.currentPatientId = null;
    await bed.save();
    broadcastBedStatus(bed);
    res.json({ success: true, data: { bed }, requestId: req.requestId });
  } catch (error) { next(error); }
};

const matrix = async (req, res, next) => {
  try {
    const beds = await Bed.find().sort({ bedNumber: 1 }).populate('currentPatientId', 'patientId fullName');
    res.json({ success: true, data: { beds, matrix: beds }, requestId: req.requestId });
  } catch (error) { next(error); }
};

module.exports = { matrix, updateStatus };