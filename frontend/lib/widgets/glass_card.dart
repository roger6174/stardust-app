import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Light mode: elevated white card with strong shadow
    // Dark mode: frosted glass
    final Color bgColor = isDark
        ? Colors.white.withValues(alpha: _isHovered ? 0.08 : 0.05)
        : Colors.white.withValues(alpha: _isHovered ? 1.0 : 0.92);

    final Color borderColor = isDark
        ? colorScheme.primary.withValues(alpha: _isHovered ? 0.4 : 0.15)
        : (_isHovered
            ? colorScheme.primary.withValues(alpha: 0.3)
            : const Color(0xFFE2E5F1));

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..translate(0.0, _isHovered ? -3.0 : 0.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            // Primary shadow — gives the card depth
            BoxShadow(
              color: isDark
                  ? colorScheme.primary
                      .withValues(alpha: _isHovered ? 0.15 : 0.05)
                  : const Color(0xFF635BFF)
                      .withValues(alpha: _isHovered ? 0.08 : 0.0),
              blurRadius: _isHovered ? 32 : 0,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            // Ambient shadow — always present in light mode
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF1A1F36)
                    .withValues(alpha: _isHovered ? 0.10 : 0.06),
                blurRadius: _isHovered ? 24 : 12,
                spreadRadius: -2,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: isDark ? 20 : 0, sigmaY: isDark ? 20 : 0),
            child: Padding(
              padding:
                  widget.padding ?? const EdgeInsets.all(AppSpacing.medium),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
