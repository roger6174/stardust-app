import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_schema.dart';
import '../theme.dart';

class CategoryWheelSelector extends StatefulWidget {
  final List<CategorySchema> schemas;
  final Function(CategorySchema) onSelect;

  const CategoryWheelSelector({
    super.key,
    required this.schemas,
    required this.onSelect,
  });

  @override
  State<CategoryWheelSelector> createState() => _CategoryWheelSelectorState();
}

class _CategoryWheelSelectorState extends State<CategoryWheelSelector> {
  late FixedExtentScrollController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default to the middle or first item
    _selectedIndex = (widget.schemas.length / 2).floor();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSelectedItemChanged(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSchema = widget.schemas[_selectedIndex];
    final accentColor = selectedSchema.parsedColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          // Dynamic Background Glow
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),

          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Choose Category',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scroll to select asset type',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glass Selection Highlight
                        Container(
                          height: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                        ),

                        ListWheelScrollView.useDelegate(
                          controller: _controller,
                          itemExtent: 100,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: _handleSelectedItemChanged,
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: widget.schemas.length,
                            builder: (context, index) {
                              final schema = widget.schemas[index];
                              final isSelected = _selectedIndex == index;
                              final icon = AppTheme.categoryIcons[schema.key] ?? Icons.folder_rounded;

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.4,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? schema.parsedColor.withValues(alpha: 0.1) : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          size: isSelected ? 32 : 24,
                                          color: isSelected ? schema.parsedColor : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        schema.label,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                          fontSize: isSelected ? 22 : 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection Button
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => widget.onSelect(selectedSchema),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: accentColor.withValues(alpha: 0.4),
                        ),
                        child: const Text('Confirm Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
