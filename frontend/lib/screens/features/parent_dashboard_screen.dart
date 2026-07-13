import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/category_schema.dart';
import '../../widgets/clay_card.dart';
import 'package:animate_do/animate_do.dart';

class ParentDashboardScreen extends StatelessWidget {
  final ParentCategory parent;
  final List<CategorySchema> subcategories;
  final Map<String, int> counts;
  final Function(String) onSelectSubcategory;
  final VoidCallback onBack;

  const ParentDashboardScreen({
    super.key,
    required this.parent,
    required this.subcategories,
    required this.counts,
    required this.onSelectSubcategory,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;
    final color = parent.parsedColor;

    // Responsive grid columns
    int gridCols;
    double gridAspect;
    if (screenWidth >= 1024) {
      gridCols = 4; gridAspect = 1.30;
    } else if (screenWidth >= 768) {
      gridCols = 3; gridAspect = 1.25;
    } else if (screenWidth >= 600) {
      gridCols = 3; gridAspect = 1.10;
    } else if (screenWidth >= 430) {
      gridCols = 2; gridAspect = 1.20;
    } else {
      gridCols = 2; gridAspect = 1.05;
    }

    // Split subcategories into active and empty
    final activeSubs = subcategories.where((s) => (counts[s.key] ?? 0) > 0).toList();
    final emptySubs = subcategories.where((s) => (counts[s.key] ?? 0) == 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.edge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
                tooltip: 'Back to Dashboard',
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppTheme.categoryIcons[parent.key] ?? Icons.folder_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.label, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Manage all items in ${parent.label}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (activeSubs.isNotEmpty) ...[
            _sectionHeader('Included in Your Plan'),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: gridAspect,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeSubs.length,
              itemBuilder: (context, index) {
                final sub = activeSubs[index];
                return _subcategoryCard(context, sub, counts[sub.key] ?? 0, index);
              },
            ),
            const SizedBox(height: 32),
          ],

          if (emptySubs.isNotEmpty) ...[
            _sectionHeader('Suggested for You'),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: gridAspect,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: emptySubs.length,
              itemBuilder: (context, index) {
                final sub = emptySubs[index];
                return _subcategoryCard(context, sub, 0, index + activeSubs.length, isSuggested: true);
              },
            ),
          ],
          
          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(label.toUpperCase(), style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryBlue,
        letterSpacing: 1.2,
      )),
    );
  }

  Widget _subcategoryCard(BuildContext context, CategorySchema sub, int count, int index, {bool isSuggested = false}) {
    final theme = Theme.of(context);
    final color = sub.parsedColor;
    final icon = AppTheme.categoryIcons[sub.key] ?? Icons.insert_drive_file_rounded;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 50 * index),
      child: ClayCard(
        elevated: true,
        accentColor: color,
        padding: const EdgeInsets.all(AppSpacing.large),
        onTap: () => onSelectSubcategory(sub.key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(isSuggested ? Icons.add_rounded : icon, color: color, size: 20),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            const Spacer(),
            Text(sub.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(isSuggested ? 'Get started' : sub.description, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
