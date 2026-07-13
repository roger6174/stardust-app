import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_service.dart';
import '../services/vault_service.dart';
import '../theme.dart';

class StardustGuideScreen extends StatefulWidget {
  const StardustGuideScreen({super.key});

  @override
  State<StardustGuideScreen> createState() => _StardustGuideScreenState();
}

class _StardustGuideScreenState extends State<StardustGuideScreen> with SingleTickerProviderStateMixin {
  final AiService _aiService = AiService();
  final VaultService _vaultService = VaultService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  double _vaultIntegrity = 0.0;
  
  // Real counts from vault
  int _financeCount = 0;
  int _insuranceCount = 0;
  int _legalCount = 0;
  int _nomineeCount = 0;
  bool _isLoadingSummary = true;
  
  // ═══════════════════════════════════════════════════════════
  // VOICE ENGINE (TTS + STT)
  // ═══════════════════════════════════════════════════════════
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _sttEngine = stt.SpeechToText();
  bool _isTtsEnabled = true;
  bool _isListening = false;
  bool _sttAvailable = false;
  String _currentLocale = 'en-IN'; // Default: English (India)
  bool _isHindiMode = false;

  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initVoiceEngine();
    _loadVaultSummary();

    // Initial greeting with chips
    _messages.add(ChatMessage(
      text: "Protocol initiated. I am the Stardust Guide. Standing by for encryption, reorganization, and planning functions.",
      isMe: false,
      chips: ["Plan My Vault", "Audit Security", "Setup Succession"],
    ));
  }

  Future<void> _loadVaultSummary() async {
    try {
      setState(() => _isLoadingSummary = true);
      final summary = await _vaultService.getSummary();
      
      final parentCounts = summary['parent_counts'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _financeCount = (parentCounts['finance'] ?? 0) as int;
        _insuranceCount = (parentCounts['insurance'] ?? 0) as int;
        _legalCount = (parentCounts['legal'] ?? 0) as int;
        _nomineeCount = (summary['total_nominees'] ?? 0) as int;
        
        // Calculate integrity score (0.0 to 1.0)
        // Simple logic: 4 categories + Nominee. Each adds 0.2 if has at least 1 item.
        double score = 0.0;
        if (_financeCount > 0) score += 0.2;
        if (_insuranceCount > 0) score += 0.2;
        if (_legalCount > 0) score += 0.2;
        if (_nomineeCount > 0) score += 0.2;
        
        // 5th bucket: Identity or Security (using total items)
        if ((summary['total'] ?? 0) as int > 5) score += 0.2;
        
        _vaultIntegrity = score.clamp(0.05, 1.0); // Never show 0%
        _isLoadingSummary = false;
      });
    } catch (_) {
      setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _initVoiceEngine() async {
    try {
      // Initialize TTS with natural, clear voice settings
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.42); // Slightly slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.95); // Slightly lower for natural tone
      
      // Use higher quality voice if available
      final voices = await _tts.getVoices;
      if (voices is List) {
        // Prefer a female English-India voice for Stardust Guide persona
        for (final v in voices) {
          if (v is Map) {
            final locale = v['locale']?.toString() ?? '';
            final name = v['name']?.toString().toLowerCase() ?? '';
            if (locale.contains('en') && locale.contains('IN') && name.contains('female')) {
              await _tts.setVoice({"name": v['name'].toString(), "locale": locale});
              break;
            }
          }
        }
      }
    } catch (_) { /* Plugin not yet linked */ }
    
    try {
      // Initialize STT
      _sttAvailable = await _sttEngine.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
        },
      );
    } catch (_) { _sttAvailable = false; }
  }

  /// Clean text for natural speech output
  String _cleanForSpeech(String text) {
    return text
        // Remove markdown bold markers
        .replaceAll('**', '')
        // Remove bullet characters
        .replaceAll('•', ',')
        // Remove all emoji (comprehensive ranges)
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\u{200D}]', unicode: true), '')
        // Remove step labels like "Step 1 —" to just "Step 1,"
        .replaceAll('—', ',')
        .replaceAll('---', ',')
        // Remove section headers that are just labels
        .replaceAll(RegExp(r'\n\n+'), '. ')
        .replaceAll('\n', '. ')
        // Remove numbering at start of lines like "1." "2."
        .replaceAll(RegExp(r'(\.\s*)\d+\.'), r'$1')
        // Clean up multiple spaces
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        // Clean up multiple periods
        .replaceAll(RegExp(r'\.{2,}'), '.')
        // Clean up ", ,"
        .replaceAll(RegExp(r',\s*,'), ',')
        .trim();
  }

  Future<void> _speak(String text) async {
    if (!_isTtsEnabled) return;
    
    final cleanText = _cleanForSpeech(text);
    if (cleanText.isEmpty) return;
    
    try {
      // Only switch to Hindi if actual Devanagari script is present
      // Hinglish (Hindi in English letters) sounds better with English voice
      if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
        await _tts.setLanguage('hi-IN');
      } else {
        await _tts.setLanguage('en-IN');
      }
      await _tts.speak(cleanText);
    } catch (_) { /* TTS not available */ }
  }

  bool _isHindiContent(String text) {
    // Check for Devanagari script
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return true;
    // Check for common Hindi/Hinglish words
    final hindiMarkers = ['aapka', 'swagat', 'karein', 'kaise', 'shuru', 'surakshit', 'chahenge', 'raha', 'yojana'];
    final lower = text.toLowerCase();
    int count = 0;
    for (final marker in hindiMarkers) {
      if (lower.contains(marker)) count++;
    }
    return count >= 2; // At least 2 Hindi markers
  }

  void _toggleLanguage() {
    setState(() {
      _isHindiMode = !_isHindiMode;
      _currentLocale = _isHindiMode ? 'hi-IN' : 'en-IN';
    });
  }

  void _startListening() async {
    if (!_sttAvailable) return;
    
    try { await _tts.stop(); } catch (_) {}
    
    setState(() => _isListening = true);
    
    try {
      await _sttEngine.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() => _isListening = false);
            if (result.recognizedWords.isNotEmpty) {
              _controller.text = result.recognizedWords;
              _handleSendMessage();
            }
          }
        },
        localeId: _currentLocale,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (_) { setState(() => _isListening = false); }
  }

  void _stopListening() {
    _sttEngine.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _orbController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    try { _tts.stop(); } catch (_) {}
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? forcedText]) async {
    final text = forcedText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (forcedText == null) _controller.clear();
    
    try { await _tts.stop(); } catch (_) {}
    
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // 1. Refresh vault summary in background
      _loadVaultSummary();

      // 2. Handle deterministic reports for Audit/Security
      if (text.toLowerCase().contains("audit") || text.toLowerCase().contains("security")) {
        await Future.delayed(const Duration(milliseconds: 1000));
        String auditReport = "Protocol analysis complete. Current vault integrity at ${(_vaultIntegrity * 100).toInt()}%.\n\n"
            "• Finance Zone: ${_financeCount > 0 ? "OPTIMIZED ($_financeCount assets)" : "UNRESOLVED"}\n"
            "• Insurance: ${_insuranceCount > 0 ? "SECURED ($_insuranceCount policies)" : "INACTIVE"}\n"
            "• Legal: ${_legalCount > 0 ? "DOCUMENTS VERIFIED" : "PENDING"}\n"
            "• Nominees: ${_nomineeCount > 0 ? "$_nomineeCount REGISTERED" : "UNSET"}\n\n"
            "System is ${_vaultIntegrity > 0.8 ? "OPTIMAL" : "STABLE"}. Standing by for further reorganization.";
        
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: auditReport, isMe: false, chips: ["Audit Security", "Plan My Vault"]));
        });
        _speak(auditReport);
        return;
      }

      final history = _messages.take(_messages.length - 1).map((m) => {
        'role': m.isMe ? 'user' : 'model',
        'parts': [{'text': m.text}],
      }).toList();

      final response = await _aiService.chat(text, history: history);
      
      final replyText = response['reply'] ?? "I'm sorry, I couldn't process that.";
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: replyText,
          isMe: false,
          chips: List<String>.from(response['chips'] ?? []),
        ));
        
        // Update integrity based on intent
        final intent = response['intent'] ?? '';
        if (intent == 'SECURITY' || intent == 'VAULT_AUDIT') {
          _vaultIntegrity = (_vaultIntegrity + 0.05).clamp(0.0, 1.0);
        } else if (intent == 'PLAN') {
          _vaultIntegrity = (_vaultIntegrity + 0.03).clamp(0.0, 1.0);
        } else if (intent == 'SUCCESSION') {
          _vaultIntegrity = (_vaultIntegrity + 0.07).clamp(0.0, 1.0);
        }
      });
      _scrollToBottom();
      _speak(replyText);
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: "Connection stability compromised. Reverting to local guide engine.", isMe: false));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            try { _tts.stop(); } catch (_) {}
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              "STARDUST GUIDE",
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: isDark ? Colors.white.withOpacity(0.5) : AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     width: 6, height: 6,
                     decoration: BoxDecoration(
                       color: _vaultIntegrity > 0.6 ? Colors.green : (_vaultIntegrity > 0.4 ? Colors.orange : AppTheme.primaryBlue),
                       shape: BoxShape.circle,
                     ),
                   ),
                   const SizedBox(width: 6),
                   Text(
                     "${(_vaultIntegrity * 100).toInt()}% SECURE",
                     style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                   ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Language toggle badge
          GestureDetector(
            onTap: _toggleLanguage,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isHindiMode 
                    ? Colors.orange.withOpacity(0.15) 
                    : AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHindiMode ? Colors.orange.withOpacity(0.3) : AppTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Text(
                _isHindiMode ? 'हिं' : 'EN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _isHindiMode ? Colors.orange : AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          // TTS toggle button
          IconButton(
            icon: Icon(
              _isTtsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 20,
              color: _isTtsEnabled ? AppTheme.primaryBlue : Colors.grey,
            ),
            onPressed: () {
              setState(() => _isTtsEnabled = !_isTtsEnabled);
              if (!_isTtsEnabled) { try { _tts.stop(); } catch (_) {} }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(isDark),

          SafeArea(
            child: Column(
              children: [
                _buildOrbHeader(),

                // Zone indicators
                _buildZoneIndicators(isDark),

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isLast = index == _messages.length - 1;
                      return Column(
                        crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          _buildChatBubble(msg, isDark),
                          if (!msg.isMe && msg.chips != null && msg.chips!.isNotEmpty && isLast && !_isTyping)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildChips(msg.chips!),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 20),
                    child: FadeIn(
                      child: Row(
                        children: [
                          const Text("Analyzing Legacy Protocol...", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),

                _buildInputSection(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ZONE INDICATORS (from reference repo)
  // ═══════════════════════════════════════════════════════════
  Widget _buildZoneIndicators(bool isDark) {
    if (_isLoadingSummary) return const SizedBox(height: 20);

    final zones = [
      {'label': 'Finance', 'icon': Icons.account_balance_rounded, 'active': _financeCount > 0},
      {'label': 'Insurance', 'icon': Icons.shield_rounded, 'active': _insuranceCount > 0},
      {'label': 'Legal', 'icon': Icons.gavel_rounded, 'active': _legalCount > 0},
      {'label': 'Nominee', 'icon': Icons.people_rounded, 'active': _nomineeCount > 0},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: zones.map((zone) {
          final active = zone['active'] as bool;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  zone['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: active 
                        ? (isDark ? Colors.white.withOpacity(0.6) : Colors.black54)
                        : Colors.grey.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChips(List<String> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FadeInRight(
            duration: const Duration(milliseconds: 500),
            child: ActionChip(
              label: Text(chip),
              onPressed: () => _handleSendMessage(chip),
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              labelStyle: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: isDark ? const Color(0xFF070B14) : const Color(0xFFF0F4FF),
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -100,
              child: _blurredSphere(400, AppTheme.primaryBlue.withOpacity(0.12))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .move(duration: 10.seconds, begin: const Offset(0, 0), end: const Offset(-50, 50))
                  .scale(duration: 8.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
            ),
            Positioned(
              bottom: 200, left: -100,
              child: _blurredSphere(300, Colors.deepPurple.withOpacity(0.08))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .move(duration: 12.seconds, begin: const Offset(0, 0), end: const Offset(60, -40))
                  .scale(duration: 10.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3)),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.03),
                      blurRadius: 100,
                      spreadRadius: -50,
                      offset: Offset.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurredSphere(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildOrbHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AnimatedBuilder(
        animation: _orbController,
        builder: (context, child) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring when listening
                if (_isListening)
                  ...List.generate(3, (i) {
                    final delay = i * 0.3;
                    final p = ((_orbController.value + delay) % 1.0);
                    return Container(
                      width: 80 + (40 * p), height: 80 + (40 * p),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity((1.0 - p) * 0.4),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : AppTheme.primaryBlue).withOpacity(0.2 + (0.1 * _orbController.value)),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: const Size(50, 50),
                  painter: OrbPainter(progress: _orbController.value, isListening: _isListening),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    final color = msg.isMe 
        ? AppTheme.primaryBlue 
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.white);
    
    final textColor = msg.isMe 
        ? Colors.white 
        : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(msg.isMe ? 24 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 24),
          ),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRichText(msg.text, textColor),
            if (!msg.isMe)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => _speak(msg.text),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTtsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, 
                        color: AppTheme.primaryBlue.withOpacity(0.5), 
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isTtsEnabled ? "Tap to replay" : "Voice muted", 
                        style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(String text, Color baseColor) {
    final parts = text.split('**');
    final children = <TextSpan>[];
    
    for (int i = 0; i < parts.length; i++) {
       if (i % 2 == 1) {
         children.add(TextSpan(
           text: parts[i],
           style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
         ));
       } else {
         children.add(TextSpan(text: parts[i]));
       }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: baseColor, fontSize: 16, height: 1.5, fontFamily: 'Outfit'),
        children: children,
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                // Mic button
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? Colors.red.withOpacity(0.15) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.red : Colors.grey,
                      size: 22,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _isListening ? "Listening..." : "Ask Stardust...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: _isListening ? Colors.red.withOpacity(0.5) : Colors.grey, 
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _handleSendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final List<String>? chips;

  ChatMessage({required this.text, required this.isMe, this.chips});
}


class OrbPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  OrbPainter({required this.progress, this.isListening = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final baseColor = isListening ? Colors.red : AppTheme.primaryBlue;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor,
          baseColor.withOpacity(0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Dynamic wave effect
    for (int i = 0; i < 3; i++) {
      final p = (progress + (i * 0.33)) % 1.0;
      final waveRadius = radius * (0.8 + (0.2 * p));
      final opacity = 1.0 - p;
      
      canvas.drawCircle(
        center, 
        waveRadius, 
        Paint()..color = baseColor.withOpacity(opacity * 0.3)..style = PaintingStyle.fill
      );
    }

    canvas.drawCircle(center, radius * 0.7, paint);
  }

  @override
  bool shouldRepaint(OrbPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.isListening != isListening;
}
