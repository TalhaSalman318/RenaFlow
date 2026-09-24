const express = require('express');
const sessionsController = require('../controllers/sessions.controller');

const router = express.Router();
router.post('/:appointmentId/start', sessionsController.start);
router.post('/:sessionId/pause', sessionsController.pause);
router.post('/:sessionId/resume', sessionsController.resume);
router.post('/:sessionId/delay', sessionsController.delay);
router.post('/:sessionId/complete', sessionsController.complete);

module.exports = router;