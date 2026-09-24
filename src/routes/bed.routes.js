const express = require('express');
const bedsController = require('../controllers/beds.controller');

const router = express.Router();
router.get('/matrix', bedsController.matrix);
router.post('/:bedId/status', bedsController.updateStatus);

module.exports = router;