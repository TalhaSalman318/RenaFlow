const express = require('express');
const sessionsController = require('../controllers/sessions.controller');
const authenticate = require('../middlewares/authenticate');

const router = express.Router();
router.get('/active/:patientId', authenticate, sessionsController.getActiveByPatient);
router.get('/patient/:patientId', authenticate, sessionsController.patientHistory);
router.post('/start', sessionsController.start);
router.post('/pause', sessionsController.pause);
router.post('/resume', sessionsController.resume);
router.post('/stop', sessionsController.stop);
router.post('/delay', sessionsController.delay);
router.post('/:appointmentId/start', sessionsController.start);
router.post('/:sessionId/pause', sessionsController.pause);
router.post('/:sessionId/resume', sessionsController.resume);
router.post('/:sessionId/delay', sessionsController.delay);
router.post('/:sessionId/complete', sessionsController.complete);
router.post('/:sessionId/stop', sessionsController.stop);

module.exports = router;