const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { auth } = require('../middleware/auth');

// All AI routes require authentication
router.use(auth);

router.post('/chat', aiController.chat);
router.post('/card-benefits', aiController.getCardBenefits);
router.post('/security-audit', aiController.securityAudit);

module.exports = router;
