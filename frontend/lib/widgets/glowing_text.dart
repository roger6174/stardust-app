import 'package:flutter/material.dart';

class GlowingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GlowingText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // More intense glow for Light Mode to combat high ambient brightness
    final double spreadFactor = isDark ? 1.0 : 1.5;

    return Stack(
      children: [
        // The Glow
        Text(
          text,
          textAlign: textAlign,
          style: (style ?? const TextStyle()).copyWith(
            color: Colors.transparent,
            shadows: [
              Shadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.8),
                blurRadius: 20 * spreadFactor,
              ),
              Shadow(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: isDark ? 0.3 : 0.6),
                blurRadius: 40 * spreadFactor,
              ),
            ],
          ),
        ),
        // The Actual Text
        Text(
          text,
          textAlign: textAlign,
          style: (style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold, // Ensure it's bold as part of the structure
          ),
        ),
      ],
    );
  }
}
