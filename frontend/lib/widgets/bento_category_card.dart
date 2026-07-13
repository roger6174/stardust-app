import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/category_schema.dart';
import '../theme.dart';

class BentoCategoryCard extends StatelessWidget {
  final ParentCategory parent;
  final int count;
  final VoidCallback onTap;
  final bool isLarge;

  const BentoCategoryCard({
    super.key,
    required this.parent,
    required this.count,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parent.parsedColor;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(isLarge ? 24 : 16),
            decoration: BoxDecoration(
              color: isDark 
                  ? color.withValues(alpha: 0.12).withValues(alpha: 0.08) 
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark 
                    ? color.withValues(alpha: 0.3) 
                    : color.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
                // Inner Clay highlight
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.8),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        AppTheme.categoryIcons[parent.key] ?? Icons.folder_rounded, 
                        color: color, 
                        size: isLarge ? 28 : 22,
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    parent.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isLarge ? 18 : 14,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLarge) ...[ 
                  const SizedBox(height: 4),
                  Text(
                    '${parent.label.toLowerCase()} assets.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
