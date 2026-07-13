import 'package:flutter/material.dart';

/// Premium background with subtle gradient mesh and floating orbs.
/// In light mode: soft cool-toned gradient with visible decorative elements.
/// In dark mode: deep space gradient with glowing orbs.
class StardustBackground extends StatefulWidget {
  final Widget child;
  const StardustBackground({super.key, required this.child});

  @override
  State<StardustBackground> createState() => _StardustBackgroundState();
}

class _StardustBackgroundState extends State<StardustBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            // ─── Base gradient ───
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF0B1120),
                          const Color(0xFF0D1529),
                          const Color(0xFF111E36),
                          const Color(0xFF0D1529),
                          const Color(0xFF0B1120),
                        ]
                      : [
                          const Color(0xFFFAFCFF),
                          const Color(0xFFF0F4FF),
                          const Color(0xFFE8EFFF),
                          const Color(0xFFF0F4FF),
                          const Color(0xFFFAFCFF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ─── Decorative orb: top-right ───
            Positioned(
              top: -60 + (30 * _ctrl.value),
              right: -80 + (20 * _ctrl.value),
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB)
                          .withValues(alpha: isDark ? 0.15 : 0.06),
                      const Color(0xFF2563EB)
                          .withValues(alpha: isDark ? 0.05 : 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ─── Decorative orb: bottom-left ───
            Positioned(
              bottom: -100 + (25 * _ctrl.value),
              left: -60 + (15 * _ctrl.value),
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6)
                          .withValues(alpha: isDark ? 0.12 : 0.05),
                      const Color(0xFF3B82F6)
                          .withValues(alpha: isDark ? 0.04 : 0.015),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ─── Decorative orb: center accent ───
            Positioned(
              top: size.height * 0.35,
              right: size.width * 0.15,
              child: Container(
                width: 200 + (30 * _ctrl.value),
                height: 200 + (30 * _ctrl.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4)
                          .withValues(alpha: isDark ? 0.08 : 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ─── Subtle grid pattern for light mode ───
            if (!isDark)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: CustomPaint(painter: _DotPatternPainter()),
                ),
              ),

            // ─── Child content ───
            widget.child,
          ],
        );
      },
    );
  }
}

/// Subtle dot grid pattern for visual texture
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
