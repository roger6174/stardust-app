import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/stardust_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';

class OnboardingAgreementsScreen extends StatefulWidget {
  const OnboardingAgreementsScreen({super.key});

  @override
  State<OnboardingAgreementsScreen> createState() => _OnboardingAgreementsScreenState();
}

class _OnboardingAgreementsScreenState extends State<OnboardingAgreementsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAgreed = false;

  void _onNext() {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      if (_isAgreed) {
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: {'isGuest': false, 'isLogin': true});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the agreements to continue'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Page Indicator Dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primaryBlue : AppTheme.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildSecurityIntro(theme, isDark),
                    _buildAgreementsContent(theme, isDark),
                  ],
                ),
              ),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: GradientButton(
                    text: _currentPage == 0 ? 'Review Security & Continue' : 'Agree & Launch Vault',
                    icon: _currentPage == 0 ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded,
                    onPressed: _onNext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityIntro(ThemeData theme, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, size: 48, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 28),
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Your Digital Fortress.',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: screenWidth < 380 ? 32 : 38,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Stardust Vault uses extreme encryption measures to ensure your legacy remains private and 100% under your control.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 48),
          _securityFeature(theme, isDark, Icons.enhanced_encryption_rounded, 'Military-Grade Encryption', 'All data is encrypted on your device using AES-256 before syncing.', 300),
          _securityFeature(theme, isDark, Icons.privacy_tip_rounded, 'Zero-Knowledge Privacy', 'Stardust never holds your keys; we cannot access your vault.', 450),
          _securityFeature(theme, isDark, Icons.gavel_rounded, 'Global Protection', 'Meets the highest global standards for digital asset security.', 600),
        ],
      ),
    );
  }

  Widget _securityFeature(ThemeData theme, bool isDark, IconData icon, String title, String desc, int delay) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(desc, style: theme.textTheme.bodySmall?.copyWith(height: 1.5, color: isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementsContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 24, color: AppTheme.primaryBlue),
              const SizedBox(width: 14),
              Text('Final Agreements', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legalBlock(theme, 'Stardust Agreement', 'By using the Vault, you act as your own bank. Stardust provides the secure infrastructure, but you are responsible for maintaining your decryption keys. If lost, they cannot be recovered.'),
                    const SizedBox(height: 20),
                    _legalBlock(theme, 'Privacy Commitment', 'Your vault data (passwords, assets, documents) is encrypted locally. We collect zero-knowledge of your content and never share your data with third parties.'),
                    const SizedBox(height: 20),
                    _legalBlock(theme, 'Terms of Usage', 'You represent that you are of legal age. You agree not to use the service for unlawful activities or to compromise the integrity of the platform.'),
                    const SizedBox(height: 20),
                    _legalBlock(theme, 'Compliance', 'Our service complies with international data privacy regulations. By continuing, you consent to our secure data processing standards.'),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Single Acceptance Tick
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: InkWell(
            onTap: () => setState(() => _isAgreed = !_isAgreed),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _isAgreed ? AppTheme.primaryBlue.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isAgreed ? AppTheme.primaryBlue : (isDark ? Colors.white10 : Colors.black12), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: _isAgreed ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isAgreed ? AppTheme.primaryBlue : (isDark ? Colors.white30 : Colors.black26), width: 2),
                    ),
                    child: _isAgreed ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'I understand and accept all terms',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legalBlock(ThemeData theme, String title, String content) {
    bool isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
        const SizedBox(height: 6),
        Text(content, style: theme.textTheme.bodySmall?.copyWith(height: 1.6, color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
      ],
    );
  }
}
