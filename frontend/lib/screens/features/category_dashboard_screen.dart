import 'package:flutter/material.dart';
import '../../models/category_schema.dart';
import '../../services/vault_service.dart';
import '../../theme.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/schema_driven_form.dart';

import 'asset_detail_screen.dart';
import '../../widgets/benefit_modal.dart';
import '../../widgets/glass_card.dart';

/// Universal category dashboard — one screen for ALL 11 categories.
/// Renders items dynamically based on the CategorySchema.
class CategoryDashboardScreen extends StatefulWidget {
  final CategorySchema schema;
  final VoidCallback? onBack;

  const CategoryDashboardScreen({super.key, required this.schema, this.onBack});

  @override
  State<CategoryDashboardScreen> createState() => _CategoryDashboardScreenState();
}

class _CategoryDashboardScreenState extends State<CategoryDashboardScreen> {
  final VaultService _vaultService = VaultService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(CategoryDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schema.key != widget.schema.key) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _vaultService.getItems(widget.schema.key);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      return title.contains(q);
    }).toList();
  }

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => SchemaDrivenForm(
          schema: widget.schema,
          onSubmit: (data) async {
            await _vaultService.addItem(widget.schema.key, data);
            if (mounted) {
              Navigator.pop(context);
              _loadItems();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.schema.label} added to vault'),
                  backgroundColor: widget.schema.parsedColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = widget.schema.parsedColor;
    final categoryIcon = AppTheme.categoryIcons[widget.schema.key] ?? Icons.folder_rounded;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
          color: categoryColor,
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onBack ?? () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: Icon(Icons.arrow_back_rounded, size: 20, color: theme.colorScheme.onSurface),
                            ),
                          ),
                          const Spacer(),
                          // Item count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_items.length} item${_items.length == 1 ? '' : 's'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [categoryColor.withValues(alpha: 0.15), categoryColor.withValues(alpha: 0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(categoryIcon, color: categoryColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.schema.label, style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 2),
                                Text(widget.schema.description, 
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Search bar ───
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.outline),
                          boxShadow: AppTheme.clayShadow(),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.schema.label.toLowerCase()}...',
                            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ─── Content ───
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text('Failed to load', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(_error!, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadItems,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredItems.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(categoryIcon, size: 48, color: categoryColor.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No ${widget.schema.label.toLowerCase()} yet' : 'No results found',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tap + to add your first ${widget.schema.label.toLowerCase().replaceAll('s\$', '')}'
                              : 'Try a different search term',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildItemCard(item, theme, categoryColor, categoryIcon);
                    },
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // ─── FAB ───
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddForm,
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add ${widget.schema.label == 'Others' ? 'Item' : widget.schema.label.replaceAll(RegExp(r's$'), '')}'),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, ThemeData theme, Color categoryColor, IconData categoryIcon) {
    final title = item['title'] ?? 'Untitled';
    final metadata = item['metadata'] as Map<String, dynamic>? ?? item;
    
    // Special handling for subtitle labels (Card, Bank, etc)
    final subtitleParts = <String>[];
    
    if (widget.schema.key == 'cards') {
      if (metadata['bank_name'] != null) subtitleParts.add(metadata['bank_name'].toString());
      if (metadata['network'] != null) subtitleParts.add(metadata['network'].toString());
      if (metadata['variant'] != null) subtitleParts.add(metadata['variant'].toString());
    } else if (widget.schema.key == 'banking') {
      if (metadata['bank_name'] != null) subtitleParts.add(metadata['bank_name'].toString());
      if (metadata['account_type'] != null) subtitleParts.add(metadata['account_type'].toString());
    } else {
      for (final field in widget.schema.fields) {
        if (field.type != FieldType.file && subtitleParts.length < 2) {
          final value = metadata[field.key]?.toString() ?? '';
          if (value.isNotEmpty && value != title) {
            subtitleParts.add('${field.label}: $value');
          }
        }
      }
    }
    
    final subtitleRaw = subtitleParts.join(' · ');
    final hasBenefits = metadata['benefits'] != null && (metadata['benefits'] as List).isNotEmpty;

    return ClayCard(
      elevated: true,
      accentColor: categoryColor,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(
              schema: widget.schema,
              item: item,
              onUpdate: _loadItems,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                if (subtitleRaw.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitleRaw, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (widget.schema.key == 'cards') ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => FractionallySizedBox(
                          heightFactor: 0.8,
                          child: BenefitModal(
                            item: item,
                            onUpdate: _loadItems,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          hasBenefits ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasBenefits ? 'View Card Benefits' : 'Fetch Card Benefits',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}
