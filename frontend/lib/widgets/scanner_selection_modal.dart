import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_schema.dart';
import '../services/vault_service.dart';
import '../theme.dart';
import 'schema_driven_form.dart';
import 'package:animate_do/animate_do.dart';

class ScannerSelectionModal extends StatefulWidget {
  final VaultSchemaResponse? schemaResponse;
  final VaultService? vaultService;
  const ScannerSelectionModal({super.key, this.schemaResponse, this.vaultService});

  @override
  State<ScannerSelectionModal> createState() => _ScannerSelectionModalState();
}

class _ScannerSelectionModalState extends State<ScannerSelectionModal> {
  String _searchQuery = '';
  String _selectedParentFilter = 'All';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final schemaResponse = widget.schemaResponse;

    if (schemaResponse == null) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    // Filter categories that have at least one file field
    final scannableCategories = schemaResponse.categories.values.where((cat) {
      final hasFileField = cat.fields.any((f) => f.type == FieldType.file);
      final matchesSearch = cat.label.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedParentFilter == 'All' || 
                           (schemaResponse.parents[cat.parent]?.label == _selectedParentFilter);
      return hasFileField && matchesSearch && matchesFilter;
    }).toList();

    // Group by parent for display
    final grouped = <String, List<CategorySchema>>{};
    for (final cat in scannableCategories) {
      final parentLabel = schemaResponse.parents[cat.parent]?.label ?? 'Other';
      grouped.putIfAbsent(parentLabel, () => []).add(cat);
    }

    // Get all parents for chips
    final parents = ['All', ...schemaResponse.parents.values.map((p) => p.label).toList()];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0F172A).withValues(alpha: 0.85) 
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mission Control Scanner', 
                               style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
                          Text('Select your document type to begin scan', 
                               style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search (e.g. Passport, Bank Statement)',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: parents.map((p) {
                    final isSelected = _selectedParentFilter == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p, style: TextStyle(
                          fontSize: 12, 
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        )),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedParentFilter = p);
                        },
                        selectedColor: AppTheme.primaryBlue,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        showCheckmark: false,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    shrinkWrap: true,
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, parentIndex) {
                      final parentLabel = grouped.keys.elementAt(parentIndex);
                      final categories = grouped[parentLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeIn(
                            duration: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Text(
                                parentLabel.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          ...List.generate(categories.length, (catIndex) {
                            final cat = categories[catIndex];
                            return FadeInUp(
                              duration: const Duration(milliseconds: 400),
                              delay: Duration(milliseconds: 50 * (parentIndex + catIndex)),
                              child: _buildCategoryTile(cat, theme),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(CategorySchema cat, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _openAddForm(context, cat);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cat.parsedColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppTheme.categoryIcons[cat.key] ?? Icons.insert_drive_file_rounded, 
                     color: cat.parsedColor, 
                     size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label, style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15, 
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    )),
                    const SizedBox(height: 2),
                    Text(cat.description, 
                         style: theme.textTheme.bodySmall?.copyWith(
                           color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                           fontSize: 12,
                         ), 
                         maxLines: 1, 
                         overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddForm(BuildContext context, CategorySchema cat) {
    final vaultService = widget.vaultService;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SchemaDrivenForm(
        schema: cat,
        onSubmit: (data) async {
          if (vaultService != null) await vaultService.addItem(cat.key, data);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vaulted: ${cat.label}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: cat.parsedColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );
  }
}
