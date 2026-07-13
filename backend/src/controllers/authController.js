const db = require('../config/db');
const { hashData, compareData } = require('../utils/hash');
const jwt = require('jsonwebtoken');
const { sendEmailOTP } = require('../services/emailService');
const { sendOTP } = require('../services/otpProvider');
const User = require('../models/userModel');
const InactivityService = require('../services/inactivityService');

// ═══════════════════════════════════════════════════════
// SECURITY CODE GENERATOR
// ═══════════════════════════════════════════════════════

const generateSecurityCode = async () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code;
    let isUnique = false;

    while (!isUnique) {
        code = Array.from({ length: 9 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
        const [rows] = await db.execute('SELECT user_id FROM users WHERE security_code = ?', [code]);
        if (rows.length === 0) isUnique = true;
    }
    return code;
};

// ═══════════════════════════════════════════════════════
// LOGIN
// ═══════════════════════════════════════════════════════

const login = async (req, res) => {
    const { identifier, password } = req.body;

    try {
        const user = await User.findByIdentifier(identifier);

        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Check if account is locked
        if (user.locked_until && new Date(user.locked_until) > new Date()) {
            return res.status(403).json({
                message: 'Account is temporarily locked. Please try again later.'
            });
        }

        const isMatch = await compareData(password, user.password_hash);

        if (!isMatch) {
            await User.incrementFailedAttempts(user.user_id);
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Reset failed attempts on success
        await User.resetFailedAttempts(user.user_id);

        // --- BYPASS OTP FOR ADMIN ---
        if (user.role === 'ADMIN' || user.email === 'admin@stardust.com') {
            const token = jwt.sign(
                { id: user.user_id, role: user.role, email: user.email, mobile: user.mobile },
                process.env.JWT_SECRET,
                { expiresIn: '4h' }
            );

            // Reset inactivity on admin login
            await InactivityService.resetInactivityOnLogin(user.user_id);

            return res.json({
                message: 'Admin authenticated successfully.',
                status: 'SUCCESS',
                token,
                user: {
                    id: user.user_id,
                    full_name: user.full_name,
                    email: user.email,
                    mobile: user.mobile,
                    role: user.role,
                    is_verified: 1,
                    has_completed_onboarding: !!user.has_completed_onboarding
                }
            });
        }

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

        const channel = identifier.includes('@') ? 'EMAIL' : 'WHATSAPP';

        await db.execute(
            'INSERT INTO otp_codes (user_id, otp_code, channel, expires_at) VALUES (?, ?, ?, ?)',
            [user.user_id, otp_hash, channel, expires_at]
        );

        console.log(`🔑 [DEVELOPMENT]: OTP for ${user.email} (${user.mobile}): ${otp}`);

        // Audit log
        const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
        try {
            await db.execute(
                'INSERT INTO audit_logs (user_id, action, ip_address, device_info) VALUES (?, ?, ?, ?)',
                [user.user_id, 'LOGIN_ATTEMPT_SUCCESS', ip, req.headers['user-agent']]
            );
        } catch (auditErr) {
            console.error('⚠️ [AUDIT LOG ERROR]:', auditErr.message);
        }

        // Send OTP via appropriate channel
        try {
            if (channel === 'EMAIL') {
                await sendEmailOTP(user.email, otp);
            } else {
                await sendOTP(user.mobile, otp);
            }
        } catch (sendErr) {
            console.error('❌ [CRITICAL] Failed to send OTP:', sendErr.message);
            return res.status(503).json({
                message: 'Failed to send OTP. Please check service configuration.',
                error: sendErr.message
            });
        }

        res.json({
            message: `Step 1 complete: Password verified. OTP required via ${channel}.`,
            status: 'OTP_REQUIRED',
            userId: user.user_id,
            destinationSnippet: channel === 'EMAIL' ? user.email : `XXXXXX${user.mobile.slice(-4)}`
        });

    } catch (error) {
        console.error('❌ [AUTH] Login error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// ═══════════════════════════════════════════════════════
// REGISTER
// ═══════════════════════════════════════════════════════

const register = async (req, res) => {
    const {
        fullName,
        full_name,
        email,
        mobile,
        password,
        securityAnswers,
        security_answers
    } = req.body;

    const actualFullName = fullName || full_name;
    const actualSecurityAnswers = securityAnswers || security_answers;

    console.log(`🚀 [REGISTRATION]: Starting for ${email || 'No Email'}, Mobile: ${mobile}`);

    if (!actualFullName || !mobile || !password || !actualSecurityAnswers) {
        return res.status(400).json({ message: 'Missing required registration fields' });
    }

    try {
        // Check if user already exists
        const [existing] = await db.execute(
            'SELECT user_id FROM users WHERE mobile = ?' + (email ? ' OR email = ?' : ''),
            email ? [mobile, email] : [mobile]
        );

        if (existing.length > 0) {
            return res.status(400).json({ message: 'Account already exists. Please try login or forgot password.' });
        }

        const password_hash = await hashData(password);

        // Generate Registration OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

        // Clean up any existing pending registration
        await db.execute('DELETE FROM pending_registrations WHERE mobile = ?' + (email ? ' OR email = ?' : ''), email ? [mobile, email] : [mobile]);

        // Store in PENDING table
        await db.execute(
            'INSERT INTO pending_registrations (full_name, email, mobile, password_hash, security_answers_json, otp_code_hash, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [actualFullName, email || '', mobile, password_hash, JSON.stringify(actualSecurityAnswers), otp_hash, expires_at]
        );

        const channel = email ? 'EMAIL' : 'WHATSAPP';

        // ─── HIGH VISIBILITY LOG FOR OTP (DEV DEBUGGING) ───
        console.log('\n' + '█'.repeat(60));
        console.log(`🔑 [STARDUST OTP] ${channel} for ${mobile} (${email || 'No Email'}):`);
        console.log(`👉 VERIFICATION CODE: ${otp}`);
        console.log('█'.repeat(60) + '\n');

        try {
            if (channel === 'EMAIL' && email) {
                await sendEmailOTP(email, otp);
            } else {
                await sendOTP(mobile, otp);
            }
        } catch (sendErr) {
            console.error('⚠️ Failed during registration OTP send (Fallback to log):', sendErr.message);
            // We DON'T throw here, to allow dev-mode signup to continue via logs
        }

        res.status(200).json({
            message: `OTP sent to ${channel}. Please verify to complete registration.`,
            status: 'REGISTRATION_OTP_REQUIRED',
            email,
            destinationSnippet: channel === 'EMAIL' ? email : `XXXXXX${mobile.slice(-4)}`
        });

    } catch (error) {
        console.error('❌ [AUTH] Registration error:', error);
        res.status(500).json({ message: 'Server error during registration', error: error.message });
    }
};

// ═══════════════════════════════════════════════════════
// SECURITY QUESTIONS
// ═══════════════════════════════════════════════════════

const getSecurityQuestions = async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM security_questions');
        res.json(rows);
    } catch (error) {
        console.error('❌ [AUTH] Error fetching security questions:', error.message);
        res.status(500).json({ message: 'Error fetching questions', diagnostic: error.message });
    }
};

// ═══════════════════════════════════════════════════════
// VERIFY OTP (Login + Registration)
// ═══════════════════════════════════════════════════════

const verifyOTP = async (req, res) => {
    const { userId, otp, email, mobile } = req.body;

    try {
        // 1. Login Verification
        if (userId) {
            const [rows] = await db.execute(
                'SELECT * FROM otp_codes WHERE user_id = ? AND is_used = 0 ORDER BY created_at DESC LIMIT 1',
                [userId]
            );

            if (rows.length > 0) {
                if (new Date(rows[0].expires_at) < new Date()) {
                    return res.status(400).json({ message: 'OTP expired' });
                }

                const isMatch = await compareData(otp, rows[0].otp_code);
                if (!isMatch) {
                    return res.status(400).json({ message: 'Invalid OTP' });
                }

                await db.execute('UPDATE otp_codes SET is_used = 1 WHERE otp_id = ?', [rows[0].otp_id]);
                await db.execute('UPDATE users SET is_verified = 1 WHERE user_id = ?', [userId]);

                // Reset inactivity protocol on successful login verification
                await InactivityService.resetInactivityOnLogin(userId);

                const [userRows] = await db.execute('SELECT * FROM users WHERE user_id = ?', [userId]);
                const user = userRows[0];

                const token = jwt.sign(
                    { id: user.user_id, role: user.role, email: user.email, mobile: user.mobile },
                    process.env.JWT_SECRET,
                    { expiresIn: '4h' }
                );

                return res.json({
                    message: 'Verification successful. Accessing vault...',
                    token,
                    securityCode: user.security_code,
                    user: {
                        id: user.user_id,
                        full_name: user.full_name,
                        email: user.email,
                        mobile: user.mobile,
                        role: user.role,
                        is_verified: 1,
                        has_completed_onboarding: !!user.has_completed_onboarding
                    }
                });
            }
        }

        // 2. Registration Verification
        const identifier = email || mobile;
        if (identifier) {
            const [pending] = await db.execute(
                'SELECT * FROM pending_registrations WHERE email = ? OR mobile = ? ORDER BY created_at DESC LIMIT 1',
                [identifier, identifier]
            );

            if (pending.length === 0) {
                return res.status(400).json({ message: 'No registration data found. Please register again.' });
            }

            if (new Date(pending[0].expires_at) < new Date()) {
                return res.status(400).json({ message: 'Registration OTP expired' });
            }

            const isMatch = await compareData(otp, pending[0].otp_code_hash);
            if (!isMatch) {
                return res.status(400).json({ message: 'Invalid Registration OTP' });
            }

            // ATOMIC USER CREATION
            const connection = await db.getConnection();
            await connection.beginTransaction();

            try {
                const rawSecurityCode = await generateSecurityCode();
                const p = pending[0];

                const [userResult] = await connection.execute(
                    'INSERT INTO users (full_name, email, mobile, password_hash, security_code, is_verified, has_completed_onboarding) VALUES (?, ?, ?, ?, ?, ?, ?)',
                    [p.full_name, p.email, p.mobile, p.password_hash, rawSecurityCode, 1, 0]
                );

                const newUserId = userResult.insertId;

                // Save security answers
                let securityAnswers = p.security_answers_json;
                if (typeof securityAnswers === 'string') {
                    try {
                        securityAnswers = JSON.parse(securityAnswers);
                    } catch (e) {
                        securityAnswers = [];
                    }
                }

                if (Array.isArray(securityAnswers)) {
                    for (const ans of securityAnswers) {
                        if (!ans.question_id || !ans.answer) continue;
                        const answer_hash = await hashData(ans.answer.toLowerCase());
                        await connection.execute(
                            'INSERT INTO user_security_answers (user_id, question_id, answer_hash) VALUES (?, ?, ?)',
                            [newUserId, ans.question_id, answer_hash]
                        );
                    }
                }

                // Link nominee records
                await connection.execute(
                    'UPDATE nominees SET linked_user_id = ? WHERE email = ? OR mobile = ?',
                    [newUserId, p.email, p.mobile]
                );

                await connection.execute('DELETE FROM pending_registrations WHERE id = ?', [p.id]);
                await connection.commit();

                const [userRows] = await connection.execute('SELECT * FROM users WHERE user_id = ?', [newUserId]);
                const user = userRows[0];

                const token = jwt.sign(
                    { id: user.user_id, role: user.role, email: user.email, mobile: user.mobile },
                    process.env.JWT_SECRET,
                    { expiresIn: '4h' }
                );

                return res.json({
                    message: 'Registration complete! Welcome to Stardust.',
                    token,
                    securityCode: user.security_code,
                    user: {
                        id: user.user_id,
                        full_name: user.full_name,
                        email: user.email,
                        mobile: user.mobile,
                        role: user.role,
                        is_verified: 1,
                        has_completed_onboarding: 0
                    }
                });

            } catch (innerError) {
                await connection.rollback();
                throw innerError;
            } finally {
                connection.release();
            }
        }

        return res.status(400).json({ message: 'Invalid verification request' });

    } catch (error) {
        console.error('❌ [AUTH] OTP verification error:', error);
        res.status(500).json({
            message: 'Server error during OTP verification',
            diagnostic: error.message
        });
    }
};

// ═══════════════════════════════════════════════════════
// FORGOT PASSWORD FLOW
// ═══════════════════════════════════════════════════════

const forgotPassword = async (req, res) => {
    const { identifier } = req.body;
    try {
        const isEmail = identifier.includes('@');
        const [rows] = await db.execute(
            isEmail ? 'SELECT * FROM users WHERE email = ?' : 'SELECT * FROM users WHERE mobile = ?',
            [identifier]
        );
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        const user = rows[0];

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 5 * 60 * 1000);

        await db.execute(
            'UPDATE users SET reset_otp_hash = ?, reset_otp_expires_at = ?, reset_verified = 0 WHERE user_id = ?',
            [otp_hash, expires_at, user.user_id]
        );

        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
        console.log(`FORGOT PASSWORD OTP for ${user.mobile}: ${otp}`);
        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

        const channel = isEmail ? 'EMAIL' : 'WHATSAPP';
        try {
            if (channel === 'EMAIL') {
                await sendEmailOTP(user.email, otp);
            } else {
                await sendOTP(user.mobile, otp);
            }
            res.json({
                message: `Password reset OTP sent to ${channel}`,
                userId: user.user_id,
                destinationSnippet: channel === 'EMAIL' ? user.email : `XXXXXX${user.mobile.slice(-4)}`
            });
        } catch (sendErr) {
            console.error('Failed for forgot password:', sendErr.message);
            res.status(503).json({ message: 'Failed to send OTP. Please try again.' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

const verifyForgotOTP = async (req, res) => {
    const { userId, otp } = req.body;
    try {
        const [rows] = await db.execute(
            'SELECT reset_otp_hash, reset_otp_expires_at FROM users WHERE user_id = ?',
            [userId]
        );
        if (rows.length === 0 || !rows[0].reset_otp_hash) {
            return res.status(400).json({ message: 'No reset request found' });
        }
        if (new Date(rows[0].reset_otp_expires_at) < new Date()) {
            return res.status(400).json({ message: 'OTP expired' });
        }
        const isMatch = await compareData(otp, rows[0].reset_otp_hash);
        if (!isMatch) return res.status(400).json({ message: 'Invalid OTP' });

        await db.execute('UPDATE users SET reset_verified = 1 WHERE user_id = ?', [userId]);

        const resetToken = jwt.sign(
            { id: userId, purpose: 'FORGOT_PASSWORD_RESET' },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );
        res.json({ message: 'OTP verified successfully', resetToken });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

const resetPasswordAfterForgot = async (req, res) => {
    const { resetToken, newPassword } = req.body;
    try {
        const decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
        if (decoded.purpose !== 'FORGOT_PASSWORD_RESET') return res.status(401).json({ message: 'Invalid reset token' });

        const [userRows] = await db.execute('SELECT reset_verified FROM users WHERE user_id = ?', [decoded.id]);
        if (userRows.length === 0 || !userRows[0].reset_verified) return res.status(401).json({ message: 'Reset not authorized' });

        const hashedPassword = await hashData(newPassword);
        await db.execute(
            'UPDATE users SET password_hash = ?, reset_otp_hash = NULL, reset_otp_expires_at = NULL, reset_verified = 0 WHERE user_id = ?',
            [hashedPassword, decoded.id]
        );
        res.json({ message: 'Password has been reset successfully' });
    } catch (error) {
        console.error(error);
        res.status(401).json({ message: 'Invalid or expired reset token' });
    }
};

// ═══════════════════════════════════════════════════════
// ACCOUNT RECOVERY (Security Questions)
// ═══════════════════════════════════════════════════════

const getRecoveryQuestions = async (req, res) => {
    const { email } = req.body;
    try {
        const [users] = await db.execute('SELECT user_id FROM users WHERE email = ?', [email]);
        if (users.length === 0) return res.status(404).json({ message: 'User not found' });

        const userId = users[0].user_id;
        const [questions] = await db.execute(`
            SELECT q.question_id, q.question 
            FROM security_questions q
            JOIN user_security_answers usa ON q.question_id = usa.question_id
            WHERE usa.user_id = ?
        `, [userId]);

        res.json(questions);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching recovery questions' });
    }
};

const verifyRecoveryAnswers = async (req, res) => {
    const { email, answers } = req.body;
    try {
        const [users] = await db.execute('SELECT user_id FROM users WHERE email = ?', [email]);
        if (users.length === 0) return res.status(404).json({ message: 'User not found' });

        const userId = users[0].user_id;
        const [storedAnswers] = await db.execute('SELECT question_id, answer_hash FROM user_security_answers WHERE user_id = ?', [userId]);

        let correctCount = 0;
        for (const ans of answers) {
            const stored = storedAnswers.find(s => s.question_id === ans.question_id);
            if (stored && await compareData(ans.answer.toLowerCase(), stored.answer_hash)) {
                correctCount++;
            }
        }

        if (correctCount >= storedAnswers.length && storedAnswers.length > 0) {
            const recoveryToken = jwt.sign(
                { id: userId, purpose: 'RECOVERY' },
                process.env.JWT_SECRET,
                { expiresIn: '15m' }
            );
            res.json({ success: true, recoveryToken });
        } else {
            res.status(400).json({ message: 'Incorrect security answers' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Recovery verification failed' });
    }
};

const resetPassword = async (req, res) => {
    const { mobile, newPassword, recoveryToken } = req.body;
    try {
        const decoded = jwt.verify(recoveryToken, process.env.JWT_SECRET);
        if (decoded.purpose !== 'RECOVERY') return res.status(401).json({ message: 'Invalid token' });

        const hashedPassword = await hashData(newPassword);
        await db.execute('UPDATE users SET password_hash = ? WHERE user_id = ?', [hashedPassword, decoded.id]);

        res.json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error(error);
        res.status(401).json({ message: 'Invalid or expired recovery token' });
    }
};

// ═══════════════════════════════════════════════════════
// MULTI-METHOD RECOVERY (Lookup → OTP → Security → Update)
// ═══════════════════════════════════════════════════════

const recoverLookup = async (req, res) => {
    const { identifier } = req.body;
    try {
        const user = await User.findByIdentifier(identifier);
        if (!user) return res.status(404).json({ message: 'Account not found in the distributed ledger.' });

        const [nominees] = await db.execute('SELECT COUNT(*) as count FROM nominees WHERE user_id = ?', [user.user_id]);

        const methods = [
            { id: 'email', label: 'Email Pulse', hint: `Send to ${user.email.replace(/(.{2})(.*)(@.*)/, '$1***$3')}` },
            { id: 'phone', label: 'WhatsApp Pulse', hint: `Send to XXXXXX${user.mobile.slice(-4)}` }
        ];

        if (nominees[0].count > 0) {
            methods.push({ id: 'nominee', label: 'Nominee Bypass', hint: 'Verify via your registered nominees.' });
        }

        res.json({ userId: user.user_id, methods });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lookup protocol failure.' });
    }
};

const recoverSendOTP = async (req, res) => {
    const { userId, method } = req.body;
    try {
        const [rows] = await db.execute('SELECT email, mobile FROM users WHERE user_id = ?', [userId]);
        if (rows.length === 0) return res.status(404).json({ message: 'User not found.' });

        const user = rows[0];
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 10 * 60 * 1000);

        await db.execute(
            'INSERT INTO otp_codes (user_id, otp_code, channel, expires_at) VALUES (?, ?, ?, ?)',
            [userId, otp_hash, method === 'email' ? 'EMAIL' : 'WHATSAPP', expires_at]
        );

        console.log(`[RECOVERY OTP] Method: ${method}, User: ${user.email}, OTP: ${otp}`);

        if (method === 'email') {
            await sendEmailOTP(user.email, otp);
        } else {
            let targetMobile = user.mobile;
            if (method === 'nominee') {
                const [n] = await db.execute('SELECT mobile FROM nominees WHERE user_id = ? LIMIT 1', [userId]);
                if (n.length > 0) targetMobile = n[0].mobile;
            }
            await sendOTP(targetMobile, otp);
        }

        res.json({ message: `Verification pulse sent via ${method}.` });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to transmit verification pulse.' });
    }
};

const recoverVerify = async (req, res) => {
    const { userId, phase, otp, answers } = req.body;
    try {
        if (phase === 'otp') {
            const [rows] = await db.execute(
                'SELECT * FROM otp_codes WHERE user_id = ? AND is_used = 0 ORDER BY created_at DESC LIMIT 1',
                [userId]
            );

            if (rows.length === 0 || new Date(rows[0].expires_at) < new Date()) {
                return res.status(400).json({ message: 'Pulse expired or invalid.' });
            }

            const isMatch = await compareData(otp, rows[0].otp_code);
            if (!isMatch) return res.status(400).json({ message: 'Incorrect pulse sequence.' });

            await db.execute('UPDATE otp_codes SET is_used = 1 WHERE otp_id = ?', [rows[0].otp_id]);

            const [questions] = await db.execute(`
                SELECT q.question_id, q.question 
                FROM security_questions q
                JOIN user_security_answers usa ON q.question_id = usa.question_id
                WHERE usa.user_id = ?
            `, [userId]);

            return res.json({ securityQuestions: questions });
        }

        if (phase === 'security') {
            const [storedAnswers] = await db.execute('SELECT question_id, answer_hash FROM user_security_answers WHERE user_id = ?', [userId]);
            if (storedAnswers.length === 0) return res.status(400).json({ message: 'No security protocols configured for this account.' });

            let correctCount = 0;
            for (const ans of answers) {
                const stored = storedAnswers.find(s => s.question_id === ans.question_id);
                if (stored && await compareData(ans.answer.toLowerCase(), stored.answer_hash)) {
                    correctCount++;
                }
            }

            if (correctCount >= storedAnswers.length) {
                const resetToken = jwt.sign(
                    { id: userId, purpose: 'FULL_RECOVERY' },
                    process.env.JWT_SECRET,
                    { expiresIn: '15m' }
                );

                const [user] = await db.execute('SELECT email, mobile FROM users WHERE user_id = ?', [userId]);

                return res.json({
                    resetToken,
                    currentEmail: user[0].email,
                    currentMobile: user[0].mobile
                });
            } else {
                return res.status(400).json({ message: 'Security protocol verification failed.' });
            }
        }

        res.status(400).json({ message: 'Invalid recovery phase.' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Verification protocol failure.' });
    }
};

const recoverUpdateAccount = async (req, res) => {
    const { resetToken, email, mobile, password } = req.body;
    try {
        const decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
        if (decoded.purpose !== 'FULL_RECOVERY') return res.status(401).json({ message: 'Invalid restoration token.' });

        const updates = [];
        const values = [];

        if (email) { updates.push('email = ?'); values.push(email); }
        if (mobile) { updates.push('mobile = ?'); values.push(mobile); }
        if (password) {
            const hash = await hashData(password);
            updates.push('password_hash = ?');
            values.push(hash);
        }

        if (updates.length === 0) return res.status(400).json({ message: 'No parameters provided for reconfiguration.' });

        values.push(decoded.id);
        await db.execute(`UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE user_id = ?`, values);

        res.json({ message: 'Vault reconfigured successfully.' });
    } catch (error) {
        console.error(error);
        res.status(401).json({ message: 'Invalid or expired restoration token.' });
    }
};

// ═══════════════════════════════════════════════════════
// ONBOARDING
// ═══════════════════════════════════════════════════════

const completeOnboarding = async (req, res) => {
    try {
        const userId = req.user.id;
        await db.execute('UPDATE users SET has_completed_onboarding = 1 WHERE user_id = ?', [userId]);
        res.json({ message: 'Onboarding completed successfully', has_completed_onboarding: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to complete onboarding' });
    }
};

const getOnboardingStatus = async (req, res) => {
    try {
        const userId = req.user.id;
        const [rows] = await db.execute('SELECT has_completed_onboarding FROM users WHERE user_id = ?', [userId]);
        if (rows.length === 0) return res.status(404).json({ message: 'User not found' });
        res.json({ has_completed_onboarding: !!rows[0].has_completed_onboarding });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch onboarding status' });
    }
};

// ═══════════════════════════════════════════════════════
// NOMINEE MANAGEMENT
// ═══════════════════════════════════════════════════════

const saveNominee = async (req, res) => {
    const { full_name, mobile, country_code, relationship } = req.body;
    const userId = req.user.id;

    if (!full_name || !mobile || !relationship) {
        return res.status(400).json({ message: 'Nominee Name, Phone, and Relationship are required' });
    }

    try {
        const [userRows] = await db.execute('SELECT nominee_limit FROM users WHERE user_id = ?', [userId]);
        const limit = userRows[0]?.nominee_limit || 2;

        const [nominees] = await db.execute('SELECT nominee_id, mobile FROM nominees WHERE user_id = ?', [userId]);
        const fullMobile = (country_code || '+91') + mobile;
        const existingNominee = nominees.find(n => n.mobile === fullMobile);

        // Check if the nominee already has a user account
        const [existingUserRows] = await db.execute(
            'SELECT user_id FROM users WHERE mobile = ?',
            [fullMobile]
        );
        const linkedUserId = existingUserRows[0]?.user_id || null;

        if (existingNominee) {
            await db.execute(
                'UPDATE nominees SET full_name = ?, mobile = ?, relationship = ?, linked_user_id = ?, updated_at = NOW() WHERE nominee_id = ?',
                [full_name, fullMobile, relationship, linkedUserId, existingNominee.nominee_id]
            );
        } else {
            if (nominees.length >= limit) {
                return res.status(400).json({ message: `Maximum of ${limit} nominees allowed for your vault policy.` });
            }
            await db.execute(
                'INSERT INTO nominees (user_id, full_name, mobile, relationship, linked_user_id) VALUES (?, ?, ?, ?, ?)',
                [userId, full_name, fullMobile, relationship, linkedUserId]
            );
        }

        res.json({ message: 'Nominee information saved successfully.' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to save nominee' });
    }
};

const getNominee = async (req, res) => {
    try {
        const userId = req.user.id;
        const [rows] = await db.execute('SELECT * FROM nominees WHERE user_id = ?', [userId]);
        res.json({ nominees: rows });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to fetch nominees' });
    }
};

// ═══════════════════════════════════════════════════════
// EMAIL VERIFICATION (Primary Account)
// ═══════════════════════════════════════════════════════

const sendUserEmailOTP = async (req, res) => {
    const userId = req.user.id;
    const { email: providedEmail } = req.body;

    try {
        let emailToVerify;

        if (providedEmail) {
            emailToVerify = providedEmail;
        } else {
            const [user] = await db.execute('SELECT email FROM users WHERE user_id = ?', [userId]);
            emailToVerify = user[0]?.email;
        }

        if (!emailToVerify) return res.status(400).json({ message: 'No email provided or found for this account' });

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 10 * 60 * 1000);

        await db.execute(
            'INSERT INTO otp_codes (user_id, otp_code, channel, expires_at) VALUES (?, ?, ?, ?)',
            [userId, otp_hash, 'EMAIL', expires_at]
        );

        await sendEmailOTP(emailToVerify, otp);
        res.json({ message: `Verification OTP sent to ${emailToVerify}` });
    } catch (error) {
        console.error('❌ [AUTH] User Email OTP Error:', error);
        res.status(500).json({ message: 'Failed to send email OTP' });
    }
};

const verifyUserEmailOTP = async (req, res) => {
    const { otp, email: verifiedEmail } = req.body;
    const userId = req.user.id;
    try {
        const [rows] = await db.execute(
            'SELECT * FROM otp_codes WHERE user_id = ? AND channel = "EMAIL" AND is_used = 0 ORDER BY created_at DESC LIMIT 1',
            [userId]
        );

        if (rows.length === 0 || new Date(rows[0].expires_at) < new Date()) {
            return res.status(400).json({ message: 'Invalid or expired OTP' });
        }

        const isMatch = await compareData(otp, rows[0].otp_code);
        if (!isMatch) return res.status(400).json({ message: 'Invalid OTP' });

        await db.execute('UPDATE otp_codes SET is_used = 1 WHERE otp_id = ?', [rows[0].otp_id]);

        if (verifiedEmail) {
            await db.execute('UPDATE users SET email = ?, is_email_verified = 1 WHERE user_id = ?', [verifiedEmail, userId]);
        } else {
            await db.execute('UPDATE users SET is_email_verified = 1 WHERE user_id = ?', [userId]);
        }

        res.json({
            message: 'Your email has been verified successfully',
            is_email_verified: true,
            email: verifiedEmail || null
        });
    } catch (error) {
        console.error('❌ [AUTH] Verify Email OTP Error:', error);
        res.status(500).json({ message: 'Failed to verify email OTP' });
    }
};

// ═══════════════════════════════════════════════════════
// NOMINEE VERIFICATION (Email + Phone OTP)
// ═══════════════════════════════════════════════════════

const sendNomineeEmailOTP = async (req, res) => {
    const { email } = req.body;
    const userId = req.user.id;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    try {
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 10 * 60 * 1000);

        await db.execute(
            'INSERT INTO otp_codes (user_id, otp_code, channel, expires_at) VALUES (?, ?, ?, ?)',
            [userId, otp_hash, 'EMAIL', expires_at]
        );

        await sendEmailOTP(email, otp);
        res.json({ message: `Verification OTP sent to ${email}` });
    } catch (error) {
        console.error('❌ [AUTH] Nominee Email OTP Error:', error);
        res.status(500).json({ message: 'Failed to send email OTP' });
    }
};

const verifyNomineeEmailOTP = async (req, res) => {
    const { otp, email } = req.body;
    const userId = req.user.id;
    try {
        const [rows] = await db.execute(
            'SELECT * FROM otp_codes WHERE user_id = ? AND channel = "EMAIL" AND is_used = 0 ORDER BY created_at DESC LIMIT 1',
            [userId]
        );

        if (rows.length === 0 || new Date(rows[0].expires_at) < new Date()) {
            return res.status(400).json({ message: 'Invalid or expired OTP' });
        }

        const isMatch = await compareData(otp, rows[0].otp_code);
        if (!isMatch) return res.status(400).json({ message: 'Invalid OTP' });

        await db.execute('UPDATE otp_codes SET is_used = 1 WHERE otp_id = ?', [rows[0].otp_id]);

        if (email) {
            await db.execute(
                'UPDATE nominees SET is_email_verified = 1 WHERE user_id = ? AND email = ?',
                [userId, email]
            );
        }

        res.json({ message: 'Email verified successfully', is_email_verified: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to verify email OTP' });
    }
};

const sendNomineePhoneOTP = async (req, res) => {
    const { mobile, country_code } = req.body;
    const userId = req.user.id;
    if (!mobile) return res.status(400).json({ message: 'Mobile number is required' });
    const fullMobile = (country_code || '+91') + mobile;
    try {
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otp_hash = await hashData(otp);
        const expires_at = new Date(Date.now() + 10 * 60 * 1000);
        await db.execute('INSERT INTO otp_codes (user_id, otp_code, channel, expires_at) VALUES (?, ?, ?, ?)', [userId, otp_hash, 'WHATSAPP', expires_at]);
        await sendOTP(fullMobile, otp);
        res.json({ message: `OTP sent to ${fullMobile}` });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to send phone OTP' });
    }
};

const verifyNomineePhoneOTP = async (req, res) => {
    const { otp } = req.body;
    const userId = req.user.id;
    try {
        const [rows] = await db.execute('SELECT * FROM otp_codes WHERE user_id = ? AND channel = "WHATSAPP" AND is_used = 0 ORDER BY created_at DESC LIMIT 1', [userId]);
        if (rows.length === 0 || new Date(rows[0].expires_at) < new Date()) return res.status(400).json({ message: 'Invalid or expired OTP' });
        const isMatch = await compareData(otp, rows[0].otp_code);
        if (!isMatch) return res.status(400).json({ message: 'Invalid OTP' });
        await db.execute('UPDATE otp_codes SET is_used = 1 WHERE otp_id = ?', [rows[0].otp_id]);
        res.json({ message: 'Phone verified successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Failed to verify phone OTP' });
    }
};

// ═══════════════════════════════════════════════════════
// PROFILE & VAULT POLICY
// ═══════════════════════════════════════════════════════

const getUserProfile = async (req, res) => {
    let userId = req.user.id;
    const vaultContext = req.header('x-vault-context');

    try {
        if (vaultContext && vaultContext !== 'null') {
            const [access] = await db.execute(`
                SELECT u.user_id FROM users u JOIN nominees n ON u.user_id = n.user_id 
                WHERE u.user_id = ? AND n.linked_user_id = ?
            `, [vaultContext, req.user.id]);
            if (access.length > 0) userId = vaultContext;
        }

        const [rows] = await db.execute('SELECT user_id, full_name, email, mobile, address, gender, dob, role, is_verified, is_email_verified, has_completed_onboarding, security_code, last_login_at, inactivity_trigger_period, reminder_interval, nominee_limit, created_at FROM users WHERE user_id = ?', [userId]);
        if (rows.length === 0) return res.status(404).json({ message: 'User not found' });

        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
        res.json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching profile' });
    }
};

const updateUserProfile = async (req, res) => {
    const { full_name, email, mobile, address, gender, dob } = req.body;
    try {
        const userId = req.user.id;

        const updates = [];
        const values = [];

        if (full_name !== undefined) { updates.push('full_name = ?'); values.push(full_name); }
        if (email !== undefined) {
            updates.push('email = ?');
            updates.push('is_email_verified = 0');
            values.push(email);
        }
        if (mobile !== undefined) { updates.push('mobile = ?'); values.push(mobile); }
        if (address !== undefined) { updates.push('address = ?'); values.push(address || null); }
        if (gender !== undefined) { updates.push('gender = ?'); values.push(gender || null); }
        if (dob !== undefined) { updates.push('dob = ?'); values.push(dob || null); }

        if (updates.length > 0) {
            values.push(userId);
            await db.execute(
                `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE user_id = ?`,
                values
            );
        }

        // Check completion status
        const [nominees] = await db.execute('SELECT COUNT(*) as count FROM nominees WHERE user_id = ?', [userId]);
        const [assets] = await db.execute('SELECT COUNT(*) as count FROM assets WHERE user_id = ?', [userId]);
        const [security] = await db.execute('SELECT COUNT(*) as count FROM user_security_answers WHERE user_id = ?', [userId]);
        const [currentUser] = await db.execute('SELECT full_name, email, mobile, address, gender, dob FROM users WHERE user_id = ?', [userId]);

        const u = currentUser[0];
        const personalFields = (u.full_name && u.mobile && u.address && u.gender && u.dob);

        if (personalFields && nominees[0].count > 0 && security[0].count > 0) {
            await db.execute('UPDATE users SET has_completed_onboarding = 1 WHERE user_id = ?', [userId]);
        }

        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error updating profile' });
    }
};

const getProfileCompletion = async (req, res) => {
    let userId = req.user.id;
    const vaultContext = req.header('x-vault-context');

    try {
        if (vaultContext && vaultContext !== 'null') {
            const [access] = await db.execute(`
                SELECT u.user_id FROM users u JOIN nominees n ON u.user_id = n.user_id 
                WHERE u.user_id = ? AND n.linked_user_id = ?
            `, [vaultContext, req.user.id]);
            if (access.length > 0) userId = vaultContext;
        }

        const [nominees] = await db.execute('SELECT COUNT(*) as count FROM nominees WHERE user_id = ?', [userId]);
        const [assets] = await db.execute('SELECT COUNT(*) as count FROM assets WHERE user_id = ?', [userId]);
        const [security] = await db.execute('SELECT COUNT(*) as count FROM user_security_answers WHERE user_id = ?', [userId]);

        const [userRows] = await db.execute('SELECT full_name, email, is_email_verified, mobile, address, gender, dob FROM users WHERE user_id = ?', [userId]);
        const user = userRows[0];

        const fields = {
            full_name: !!user.full_name,
            email: !!user.email && !!user.is_email_verified,
            mobile: !!user.mobile,
            address: !!user.address,
            gender: !!user.gender,
            dob: !!user.dob,
            has_nominee: nominees[0].count > 0,
            has_security: security[0].count > 0
        };

        const missing = Object.keys(fields).filter(k => !fields[k]);

        let score = 0;
        const personalFieldsList = ['full_name', 'email', 'mobile', 'address', 'gender', 'dob'];
        personalFieldsList.forEach(f => { if (fields[f]) score += 11.66; });
        if (fields.has_security) score += 30;

        const finalScore = Math.min(100, Math.round(score));

        res.json({
            percentage: finalScore,
            is_complete: finalScore === 100,
            fields,
            missing
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching completion status' });
    }
};

const updateVaultPolicy = async (req, res) => {
    const { inactivity_trigger_period, reminder_interval } = req.body;
    const userId = req.user.id;

    if (!inactivity_trigger_period || !reminder_interval) {
        return res.status(400).json({ message: 'Missing policy fields' });
    }

    try {
        await db.execute(
            'UPDATE users SET inactivity_trigger_period = ?, reminder_interval = ?, updated_at = NOW() WHERE user_id = ?',
            [inactivity_trigger_period, reminder_interval, userId]
        );
        res.json({ message: 'Vault policy updated successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error updating vault policy' });
    }
};

// ═══════════════════════════════════════════════════════
// AUDIT & NOMINEE LINKING
// ═══════════════════════════════════════════════════════

const getAuditLogs = async (req, res) => {
    const userId = req.user.id;
    try {
        const [rows] = await db.execute('SELECT log_id, action, ip_address, device_info, created_at FROM audit_logs WHERE user_id = ? ORDER BY created_at DESC LIMIT 50', [userId]);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching audit logs' });
    }
};

/**
 * Lists vaults where the current user's email/mobile is listed as a nominee
 * but hasn't been linked to their profile yet.
 */
const getNomineeOpportunities = async (req, res) => {
    let { id, email, mobile } = req.user;

    try {
        if (!email || !mobile) {
            const [rows] = await db.execute('SELECT email, mobile FROM users WHERE user_id = ?', [id]);
            if (rows.length > 0) {
                email = rows[0].email;
                mobile = rows[0].mobile;
            }
        }

        const [rows] = await db.execute(`
            SELECT u_owner.full_name as owner_name, u_owner.email as owner_email, n.nominee_id, n.relationship
            FROM nominees n
            JOIN users u_owner ON n.user_id = u_owner.user_id
            WHERE (n.email = ? OR n.mobile = ?)
            AND n.linked_user_id IS NULL
        `, [email, mobile]);
        
        res.json(rows);
    } catch (error) {
        console.error('❌ [AUTH] Nominee Opportunity Error:', error);
        res.status(500).json({ message: 'Error fetching nominee opportunities' });
    }
};

const linkNomineeAccount = async (req, res) => {
    const { nomineeId, securityCode } = req.body;
    const currentUserId = req.user.id;

    try {
        const [nomineeRows] = await db.execute('SELECT user_id, email, mobile FROM nominees WHERE nominee_id = ?', [nomineeId]);
        if (nomineeRows.length === 0) return res.status(404).json({ message: 'Nominee record not found' });

        const ownerId = nomineeRows[0].user_id;

        const [currentUser] = await db.execute('SELECT email, mobile FROM users WHERE user_id = ?', [currentUserId]);
        if (currentUser.length === 0) return res.status(404).json({ message: 'User not found' });

        const isMatchNominee = (currentUser[0].email === nomineeRows[0].email || currentUser[0].mobile === nomineeRows[0].mobile);
        if (!isMatchNominee) {
            return res.status(403).json({ message: 'Unauthorized: You are not the nominee for this record' });
        }

        const [ownerRows] = await db.execute('SELECT security_code FROM users WHERE user_id = ?', [ownerId]);
        if (ownerRows.length === 0 || !ownerRows[0].security_code) {
            return res.status(404).json({ message: 'Vault owner not found or missing security code' });
        }

        const sanitize = (code) => code?.replace(/[-\s]/g, '').toUpperCase();
        if (sanitize(securityCode) !== sanitize(ownerRows[0].security_code)) {
            return res.status(400).json({ message: 'Invalid security code' });
        }

        await db.execute('UPDATE nominees SET linked_user_id = ? WHERE nominee_id = ?', [currentUserId, nomineeId]);
        res.json({ success: true, message: 'Vault linked successfully' });
    } catch (error) {
        console.error('❌ [AUTH] Link Error:', error);
        res.status(500).json({ message: 'Error linking vault' });
    }
};

// ═══════════════════════════════════════════════════════
// DELETE ACCOUNT
// ═══════════════════════════════════════════════════════

const deleteAccount = async (req, res) => {
    const userId = req.user.id;
    let connection;

    try {
        connection = await db.getConnection();
        await connection.beginTransaction();

        console.log(`🗑️ [AUTH] Deleting account for User ID: ${userId}`);

        // 1. Delete user-owned records from dependent tables
        await connection.execute('DELETE FROM audit_logs WHERE user_id = ?', [userId]);
        await connection.execute('DELETE FROM otp_codes WHERE user_id = ?', [userId]);
        await connection.execute('DELETE FROM user_security_answers WHERE user_id = ?', [userId]);
        await connection.execute('DELETE FROM assets WHERE user_id = ?', [userId]);
        
        // 2. Handle Nominees and Succession Requests
        // Find nominees created by this user to delete their succession requests
        const [userNominees] = await connection.execute('SELECT nominee_id FROM nominees WHERE user_id = ?', [userId]);
        if (userNominees.length > 0) {
            const nomineeIds = userNominees.map(n => n.nominee_id).join(',');
            await connection.execute(`DELETE FROM succession_requests WHERE nominee_id IN (${nomineeIds})`);
        }
        
        // Also delete succession requests where this user is the vault owner
        await connection.execute('DELETE FROM succession_requests WHERE user_id = ?', [userId]);
        
        // Delete nominees created by this user
        await connection.execute('DELETE FROM nominees WHERE user_id = ?', [userId]);

        // 3. Unlink this user from other people's nominee records
        await connection.execute('UPDATE nominees SET linked_user_id = NULL WHERE linked_user_id = ?', [userId]);

        // 4. Finally, delete the user record
        await connection.execute('DELETE FROM users WHERE user_id = ?', [userId]);

        await connection.commit();
        
        console.log(`✅ [AUTH] Account ${userId} destroyed successfully.`);
        res.json({ success: true, message: 'Account and all associated data have been permanently deleted.' });
    } catch (error) {
        if (connection) await connection.rollback();
        console.error('❌ [AUTH] Delete Account Error:', error);
        res.status(500).json({ message: 'Failed to delete account protocol.', diagnostic: error.message });
    } finally {
        if (connection) connection.release();
    }
};

// ═══════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════

module.exports = {
    login,
    register,
    getSecurityQuestions,
    verifyOTP,
    getRecoveryQuestions,
    verifyRecoveryAnswers,
    resetPassword,
    forgotPassword,
    verifyForgotOTP,
    resetPasswordAfterForgot,
    completeOnboarding,
    getOnboardingStatus,
    saveNominee,
    getNominee,
    sendNomineeEmailOTP,
    verifyNomineeEmailOTP,
    sendNomineePhoneOTP,
    verifyNomineePhoneOTP,
    getAuditLogs,
    getNomineeOpportunities,
    linkNomineeAccount,
    getUserProfile,
    updateUserProfile,
    getProfileCompletion,
    recoverLookup,
    recoverSendOTP,
    recoverVerify,
    recoverUpdateAccount,
    updateVaultPolicy,
    sendUserEmailOTP,
    verifyUserEmailOTP,
    deleteAccount
};
