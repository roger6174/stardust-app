const express = require('express');
const router = express.Router();
const multer = require('multer');
const { 
    verifyToken, 
    uploadProof, 
    discoverAccounts, 
    submitManualClaim, 
    initiateClaim, 
    verifyClaimOTP, 
    getInheritedAccounts,
    getApprovedSecurityCode,
    getMyClaimStatuses
} = require('../controllers/successionController');
const { auth } = require('../middleware/auth');

// Multer setup for memory storage
const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// Public
router.get('/verify', verifyToken);
router.post('/upload', upload.single('proof'), uploadProof);

// Protected
router.get('/inherited-accounts', auth, getInheritedAccounts);
router.get('/discover', auth, discoverAccounts);
router.post('/submit-claim', auth, upload.single('proof'), submitManualClaim);

// Succession Status & Access
router.get('/my-claims', auth, getMyClaimStatuses);
router.get('/approved-code', auth, getApprovedSecurityCode);

module.exports = router;
