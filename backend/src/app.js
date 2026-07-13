const express = require('express');
const cors = require('cors');

console.log('🚀 UNLOCKING STARDUST VAULT...');
console.log('📂 FILE PATH: ' + __filename);
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Global Error Protection - Prevent Silent Crashes
process.on('unhandledRejection', (reason, promise) => {
    console.error('🔴 UNHANDLED REJECTION:', reason);
});
process.on('uncaughtException', (err) => {
    console.error('🔴 UNCAUGHT EXCEPTION:', err.message);
});

const InactivityService = require('./services/inactivityService');

// ═══════════════════════════════════════════════════════
// LEGACY PROTECTION PROTOCOL — AUTO-PULSE (6 Hours)
// ═══════════════════════════════════════════════════════
setInterval(async () => {
    console.log('🕒 [PROTOCOL] Running automated inactivity checks...');
    try {
        await InactivityService.performInactivityChecks();
    } catch (err) {
        console.error('🔴 [PROTOCOL] Inactivity check failed:', err.message);
    }
}, 6 * 60 * 60 * 1000); // 6 Hours

// Force Stay-Alive Heartbeat (1 Hour)
setInterval(() => { /* Heartbeat */ }, 3600000);

const app = express();
const PORT = process.env.PORT || 5099;

// Global Request Radar
app.use((req, res, next) => {
    console.log(`📡 [RADAR] Incoming: ${req.method} ${req.url}`);
    next();
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Request logger
app.use((req, res, next) => {
    console.log(`[REQ] ${req.method} ${req.url}`);
    next();
});

// Rate limiting
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, 
    max: 100,
    message: 'Too many requests, please try again after 15 minutes'
});
app.use('/api/', globalLimiter);

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/vault', require('./routes/vaultRoutes')); // ✅ NEW unified vault API
app.use('/api/uploads', require('./routes/uploadRoutes'));
app.use('/api/security-logs', require('./routes/securityRoutes'));
app.use('/api/succession', require('./routes/successionRoutes'));
app.use('/api/ai', require('./routes/aiRoutes'));

// ⚠️ DEPRECATED — Old routes kept for backward compat (will be removed)
app.use('/api/assets', require('./routes/assetRoutes'));
app.use('/api/passwords', require('./routes/passwordRoutes'));
app.use('/api/insurance', require('./routes/insuranceRoutes'));
app.use('/api/contacts', require('./routes/contactRoutes'));
app.use('/api/legal', require('./routes/legalRoutes'));
app.use('/api/others', require('./routes/othersRoutes'));

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Default route
app.get('/', (req, res) => {
    res.json({ message: 'Stardust Vault App Backend API' });
});

// Port
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 App Backend running on all interfaces (Port ${PORT})`);
    
    // Safety check for AI Key
    const key = process.env.GEMINI_API_KEY;
    if (key) {
        const masked = key.substring(0, 6) + '...' + key.substring(key.length - 3);
        console.log(`✨ [AI] Engine detected with key: ${masked}`);
    } else {
        console.error('⚠️ [AI] WARNING: GEMINI_API_KEY is missing!');
    }
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Internal Server Error' });
});

module.exports = app;
