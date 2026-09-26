const Bed = require('../models/Bed');
const RecurringSchedule = require('../models/RecurringSchedule');
const { broadcastBedStatus } = require('../sockets/bed.socket');

const shiftMeta = {
  Morning: { label: 'Morning Shift', timeRange: '08:00 AM - 12:00 PM' },
  Afternoon: { label: 'Afternoon Shift', timeRange: '01:00 PM - 05:00 PM' },
  Evening: { label: 'Evening Shift', timeRange: '06:00 PM - 10:00 PM' }
};

const normalizeShift = value => Object.keys(shiftMeta).find(shift => shift.toLowerCase() === String(value || '').toLowerCase()) || null;

const dayLabelMap = {
  1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'
};

const buildShiftSlots = async bedId => {
  const schedules = await RecurringSchedule.find({ bedId, status: 'active' })
    .populate({
      path: 'patientId',
      select: 'fullName patientId phone gender bloodGroup userId',
      populate: [
        { path: 'userId', select: 'fullName email medicalId phone' },
        { path: 'assignedBedId', select: 'bedNumber bedCode status' },
        { path: 'recurringSchedules' }
      ]
    })
    .sort({ shift: 1, selectedDays: 1 });

  const grouped = { Morning: [], Afternoon: [], Evening: [] };
  schedules.forEach(schedule => {
    const shift = normalizeShift(schedule.shift);
    if (shift) grouped[shift].push(schedule);
  });

  return Object.entries(shiftMeta).map(([shift, meta]) => {
    const assignedSchedules = grouped[shift] || [];
    const assignments = assignedSchedules
      .filter(item => item.patientId)
      .map(item => {
        const patient = item.patientId;
        const user = patient.userId;
        return {
          scheduleId: item._id,
          patientName: patient.fullName || user?.fullName || user?.displayName || null,
          medicalId: patient.patientId || user?.medicalId || null,
          phone: patient.phone || user?.phone || null,
          gender: patient.gender || null,
          bloodGroup: patient.bloodGroup || null,
          days: [...new Set((item.selectedDays || []).map(day => dayLabelMap[day]).filter(Boolean))]
        };
      });
    const names = [...new Set(assignments.flatMap(item => item.days))];

    return {
      shift,
      label: meta.label,
      timeRange: meta.timeRange,
      status: assignments.length ? 'assigned' : 'vacant',
      patientName: assignments[0]?.patientName || null,
      medicalId: assignments[0]?.medicalId || null,
      phone: assignments[0]?.phone || null,
      gender: assignments[0]?.gender || null,
      bloodGroup: assignments[0]?.bloodGroup || null,
      days: names,
      assignments
    };
  });
};

const updateStatus = async (req, res, next) => {
  try {
    const bed = await Bed.findOne({ bedNumber: Number(req.params.bedId) }).populate({
      path: 'currentPatientId',
      select: 'patientId fullName phone gender bloodGroup userId',
      populate: [
        { path: 'userId', select: 'fullName email medicalId phone' },
        { path: 'assignedBedId', select: 'bedNumber bedCode status' },
        { path: 'recurringSchedules' }
      ]
    });
    if (!bed) return res.status(404).json({ success: false, error: { code: 'BED_NOT_FOUND', message: 'Bed was not found.' }, requestId: req.requestId });
    const { status, alertReason, patientId } = req.body;
    if (!['occupied', 'vacant', 'alert', 'delayed'].includes(status)) {
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
    const beds = await Bed.find().sort({ bedNumber: 1 }).populate({
      path: 'currentPatientId',
      select: 'patientId fullName phone gender bloodGroup userId',
      populate: [
        { path: 'userId', select: 'fullName email medicalId phone' },
        { path: 'assignedBedId', select: 'bedNumber bedCode status' },
        { path: 'recurringSchedules' }
      ]
    });
    const matrixBeds = await Promise.all(beds.map(async bed => {
      const shiftSlots = await buildShiftSlots(bed._id);
      const occupiedSlots = shiftSlots.filter(slot => slot.status === 'assigned').length;
      const storedStatus = bed.status === 'sanitizing' ? 'vacant' : bed.status;
      const status = storedStatus === 'vacant' && occupiedSlots > 0
        ? 'occupied'
        : storedStatus;
      return {
        ...bed.toObject(),
        status,
        matrixDerivedStatus: status !== bed.status,
        shiftSlots,
        occupiedSlots,
        availableSlots: shiftSlots.length - occupiedSlots,
        slotSummary: `${occupiedSlots}/3 Slots Occupied - ${shiftSlots.length - occupiedSlots} Slots Available`
      };
    }));

    res.json({ success: true, data: { beds: matrixBeds, matrix: matrixBeds }, requestId: req.requestId });
  } catch (error) { next(error); }
};

module.exports = { matrix, updateStatus };