const express = require('express');
const patientsController = require('../controllers/patients.controller');

const router = express.Router();
router.get('/', patientsController.list);
router.post('/', patientsController.create);

module.exports = router;