import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';
import 'gradient_button.dart';

class IntroModal extends StatefulWidget {
  final VoidCallback onFinish;
  const IntroModal({super.key, required this.onFinish});

  @override
  State<IntroModal> createState() => _IntroModalState();
}

class _IntroModalState extends State<IntroModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Secure Your Legacy',
      'desc': 'Zero-knowledge encryption protects your most sensitive data and digital assets.',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF635BFF),
    },
    {
      'title': 'Asset Management',
      'desc': 'Track real estate, banking, investments, and more in one unified vault.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF06B6D4),
    },
    {
      'title': 'Password Security',
      'desc': 'Generate and store strong passwords with military-grade protection.',
      'icon': Icons.lock_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Emergency Access',
      'desc': 'Trusted contacts can access your vault when it matters most.',
      'icon': Icons.people_rounded,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF635BFF).withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 20,
                              color: isDark ? Colors.white54 : const Color(0xFF8898AA)),
                          onPressed: widget.onFinish,
                        ),
                      ),
                    ),
                    // Content
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) => setState(() => _currentPage = idx),
                        itemCount: _slides.length,
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: (slide['color'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 30,
                                    color: slide['color'] as Color,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  slide['title']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1A1F36),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  slide['desc']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF697386),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == index ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF635BFF)
                                : const Color(0xFF635BFF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    // Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                      child: GradientButton(
                        text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        icon: _currentPage == _slides.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            widget.onFinish();
                          }
                        },
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
