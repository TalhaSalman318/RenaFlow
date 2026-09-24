const express = require('express');
const appointmentsController = require('../controllers/appointments.controller');

const router = express.Router();
router.get('/availability', appointmentsController.availability);
router.post('/schedule', appointmentsController.schedule);

module.exports = router;