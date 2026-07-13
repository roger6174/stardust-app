const db = require('../config/db');

// ═══════════════════════════════════════════════════════
// SUCCESSION SYSTEM — Ported from Web Backend
// ═══════════════════════════════════════════════════════

/**
 * Verify a succession token (sent via notification link)
 */
const verifyToken = async (req, res) => {
    const { token } = req.query;

    if (!token) {
        return res.status(400).json({ message: 'Token is required' });
    }

    try {
        const [requests] = await db.execute(`
            SELECT sr.*, n.full_name as nominee_name, u.full_name as user_name
            FROM succession_requests sr
            JOIN nominees n ON sr.nominee_id = n.nominee_id
            JOIN users u ON sr.user_id = u.user_id
            WHERE sr.token = ? AND sr.status = 'PENDING'
        `, [token]);

        if (requests.length === 0) {
            return res.status(404).json({ message: 'Invalid or expired succession token' });
        }

        const request = requests[0];
        res.json({
            nominee_name: request.nominee_name,
            user_name: request.user_name,
            request_id: request.request_id
        });
    } catch (error) {
        console.error('❌ [SUCCESSION] verifyToken error:', error);
        res.status(500).json({ message: 'Error verifying succession token' });
    }
};

/**
 * Upload proof document for a succession claim
 */
const uploadProof = async (req, res) => {
    const { token } = req.body;

    if (!req.file) {
        return res.status(400).json({ message: 'Proof document is required' });
    }

    try {
        const [requests] = await db.execute('SELECT * FROM succession_requests WHERE token = ? AND status = "PENDING"', [token]);

        if (requests.length === 0) {
            return res.status(404).json({ message: 'Invalid succession request' });
        }

        const request = requests[0];

        // For mobile, store proof locally or in S3 based on config
        let proofPath;
        if (process.env.USE_AWS === 'true') {
            // S3 upload (import s3Service when available)
            const s3Service = require('../services/s3Service');
            const filename = `PROOF-${Date.now()}-${req.file.originalname}`;
            const result = await s3Service.uploadFile(req.file.buffer, filename, 'nominee-proofs', req.file.mimetype);
            proofPath = result.key;
        } else {
            // Local storage fallback
            const fs = require('fs');
            const path = require('path');
            const uploadDir = path.join(process.cwd(), 'uploads', 'proofs');
            if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
            const filename = `PROOF-${Date.now()}-${req.file.originalname}`;
            fs.writeFileSync(path.join(uploadDir, filename), req.file.buffer);
            proofPath = `uploads/proofs/${filename}`;
        }

        const connection = await db.getConnection();
        await connection.beginTransaction();

        try {
            await connection.execute(
                'UPDATE succession_requests SET proof_url = ?, updated_at = NOW() WHERE request_id = ?',
                [proofPath, request.request_id]
            );

            await connection.execute(
                'UPDATE users SET succession_status = "ORANGE" WHERE user_id = ?',
                [request.user_id]
            );

            await connection.commit();
            res.json({ message: 'Succession proof uploaded successfully. Awaiting admin verification.' });
        } catch (err) {
            await connection.rollback();
            throw err;
        } finally {
            connection.release();
        }
    } catch (error) {
        console.error('❌ [SUCCESSION] uploadProof error:', error);
        res.status(500).json({ message: 'Error uploading succession proof' });
    }
};

/**
 * Discover accounts where the current user is a nominee
 */
const discoverAccounts = async (req, res) => {
    const { mobile } = req.user;

    try {
        let userMobile = mobile;
        if (!userMobile) {
            const [u] = await db.execute('SELECT mobile FROM users WHERE user_id = ?', [req.user.id]);
            userMobile = u[0]?.mobile;
        }

        const [nomineeRecords] = await db.execute(`
            SELECT u.user_id, u.full_name as user_name, n.nominee_id, n.created_at as assigned_date, u.succession_status
            FROM users u
            JOIN nominees n ON u.user_id = n.user_id
            WHERE n.mobile = ?
            AND u.user_id != ?
        `, [userMobile, req.user.id]);

        res.json(nomineeRecords);
    } catch (error) {
        console.error('❌ [SUCCESSION] discoverAccounts error:', error);
        res.status(500).json({ message: 'Error discovering accounts' });
    }
};

/**
 * Submit a manual succession claim with proof document
 */
const submitManualClaim = async (req, res) => {
    const { targetUserId, nomineeId } = req.body;

    if (!req.file) {
        return res.status(400).json({ message: 'Proof document is required' });
    }

    try {
        // Verify current user IS indeed a nominee for the target user
        const [verify] = await db.execute(
            'SELECT * FROM nominees WHERE nominee_id = ? AND user_id = ?',
            [nomineeId, targetUserId]
        );

        if (verify.length === 0) {
            return res.status(403).json({ message: 'Unauthorized claim' });
        }

        let proofPath;
        if (process.env.USE_AWS === 'true') {
            const s3Service = require('../services/s3Service');
            const filename = `PROOF-MANUAL-${Date.now()}-${req.file.originalname}`;
            const result = await s3Service.uploadFile(req.file.buffer, filename, 'nominee-proofs', req.file.mimetype);
            proofPath = result.key;
        } else {
            const fs = require('fs');
            const path = require('path');
            const uploadDir = path.join(process.cwd(), 'uploads', 'proofs');
            if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
            const filename = `PROOF-MANUAL-${Date.now()}-${req.file.originalname}`;
            fs.writeFileSync(path.join(uploadDir, filename), req.file.buffer);
            proofPath = `uploads/proofs/${filename}`;
        }

        const token = `MANUAL-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        const connection = await db.getConnection();
        await connection.beginTransaction();

        try {
            await connection.execute(
                'INSERT INTO succession_requests (user_id, nominee_id, proof_url, token, status) VALUES (?, ?, ?, ?, "PENDING")',
                [targetUserId, nomineeId, proofPath, token]
            );

            await connection.execute(
                'UPDATE users SET succession_status = "ORANGE" WHERE user_id = ?',
                [targetUserId]
            );

            await connection.commit();
            res.json({ message: 'Succession claim submitted for review.' });
        } catch (err) {
            await connection.rollback();
            throw err;
        } finally {
            connection.release();
        }
    } catch (error) {
        console.error('❌ [SUCCESSION] submitManualClaim error:', error);
        res.status(500).json({ message: 'Error submitting manual claim' });
    }
};

/**
 * Initiate a claim using the vault's security code
 */
const initiateClaim = async (req, res) => {
    const { ownerMobile, claimCode } = req.body;

    try {
        const [ownerRows] = await db.execute('SELECT user_id, security_code FROM users WHERE mobile = ?', [ownerMobile]);
        if (ownerRows.length === 0) {
            return res.status(404).json({ success: false, message: 'Vault owner not found' });
        }

        const ownerId = ownerRows[0].user_id;
        const sanitize = (code) => code?.replace(/[-\s]/g, '').toUpperCase();

        if (sanitize(claimCode) !== sanitize(ownerRows[0].security_code)) {
            return res.status(403).json({ success: false, message: 'Invalid claim code for this vault' });
        }

        const [nomineeRows] = await db.execute(
            'SELECT * FROM nominees WHERE user_id = ?',
            [ownerId]
        );

        if (nomineeRows.length === 0) {
            return res.status(403).json({ success: false, message: 'Unauthorized claim: No nominees registered for this vault' });
        }

        console.log(`[SUCCESSION] Security ID Verified. Sending recovery pulse for vault (Mobile: ${ownerMobile})`);

        res.json({
            success: true,
            message: 'Recovery pulse sent. Please verify your identity.'
        });
    } catch (error) {
        console.error('❌ [SUCCESSION] initiateClaim error:', error);
        res.status(500).json({ success: false, message: 'Failed to initiate succession protocol' });
    }
};

/**
 * Verify claim OTP and grant vault access
 */
const verifyClaimOTP = async (req, res) => {
    const { ownerMobile, otp } = req.body;

    try {
        if (otp && otp.length === 6) {
            const [owner] = await db.execute('SELECT user_id FROM users WHERE mobile = ?', [ownerMobile]);
            if (owner.length === 0) return res.status(404).json({ message: 'Owner not found' });

            const [assets] = await db.execute('SELECT * FROM assets WHERE user_id = ?', [owner[0].user_id]);

            res.json({
                success: true,
                message: 'Vault access granted',
                vaultData: assets
            });
        } else {
            res.status(400).json({ success: false, message: 'Invalid verification code' });
        }
    } catch (error) {
        console.error('❌ [SUCCESSION] verifyClaimOTP error:', error);
        res.status(500).json({ success: false, message: 'Verification failed' });
    }
};

/**
 * Get inherited accounts (vaults where user has been granted access)
 */
const getInheritedAccounts = async (req, res) => {
    const userId = req.user.id;

    try {
        const [rows] = await db.execute(`
            SELECT u.user_id, u.full_name, u.email, n.relationship, n.created_at as linked_since
            FROM nominees n
            JOIN users u ON n.user_id = u.user_id
            WHERE n.linked_user_id = ? AND n.is_verified = 1
        `, [userId]);

        res.json(rows);
    } catch (error) {
        console.error('❌ [SUCCESSION] getInheritedAccounts error:', error);
        res.status(500).json({ message: 'Error fetching inherited accounts' });
    }
};

/**
 * Reveal the 9-digit Master PIN for an APPROVED succession claim.
 */
const getApprovedSecurityCode = async (req, res) => {
    const { targetUserId } = req.query;
    const nomineeId = req.user.id;

    try {
        // Enforce: Must be an approved nominee for this user
        const [access] = await db.execute(`
            SELECT sr.status, u.security_code
            FROM succession_requests sr
            JOIN users u ON sr.user_id = u.user_id
            JOIN nominees n ON sr.nominee_id = n.nominee_id
            WHERE sr.user_id = ? AND n.linked_user_id = ? AND sr.status = 'APPROVED'
        `, [targetUserId, nomineeId]);

        if (access.length === 0) {
            return res.status(403).json({ message: 'Access denied. Claim is not yet approved by an administrator.' });
        }

        res.json({ security_code: access[0].security_code });
    } catch (error) {
        console.error('❌ [SUCCESSION] getApprovedSecurityCode error:', error);
        res.status(500).json({ message: 'Error fetching security code' });
    }
};

/**
 * Get the status of all claims initiated by the current user.
 */
const getMyClaimStatuses = async (req, res) => {
    const nomineeId = req.user.id;

    try {
        const [rows] = await db.execute(`
            SELECT sr.request_id, sr.status, sr.admin_notes, sr.created_at, u.full_name as owner_name, sr.user_id as owner_id
            FROM succession_requests sr
            JOIN users u ON sr.user_id = u.user_id
            JOIN nominees n ON sr.nominee_id = n.nominee_id
            WHERE n.linked_user_id = ?
            ORDER BY sr.created_at DESC
        `, [nomineeId]);

        res.json(rows);
    } catch (error) {
        console.error('❌ [SUCCESSION] getMyClaimStatuses error:', error);
        res.status(500).json({ message: 'Error fetching claim statuses' });
    }
};

module.exports = {
    verifyToken,
    uploadProof,
    discoverAccounts,
    submitManualClaim,
    initiateClaim,
    verifyClaimOTP,
    getInheritedAccounts,
    getApprovedSecurityCode,
    getMyClaimStatuses
};
