const express = require('express');
const router = express.Router();
const securityController = require('../controllers/securityController');
const { auth } = require('../middleware/auth');

router.get('/', auth, securityController.getLogs);

module.exports = router;
