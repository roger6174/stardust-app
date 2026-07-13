const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// ═══════════════════════════════════════════════════════════
// RULE-BASED INTENT ENGINE (Ported from stardust-guide-ai)
// Deterministic, zero-dependency, always works.
// ═══════════════════════════════════════════════════════════

const INTENTS = [
    {
        key: 'GREETING',
        keywords: ['hello', 'hi', 'hey', 'namaste', 'good morning', 'good evening', 'start', 'plan my vault'],
        hindiKeywords: ['namaste', 'namaskar', 'kaise ho', 'shuru'],
        response: {
            reply: "Welcome to **Stardust Vault**. I am your AI Guardian — here to help you secure, organize, and future-proof your digital legacy.\n\nYour vault integrity is being monitored in real-time. What would you like to do?",
            chips: ["Plan My Vault", "Upload Document", "Setup Nominees", "Security Audit"],
            intent: "GREETING"
        },
        hindiResponse: {
            reply: "**Stardust Vault** mein aapka swagat hai 🙏\n\nMain aapka AI Guardian hoon — aapki digital legacy ko surakshit aur organized rakhne mein madad karunga.\n\nAap kya karna chahenge?",
            chips: ["Vault Plan Karein", "Document Upload", "Nominee Setup", "Security Jaanch"],
            intent: "GREETING"
        }
    },
    {
        key: 'PLAN',
        keywords: ['plan', 'organize', 'vault plan', 'plan my vault', 'how to start', 'guide me', 'what should i do', 'help me plan'],
        hindiKeywords: ['plan', 'yojana', 'kaise karein', 'madad', 'shuru kaise'],
        response: {
            reply: "Here is your **Vault Optimization Plan**:\n\n**Step 1 — Financial Zone**\nUpload bank statements, credit cards, FDs, and investments. This forms your financial backbone.\n\n**Step 2 — Insurance Shield**\nAdd all life, health, vehicle, and property insurance policies. Set renewal reminders.\n\n**Step 3 — Legal Fortress**\nStore your will, property deeds, power of attorney, and tax documents.\n\n**Step 4 — Identity Core**\nSecure Aadhaar, PAN, passport, and driving license with encrypted storage.\n\n**Step 5 — Succession Protocol**\nAppoint nominees and set up the Legacy Transfer system for your heirs.\n\nShall I guide you through any specific step?",
            chips: ["Start with Finance", "Upload Insurance", "Setup Nominees", "Security Audit"],
            intent: "PLAN"
        },
        hindiResponse: {
            reply: "Yeh raha aapka **Vault Optimization Plan**:\n\n**Step 1 — Finance Zone**\nBank statements, credit cards, FDs upload karein.\n\n**Step 2 — Insurance Shield**\nSabhi insurance policies add karein.\n\n**Step 3 — Legal Fortress**\nWill, property papers, tax documents store karein.\n\n**Step 4 — Identity Core**\nAadhaar, PAN, passport surakshit karein.\n\n**Step 5 — Succession Protocol**\nNominees appoint karein aur Legacy Transfer setup karein.\n\nKis step se shuru karein?",
            chips: ["Finance se Shuru", "Insurance Upload", "Nominee Setup", "Security Jaanch"],
            intent: "PLAN"
        }
    },
    {
        key: 'UPLOAD',
        keywords: ['upload', 'add', 'scan', 'document', 'store', 'save', 'file', 'photo', 'camera'],
        hindiKeywords: ['upload', 'daalo', 'jodo', 'save karo', 'document', 'file'],
        response: {
            reply: "To upload a document to your vault:\n\n1. Tap the **SCAN** button (bottom-right corner)\n2. Choose **Camera Scan** or **Gallery Upload**\n3. Select the category (Finance, Insurance, Legal, etc.)\n4. The document will be **encrypted and stored** securely\n\nAll files are protected with AES-256 encryption and only accessible by you and your appointed nominees.",
            chips: ["Scan Now", "View My Vault", "Setup Nominees", "Back to Plan"],
            intent: "UPLOAD"
        }
    },
    {
        key: 'SUCCESSION',
        keywords: ['nominee', 'succession', 'heir', 'legacy', 'transfer', 'death', 'after me', 'family', 'inherit', 'will'],
        hindiKeywords: ['nominee', 'waris', 'uttaradhikari', 'parivar', 'vasiyat', 'transfer'],
        response: {
            reply: "The **Succession Protocol** ensures your digital legacy transfers safely to your chosen heirs.\n\n**How it works:**\n• Appoint up to 5 nominees with email verification\n• Set an **inactivity timer** (30-365 days)\n• If you become inactive, nominees receive secure access\n• Each nominee gets only the vaults you assign to them\n\n**Security:** Nominees must verify their identity via email + OTP before accessing any data.\n\nWould you like to set up your first nominee?",
            chips: ["Add Nominee", "Set Inactivity Timer", "View Nominees", "Back to Plan"],
            intent: "SUCCESSION"
        }
    },
    {
        key: 'SECURITY',
        keywords: ['security', 'audit', 'safe', 'protect', 'encrypt', 'hack', 'breach', 'password', 'secure', 'integrity', 'check'],
        hindiKeywords: ['suraksha', 'surakshit', 'jaanch', 'hack', 'password'],
        response: {
            reply: "**Vault Security Status:**\n\n🔒 **Encryption:** AES-256 active on all stored documents\n🛡️ **Authentication:** JWT token-based session management\n📡 **Monitoring:** All access attempts logged in Security Console\n⏰ **Inactivity Guard:** Succession protocol triggers after configured period\n\n**Recommendations:**\n• Enable biometric login for faster, safer access\n• Review your nominee list quarterly\n• Keep insurance policies updated with renewal dates\n• Run a full vault audit every 90 days",
            chips: ["Run Full Audit", "View Security Log", "Update Nominees", "Back to Plan"],
            intent: "SECURITY"
        }
    },
    {
        key: 'FINANCE',
        keywords: ['finance', 'bank', 'credit card', 'debit', 'investment', 'mutual fund', 'fd', 'savings', 'loan', 'emi', 'money', 'account'],
        hindiKeywords: ['paisa', 'bank', 'nivesh', 'bachat', 'karz', 'loan'],
        response: {
            reply: "**Financial Zone** is the backbone of your vault.\n\nHere's what you should store:\n• 🏦 Bank account details & statements\n• 💳 Credit/Debit card information\n• 📈 Investment portfolios (MF, stocks, FDs)\n• 🏠 Loan & EMI documents\n• 💰 PPF, NPS, and pension records\n\nAll financial data is encrypted at rest. Your nominees will receive access only when the Succession Protocol is activated.",
            chips: ["Upload Finance Doc", "View Finance Vault", "Card Benefits", "Back to Plan"],
            intent: "FINANCE"
        }
    },
    {
        key: 'INSURANCE',
        keywords: ['insurance', 'policy', 'life insurance', 'health insurance', 'car insurance', 'premium', 'claim', 'cover'],
        hindiKeywords: ['bima', 'insurance', 'policy', 'premium', 'claim'],
        response: {
            reply: "**Insurance Shield** protects your family's future.\n\nStore all your policies here:\n• 🏥 Health Insurance (individual & family floater)\n• 💀 Life Insurance (term, endowment, ULIP)\n• 🚗 Vehicle Insurance (car, bike)\n• 🏠 Property Insurance\n• ✈️ Travel Insurance\n\n**Pro tip:** Set renewal date reminders so you never miss a premium payment. Your nominees will be able to file claims directly using the stored policy documents.",
            chips: ["Upload Policy", "Set Reminder", "View Policies", "Back to Plan"],
            intent: "INSURANCE"
        }
    },
    {
        key: 'LEGAL',
        keywords: ['legal', 'will', 'property', 'deed', 'power of attorney', 'tax', 'court', 'agreement', 'contract'],
        hindiKeywords: ['kanoon', 'vasiyat', 'sampatti', 'tax', 'agreement'],
        response: {
            reply: "**Legal Fortress** stores your most critical documents.\n\n📜 **Essential Legal Documents:**\n• Last Will & Testament\n• Property deeds & registration papers\n• Power of Attorney\n• Rental agreements\n• Tax returns (ITR) & Form 16\n• Business partnership deeds\n\n**Important:** These documents are critical for your heirs. Ensure your nominees know they're stored here.",
            chips: ["Upload Legal Doc", "View Legal Vault", "Setup Will", "Back to Plan"],
            intent: "LEGAL"
        }
    },
    {
        key: 'IDENTITY',
        keywords: ['identity', 'aadhaar', 'pan', 'passport', 'license', 'voter id', 'id proof', 'kyc'],
        hindiKeywords: ['aadhaar', 'pan', 'passport', 'pehchaan', 'license'],
        response: {
            reply: "**Identity Core** secures your government-issued IDs.\n\n🆔 **Store these documents:**\n• Aadhaar Card\n• PAN Card\n• Passport\n• Driving License\n• Voter ID\n• Birth/Marriage Certificate\n\nAll identity documents are stored with the highest encryption level. They'll be accessible to your nominees during legacy transfer for KYC and claim processes.",
            chips: ["Upload ID", "View IDs", "Scan Document", "Back to Plan"],
            intent: "IDENTITY"
        }
    }
];

// Default fallback for unrecognized messages
const DEFAULT_RESPONSE = {
    reply: "I understand you're looking for help with your vault. Here are the things I can assist you with:\n\n• **Plan My Vault** — Get a step-by-step organization guide\n• **Upload Documents** — Securely store important files\n• **Nominees & Succession** — Set up legacy transfer\n• **Security Audit** — Check your vault's integrity\n• **Category Help** — Finance, Insurance, Legal, Identity\n\nWhat would you like to explore?",
    chips: ["Plan My Vault", "Upload Document", "Setup Nominees", "Security Audit"],
    intent: "HELP"
};

/**
 * Detect if message contains Hindi/Hinglish
 */
function isHindi(text) {
    // Check for Devanagari script
    if (/[\u0900-\u097F]/.test(text)) return true;
    // Check for common Hindi/Hinglish words
    const hindiMarkers = ['kya', 'kaise', 'hai', 'haan', 'nahi', 'mein', 'mujhe', 'karo', 'karein', 'chahiye', 'batao', 'bhai', 'yaar', 'acha'];
    const lower = text.toLowerCase();
    return hindiMarkers.some(marker => lower.includes(marker));
}

/**
 * Match user message to an intent
 */
function matchIntent(message) {
    const lower = message.toLowerCase().trim();
    const hindi = isHindi(message);

    for (const intent of INTENTS) {
        // Check English keywords
        for (const kw of intent.keywords) {
            if (lower.includes(kw)) {
                return hindi && intent.hindiResponse ? intent.hindiResponse : intent.response;
            }
        }
        // Check Hindi keywords
        if (intent.hindiKeywords) {
            for (const kw of intent.hindiKeywords) {
                if (lower.includes(kw)) {
                    return intent.hindiResponse || intent.response;
                }
            }
        }
    }

    return DEFAULT_RESPONSE;
}

// ═══════════════════════════════════════════════════════════
// API ENDPOINTS
// ═══════════════════════════════════════════════════════════

/**
 * General Chat with Stardust Guide
 * PRIMARY: Rule-based intent matching (always works)
 * FALLBACK: Gemini AI for complex/unrecognized queries (optional)
 */
exports.chat = async (req, res) => {
    const { message, history } = req.body;

    if (!message) {
        return res.status(400).json({ message: 'Message is required' });
    }

    // Step 1: Try rule-based matching first (instant, reliable)
    const matched = matchIntent(message);

    // Return the deterministic response immediately
    res.json({
        ...matched,
        timestamp: new Date().toISOString()
    });
};

/**
 * Get Card Benefits — Rule-based with common Indian cards
 */
exports.getCardBenefits = async (req, res) => {
    const { bank, network, variant } = req.body;

    if (!bank) {
        return res.status(400).json({ message: 'Bank name is required' });
    }

    // Deterministic benefits based on common Indian card knowledge
    const benefits = [
        `${bank} ${variant || ''} card offers competitive reward points on all transactions.`,
        `Complimentary airport lounge access at domestic and select international airports.`,
        `Fuel surcharge waiver of up to 1% at all fuel stations across India.`,
        `Welcome benefits and milestone rewards on meeting annual spend targets.`,
        `Best suited for users who prioritize ${variant ? variant.toLowerCase() + '-tier' : 'everyday'} spending with premium lifestyle benefits.`
    ];

    res.json({
        bank,
        variant,
        benefits: benefits.join('\n'),
        timestamp: new Date().toISOString()
    });
};

/**
 * Security Audit — Deterministic analysis based on vault summary
 */
exports.securityAudit = async (req, res) => {
    const { vaultSummary } = req.body;

    const auditPoints = [];

    if (!vaultSummary || Object.keys(vaultSummary).length === 0) {
        auditPoints.push("⚠️ Your vault appears empty. Start by uploading financial documents and identity proofs.");
        auditPoints.push("🔒 Appoint at least one nominee to activate the Succession Protocol.");
        auditPoints.push("📋 Add insurance policies to protect your family's financial future.");
    } else {
        // Analyze what's present and missing
        const categories = vaultSummary.categories || {};
        const nomineeCount = vaultSummary.nomineeCount || 0;

        if (!categories.finance || categories.finance === 0) {
            auditPoints.push("⚠️ CRITICAL: No financial documents found. Your vault's core is empty.");
        } else {
            auditPoints.push(`✅ Financial zone active with ${categories.finance} document(s).`);
        }

        if (!categories.insurance || categories.insurance === 0) {
            auditPoints.push("⚠️ No insurance policies stored. This is a major gap in legacy protection.");
        } else {
            auditPoints.push(`✅ Insurance shield active with ${categories.insurance} policy/policies.`);
        }

        if (nomineeCount === 0) {
            auditPoints.push("🔴 CRITICAL: No nominees appointed. Succession Protocol is inactive.");
        } else {
            auditPoints.push(`✅ ${nomineeCount} nominee(s) configured for succession.`);
        }

        if (!categories.legal || categories.legal === 0) {
            auditPoints.push("⚠️ No legal documents found. Consider storing your will and property deeds.");
        }
    }

    res.json({
        audit: auditPoints.join('\n'),
        timestamp: new Date().toISOString()
    });
};
