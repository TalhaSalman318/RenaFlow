const express = require('express');
const patientsController = require('../controllers/patients.controller');
const authenticate = require('../middlewares/authenticate');

const router = express.Router();
router.get('/me', authenticate, patientsController.me);
router.get('/', patientsController.list);
router.post('/', patientsController.create);
router.put('/:patientId', patientsController.update);

module.exports = router;