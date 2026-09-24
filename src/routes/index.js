const express = require('express');
const authRoutes = require('./auth.routes');
const appointmentRoutes = require('./appointment.routes');
const bedRoutes = require('./bed.routes');
const sessionRoutes = require('./session.routes');
const patientRoutes = require('./patient.routes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/appointments', appointmentRoutes);
router.use('/beds', bedRoutes);
router.use('/sessions', sessionRoutes);
router.use('/patients', patientRoutes);

module.exports = router;