import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/stardust_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../theme.dart';
import '../services/auth_service.dart';

// ─── Unified Auth Screen ───
class AuthScreen extends StatefulWidget {
  final int initialIndex;
  const AuthScreen({super.key, this.initialIndex = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  int _signUpStep = 1;
  bool _obscureLogin = true;
  bool _obscureSignup = true;
  bool _obscureConfirm = true;

  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpMobileController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmController = TextEditingController();
  int _selectedQuestionId = 1;
  final _securityAnswerController = TextEditingController();

  final List<Map<String, dynamic>> _securityQuestions = [
    {'id': 1, 'question': 'What was your first pet\'s name?'},
    {'id': 2, 'question': 'What is your mother\'s maiden name?'},
    {'id': 3, 'question': 'What city were you born in?'},
    {'id': 4, 'question': 'What was the make of your first car?'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpMobileController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _auth.login(
        _loginIdentifierController.text.trim(),
        _loginPasswordController.text,
      );
      if (mounted) {
        Navigator.pushNamed(context, '/otp-verification', arguments: {
          'isLogin': true,
          'userId': result['userId'],
          'destinationSnippet': result['destinationSnippet']
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (_signUpPasswordController.text != _signUpConfirmController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_securityAnswerController.text.isEmpty) {
      _showError('Please answer the security question');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _auth.register(
        fullName: _signUpNameController.text.trim(),
        email: _signUpEmailController.text.trim().isEmpty ? null : _signUpEmailController.text.trim(),
        mobile: _signUpMobileController.text.trim(),
        password: _signUpPasswordController.text,
        securityAnswers: [
          {'question_id': _selectedQuestionId, 'answer': _securityAnswerController.text.trim()}
        ],
      );
      
      if (kDebugMode) {
        print('🔑 [DEBUG] Signup Success. Result: $result');
      }

      if (mounted) {
        Navigator.pushNamed(context, '/otp-verification', arguments: {
          'isLogin': false,
          'userId': null,
          'email': _signUpEmailController.text.trim().isEmpty ? null : _signUpEmailController.text.trim(),
          'mobile': _signUpMobileController.text.trim(),
          'destinationSnippet': result['destinationSnippet']
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Account already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Sign In',
              textColor: Colors.white,
              onPressed: () => _tabController.animateTo(0),
            ),
          ),
        );
      } else {
        _showError(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // ─── Logo + Branding ───
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: _logo(),
                    ),
                    const SizedBox(height: 12),
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 150),
                      child: Text(
                        'Stardust Vault',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeIn(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'Secure your digital legacy',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF697386),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ─── Auth Card ───
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _tabBar(),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                                child: _isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 80),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF635BFF),
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : _tabController.index == 0 
                                        ? _signInTab() 
                                        : _signUpTab(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ─── Developer Bypass ───
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: () {
                          // Bypass directly to onboarding for under-development testing
                          Navigator.pushReplacementNamed(context, '/onboarding');
                        },
                        child: Text(
                          '[Dev] Bypass to Onboarding',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF635BFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.shield_rounded, size: 36, color: Colors.white),
    );
  }

  Widget _tabBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF1A1F36),
        unselectedLabelColor: const Color(0xFF8898AA),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Sign In'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF8898AA)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5F1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF635BFF), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8898AA), fontSize: 14),
    );
  }

  Widget _signInTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: _loginIdentifierController,
          decoration: _inputDecoration('Email or Mobile', Icons.person_outline_rounded),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPasswordController,
          decoration: _inputDecoration(
            'Password',
            Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _obscureLogin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF8898AA),
              ),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
          ),
          obscureText: _obscureLogin,
        ),
        const SizedBox(height: 28),
        GradientButton(
          text: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _linkButton('Lost Access?', () => Navigator.pushNamed(context, '/forgot-password')),
            Container(
              width: 1,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFFE2E5F1),
            ),
            _linkButton('Emergency Recovery', () => Navigator.pushNamed(context, '/recover-account')),
          ],
        ),
      ],
    );
  }

  Widget _linkButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF635BFF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _signUpTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        _stepRow(),
        const SizedBox(height: 24),
        if (_signUpStep == 1) ...[
          TextField(
            controller: _signUpNameController,
            decoration: _inputDecoration('Full Name', Icons.badge_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpEmailController,
            decoration: _inputDecoration('Email Address (Optional)', Icons.email_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpMobileController,
            decoration: _inputDecoration('Mobile Number', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => setState(() => _signUpStep = 2),
          ),
        ] else ...[
          TextField(
            controller: _signUpPasswordController,
            decoration: _inputDecoration(
              'Password',
              Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscureSignup ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF8898AA),
                ),
                onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
              ),
            ),
            obscureText: _obscureSignup,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpConfirmController,
            decoration: _inputDecoration(
              'Confirm Password',
              Icons.lock_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF8898AA),
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            obscureText: _obscureConfirm,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedQuestionId,
            items: _securityQuestions.map((q) {
              return DropdownMenuItem<int>(
                value: q['id'] as int,
                child: Text(q['question'] as String, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedQuestionId = val!),
            decoration: _inputDecoration('Security Question', Icons.help_outline_rounded),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _securityAnswerController,
            decoration: _inputDecoration('Security Answer', Icons.key_rounded),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _signUpStep = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFE2E5F1)),
                  ),
                  child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: 'Create',
                  onPressed: _handleSignUp,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stepRow() {
    return Row(
      children: [
        _stepPill(1, 'Identity'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _signUpStep >= 2
                    ? [const Color(0xFF635BFF), const Color(0xFF7C3AED)]
                    : [const Color(0xFFE2E5F1), const Color(0xFFE2E5F1)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        _stepPill(2, 'Security'),
      ],
    );
  }

  Widget _stepPill(int step, String label) {
    final bool active = _signUpStep >= step;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                  )
                : null,
            color: active ? null : const Color(0xFFF0F1FA),
            border: active ? null : Border.all(color: const Color(0xFFE2E5F1)),
          ),
          child: Center(
            child: active
                ? (step < _signUpStep
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : Text(step.toString(),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)))
                : Text(step.toString(),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8898AA), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: active ? const Color(0xFF1A1F36) : const Color(0xFF8898AA),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Forgot Password ───
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _backButton(context),
                    const SizedBox(height: 24),
                    FadeInDown(
                      child: Text('Forgot Password',
                          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: const Duration(milliseconds: 150),
                      child: Text('Enter your email to receive a reset link',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF697386))),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: GlassCard(
                        child: Column(children: [
                          TextField(decoration: const InputDecoration(labelText: 'Email')),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Reset Password',
                            icon: Icons.send_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password reset link sent!')),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recover Account ───
class RecoverAccountScreen extends StatelessWidget {
  const RecoverAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _backButton(context),
                    const SizedBox(height: 24),
                    FadeInDown(
                      child: Text('Recover Account',
                          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: const Duration(milliseconds: 150),
                      child: Text('Enter your email or recovery identifier',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF697386))),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: GlassCard(
                        child: Column(children: [
                          TextField(decoration: const InputDecoration(labelText: 'Email / Recovery ID')),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Recover',
                            icon: Icons.restore_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recovery instructions sent!')),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── OTP Verification ───
class OTPVerificationScreen extends StatefulWidget {
  final bool isLogin;
  final int? userId;
  final String? email;
  final String? mobile;
  final String? destinationSnippet;

  const OTPVerificationScreen({
    super.key,
    this.isLogin = true,
    this.userId,
    this.email,
    this.mobile,
    this.destinationSnippet,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showError('Please enter the full 6-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.verifyOtp(
        userId: widget.userId,
        otp: otp,
        email: widget.email,
        mobile: widget.mobile,
      );
      if (mounted) {
        if (!widget.isLogin) {
          // If signing up, go through the mandatory onboarding & agreements flow
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          // If logging in, skip onboarding and go directly to dashboard
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
            arguments: {'isGuest': false, 'isLogin': true},
          );
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _backButton(context),
                    const SizedBox(height: 24),
                    FadeInDown(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF635BFF).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.verified_user_rounded, size: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: Text('Verification',
                          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Enter the 6-digit code sent to ${widget.destinationSnippet ?? 'your device'}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF697386)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: GlassCard(
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF635BFF))),
                              )
                            : Column(children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return SizedBox(
                                      width: 44,
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1F36)),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: const Color(0xFFF8F9FE),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFE2E5F1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF635BFF), width: 2),
                                          ),
                                        ),
                                        onChanged: (v) => _onChanged(v, index),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 28),
                                GradientButton(text: 'Verify', icon: Icons.check_rounded, onPressed: _handleVerify),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Resend Code',
                                      style: TextStyle(color: Color(0xFF635BFF), fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───
Widget _backButton(BuildContext context) {
  return Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF697386), size: 20),
      onPressed: () => Navigator.pop(context),
    ),
  );
}
