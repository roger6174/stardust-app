import 'dart:convert';
import 'api_client.dart';

class AiService {
  final ApiClient _api = ApiClient();

  /// General chat with Stardust Guide
  /// Uses server first, falls back to local rule-based engine if server fails.
  Future<Map<String, dynamic>> chat(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final response = await _api.post('/ai/chat', {
        'message': message,
        'history': history ?? [],
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // If server returned an error field, fall back to local
        if (body['error'] != null) {
          return _localMatch(message);
        }
        return body;
      }
    } catch (_) {
      // Server unreachable or timed out — use local engine
    }
    return _localMatch(message);
  }

  /// Get specific benefits for a card
  Future<Map<String, dynamic>> getCardBenefits({
    required String bank,
    String? network,
    String? variant,
  }) async {
    try {
      final response = await _api.post('/ai/card-benefits', {
        'bank': bank,
        'network': network,
        'variant': variant,
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    return {
      'bank': bank,
      'variant': variant,
      'benefits': '$bank ${variant ?? ''} card offers competitive reward points.\n'
          'Complimentary airport lounge access.\n'
          'Fuel surcharge waiver up to 1%.\n'
          'Welcome benefits and milestone rewards.\n'
          'Best suited for ${variant != null ? variant.toLowerCase() : 'everyday'} spending.',
    };
  }

  /// Get AI security audit
  Future<Map<String, dynamic>> getSecurityAudit(Map<String, dynamic> vaultSummary) async {
    try {
      final response = await _api.post('/ai/security-audit', {
        'vaultSummary': vaultSummary,
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    return {
      'audit': '⚠️ Your vault needs attention. Upload financial documents to begin.\n'
          '🔒 Appoint at least one nominee to activate Succession Protocol.\n'
          '📋 Add insurance policies to complete your coverage.',
    };
  }

  // ═══════════════════════════════════════════════════════════
  // LOCAL RULE-BASED ENGINE (Zero-dependency fallback)
  // Ported from stardust-guide-ai reference repo
  // ═══════════════════════════════════════════════════════════

  static bool _isHindi(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return true;
    final hindiMarkers = ['kya', 'kaise', 'hai', 'haan', 'nahi', 'mein', 'mujhe', 'karo', 'karein', 'chahiye', 'batao', 'bhai', 'yaar'];
    final lower = text.toLowerCase();
    return hindiMarkers.any((m) => lower.contains(m));
  }

  static Map<String, dynamic> _localMatch(String message) {
    final lower = message.toLowerCase().trim();
    final hindi = _isHindi(message);

    // GREETING
    if (_matchesAny(lower, ['hello', 'hi', 'hey', 'namaste', 'good morning', 'good evening', 'start'])) {
      return hindi
          ? {'reply': '**Stardust Vault** mein aapka swagat hai 🙏\n\nMain aapka AI Guardian hoon — aapki digital legacy ko surakshit rakhne mein madad karunga.\n\nAap kya karna chahenge?', 'chips': ['Vault Plan Karein', 'Document Upload', 'Nominee Setup', 'Security Jaanch'], 'intent': 'GREETING'}
          : {'reply': 'Welcome to **Stardust Vault**. I am your AI Guardian — here to help you secure, organize, and future-proof your digital legacy.\n\nYour vault integrity is being monitored in real-time. What would you like to do?', 'chips': ['Plan My Vault', 'Upload Document', 'Setup Nominees', 'Security Audit'], 'intent': 'GREETING'};
    }

    // PLAN
    if (_matchesAny(lower, ['plan', 'organize', 'vault plan', 'plan my vault', 'how to start', 'guide me', 'help me plan'])) {
      return {
        'reply': 'Here is your **Vault Optimization Plan**:\n\n**Step 1 — Financial Zone**\nUpload bank statements, credit cards, FDs, and investments.\n\n**Step 2 — Insurance Shield**\nAdd all insurance policies. Set renewal reminders.\n\n**Step 3 — Legal Fortress**\nStore your will, property deeds, and tax documents.\n\n**Step 4 — Identity Core**\nSecure Aadhaar, PAN, passport with encrypted storage.\n\n**Step 5 — Succession Protocol**\nAppoint nominees and set up Legacy Transfer.\n\nShall I guide you through any step?',
        'chips': ['Start with Finance', 'Upload Insurance', 'Setup Nominees', 'Security Audit'],
        'intent': 'PLAN',
      };
    }

    // UPLOAD / SCAN
    if (_matchesAny(lower, ['upload', 'add', 'scan', 'document', 'store', 'save', 'file', 'photo'])) {
      return {
        'reply': 'To upload a document to your vault:\n\n1. Tap the **SCAN** button (bottom-right corner)\n2. Choose **Camera Scan** or **Gallery Upload**\n3. Select the category (Finance, Insurance, Legal, etc.)\n4. The document will be **encrypted and stored** securely\n\nAll files are protected with AES-256 encryption.',
        'chips': ['Scan Now', 'View My Vault', 'Setup Nominees', 'Back to Plan'],
        'intent': 'UPLOAD',
      };
    }

    // SUCCESSION / NOMINEE
    if (_matchesAny(lower, ['nominee', 'succession', 'heir', 'legacy', 'transfer', 'family', 'inherit', 'will'])) {
      return {
        'reply': 'The **Succession Protocol** ensures your digital legacy transfers safely.\n\n**How it works:**\n• Appoint up to 5 nominees with email verification\n• Set an **inactivity timer** (30-365 days)\n• If you become inactive, nominees receive secure access\n• Each nominee gets only the vaults you assign\n\n**Security:** Nominees verify via email + OTP.\n\nWould you like to set up your first nominee?',
        'chips': ['Add Nominee', 'Set Inactivity Timer', 'View Nominees', 'Back to Plan'],
        'intent': 'SUCCESSION',
      };
    }

    // SECURITY
    if (_matchesAny(lower, ['security', 'audit', 'safe', 'protect', 'encrypt', 'hack', 'secure', 'integrity', 'check'])) {
      return {
        'reply': '**Vault Security Status:**\n\n🔒 **Encryption:** AES-256 active on all documents\n🛡️ **Authentication:** JWT token-based sessions\n📡 **Monitoring:** All access attempts logged\n⏰ **Inactivity Guard:** Succession protocol ready\n\n**Recommendations:**\n• Enable biometric login\n• Review nominee list quarterly\n• Keep insurance policies updated\n• Run full audit every 90 days',
        'chips': ['Run Full Audit', 'View Security Log', 'Update Nominees', 'Back to Plan'],
        'intent': 'SECURITY',
      };
    }

    // FINANCE
    if (_matchesAny(lower, ['finance', 'bank', 'credit card', 'debit', 'investment', 'mutual fund', 'fd', 'savings', 'loan', 'money'])) {
      return {
        'reply': '**Financial Zone** is the backbone of your vault.\n\nStore these:\n• 🏦 Bank account details & statements\n• 💳 Credit/Debit card information\n• 📈 Investment portfolios (MF, stocks, FDs)\n• 🏠 Loan & EMI documents\n• 💰 PPF, NPS, and pension records\n\nAll financial data is encrypted at rest.',
        'chips': ['Upload Finance Doc', 'View Finance Vault', 'Card Benefits', 'Back to Plan'],
        'intent': 'FINANCE',
      };
    }

    // INSURANCE
    if (_matchesAny(lower, ['insurance', 'policy', 'premium', 'claim', 'cover', 'health insurance', 'life insurance'])) {
      return {
        'reply': '**Insurance Shield** protects your family\'s future.\n\nStore all policies:\n• 🏥 Health Insurance\n• 💀 Life Insurance (term, ULIP)\n• 🚗 Vehicle Insurance\n• 🏠 Property Insurance\n• ✈️ Travel Insurance\n\n**Pro tip:** Set renewal date reminders so you never miss a premium.',
        'chips': ['Upload Policy', 'Set Reminder', 'View Policies', 'Back to Plan'],
        'intent': 'INSURANCE',
      };
    }

    // LEGAL
    if (_matchesAny(lower, ['legal', 'will', 'property', 'deed', 'tax', 'court', 'agreement', 'contract'])) {
      return {
        'reply': '**Legal Fortress** stores your most critical documents.\n\n📜 **Essential Documents:**\n• Last Will & Testament\n• Property deeds & registration\n• Power of Attorney\n• Tax returns (ITR) & Form 16\n• Rental agreements\n\n**Important:** Ensure nominees know these are stored here.',
        'chips': ['Upload Legal Doc', 'View Legal Vault', 'Setup Will', 'Back to Plan'],
        'intent': 'LEGAL',
      };
    }

    // IDENTITY
    if (_matchesAny(lower, ['identity', 'aadhaar', 'pan', 'passport', 'license', 'voter', 'id proof', 'kyc'])) {
      return {
        'reply': '**Identity Core** secures your government IDs.\n\n🆔 **Store these:**\n• Aadhaar Card\n• PAN Card\n• Passport\n• Driving License\n• Voter ID\n• Birth/Marriage Certificate\n\nAll identity documents are stored with highest encryption.',
        'chips': ['Upload ID', 'View IDs', 'Scan Document', 'Back to Plan'],
        'intent': 'IDENTITY',
      };
    }

    // DEFAULT FALLBACK
    return {
      'reply': 'I can help you with:\n\n• **Plan My Vault** — Step-by-step organization guide\n• **Upload Documents** — Securely store important files\n• **Nominees & Succession** — Set up legacy transfer\n• **Security Audit** — Check vault integrity\n• **Category Help** — Finance, Insurance, Legal, Identity\n\nWhat would you like to explore?',
      'chips': ['Plan My Vault', 'Upload Document', 'Setup Nominees', 'Security Audit'],
      'intent': 'HELP',
    };
  }

  static bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((kw) => input.contains(kw));
  }
}
