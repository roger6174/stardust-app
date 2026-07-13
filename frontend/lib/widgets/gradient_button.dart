import 'package:flutter/material.dart';
import '../theme.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = isEnabled),
      onExit: (_) => setState(() { _hovering = false; _pressing = false; }),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _pressing ? 1.0 : (_hovering ? -1.0 : 0.0)),
          width: widget.width ?? double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: [
                      const Color(0xFF2563EB),
                      const Color(0xFF3B82F6),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isEnabled
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF0F1FA)),
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: _hovering ? 0.4 : 0.2),
                      blurRadius: _hovering ? 20 : 10,
                      offset: Offset(0, _hovering ? 6 : 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: isEnabled
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFF8898AA)),
                    size: 18),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: isEnabled
                      ? Colors.white
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFF8898AA)),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
