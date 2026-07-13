import 'package:flutter/material.dart';
import '../theme.dart';

/// Claymorphism-styled card — soft extruded look with dual shadows.
/// Replaces the old GlassCard for the new blue/white design system.
class ClayCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool elevated;

  const ClayCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.cardRadius,
    this.onTap,
    this.accentColor,
    this.elevated = false,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;


  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive = widget.onTap != null;

    // ─── Colors ───
    final Color bgColor = isDark
        ? (_isHovered ? AppTheme.darkCard.withValues(alpha: 0.95) : AppTheme.darkCard)
        : (_isHovered ? AppTheme.white : AppTheme.white.withValues(alpha: 0.95));

    final Color borderColor = isDark
        ? (_isHovered ? AppTheme.accentSky.withValues(alpha: 0.3) : AppTheme.darkBorder)
        : (_isHovered
            ? (widget.accentColor ?? AppTheme.primaryBlue).withValues(alpha: 0.25)
            : AppTheme.mist);

    // ─── Shadows ───
    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.3 : 0.2),
              offset: Offset(0, _isHovered ? 8 : 4),
              blurRadius: _isHovered ? 20 : 12,
            ),
          ]
        : [
            // Primary clay shadow
            BoxShadow(
              color: (widget.accentColor ?? const Color(0xFF2563EB))
                  .withValues(alpha: _isHovered ? 0.12 : (widget.elevated ? 0.08 : 0.04)),
              offset: Offset(0, _isHovered ? 12 : (widget.elevated ? 8 : 4)),
              blurRadius: _isHovered ? 32 : (widget.elevated ? 24 : 12),
              spreadRadius: 0,
            ),
            // Ambient shadow
            BoxShadow(
              color: const Color(0xFF0F172A)
                  .withValues(alpha: _isHovered ? 0.08 : (widget.elevated ? 0.06 : 0.03)),
              blurRadius: _isHovered ? 16 : (widget.elevated ? 10 : 6),
              spreadRadius: -2,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ];

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: shadows,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.medium),
        child: widget.child,
      ),
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    if (isInteractive) {
      card = ScaleTransition(
        scale: _scaleAnimation,
        child: card,
      );
    }

    return MouseRegion(
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isInteractive ? (_) {
          _controller.forward();
        } : null,
        onTapUp: isInteractive ? (_) {
          _controller.reverse();
        } : null,
        onTapCancel: isInteractive ? () {
          _controller.reverse();
        } : null,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
