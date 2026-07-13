import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/stardust_background.dart';
import '../services/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      final bool authenticated = await ApiClient().isAuthenticated();
      if (authenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: {'isGuest': false, 'isLogin': true});
      } else {
        Navigator.pushReplacementNamed(context, '/intro');
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StardustBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Animated logo with pulse ring ───
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: ZoomIn(
                  duration: const Duration(milliseconds: 1200),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF635BFF)
                                  .withValues(alpha: 0.15 + (_pulseCtrl.value * 0.15)),
                              blurRadius: 40 + (_pulseCtrl.value * 20),
                              spreadRadius: _pulseCtrl.value * 8,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // ─── App name ───
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 400),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                  ).createShader(bounds),
                  child: const Text(
                    'Stardust Vault',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ─── Tagline ───
              FadeIn(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 800),
                child: const Text(
                  'SECURE YOUR DIGITAL LEGACY',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8898AA),
                    letterSpacing: 3.0,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // ─── Loading indicator ───
              FadeIn(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 1200),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF635BFF).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
