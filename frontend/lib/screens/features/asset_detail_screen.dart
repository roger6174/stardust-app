import 'package:flutter/material.dart';
import '../../models/category_schema.dart';
import '../../services/vault_service.dart';
import '../../theme.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/schema_driven_form.dart';
import '../../widgets/benefit_modal.dart';

/// Universal asset detail screen — view/edit/delete any item from any category.
class AssetDetailScreen extends StatefulWidget {
  final CategorySchema schema;
  final Map<String, dynamic> item;
  final VoidCallback? onUpdate;

  const AssetDetailScreen({
    super.key,
    required this.schema,
    required this.item,
    this.onUpdate,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final VaultService _vaultService = VaultService();
  late Map<String, dynamic> _item;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _item = Map.from(widget.item);
  }

  void _showEditForm() {
    final metadata = _item['metadata'] as Map<String, dynamic>? ?? _extractMetadata();

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
          initialData: metadata,
          onSubmit: (data) async {
            final assetId = _item['asset_id'];
            try {
              await _vaultService.updateItem(widget.schema.key, assetId, data);
              if (mounted) {
                Navigator.pop(context);
                // Reload the item
                final updated = await _vaultService.getItem(widget.schema.key, assetId);
                setState(() => _item = updated);
                widget.onUpdate?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Updated successfully'),
                    backgroundColor: widget.schema.parsedColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Update failed: $e'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${_item['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await _vaultService.deleteItem(widget.schema.key, _item['asset_id']);
        widget.onUpdate?.call();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Map<String, dynamic> _extractMetadata() {
    // Build metadata from flattened item fields
    final metadata = <String, dynamic>{};
    for (final field in widget.schema.fields) {
      if (_item.containsKey(field.key)) {
        metadata[field.key] = _item[field.key];
      }
    }
    return metadata;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = widget.schema.parsedColor;
    final categoryIcon = AppTheme.categoryIcons[widget.schema.key] ?? Icons.folder_rounded;
    final metadata = _item['metadata'] as Map<String, dynamic>? ?? _extractMetadata();

    return Scaffold(
      body: SafeArea(
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
                          onTap: () => Navigator.pop(context),
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
                        // Edit button
                        GestureDetector(
                          onTap: _showEditForm,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_rounded, size: 20, color: categoryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: _isDeleting ? null : _confirmDelete,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isDeleting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title card
                    ClayCard(
                      elevated: true,
                      accentColor: categoryColor,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [categoryColor.withValues(alpha: 0.2), categoryColor.withValues(alpha: 0.05)],
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
                                Text(_item['title'] ?? 'Untitled', style: theme.textTheme.headlineSmall),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.schema.label,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Field Details ───
                    Text('Details', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ─── Field list ───
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: widget.schema.fields.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final field = widget.schema.fields[index];
                  if (field.type == FieldType.file) return const SizedBox.shrink();
                  
                  final value = metadata[field.key]?.toString() ?? _item[field.key]?.toString() ?? '';
                  if (value.isEmpty) return const SizedBox.shrink();

                  final isPassword = field.type == FieldType.password;

                  return ClayCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            field.label,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            isPassword ? '••••••••' : value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isPassword)
                          Icon(Icons.visibility_off_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ─── Card Benefits Section ───
            if (widget.schema.key == 'cards')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Card Perks', style: theme.textTheme.titleLarge),
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome_rounded, size: 18, color: categoryColor),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (metadata['benefits'] != null && (metadata['benefits'] as List).isNotEmpty)
                        Column(
                          children: (metadata['benefits'] as List).map((point) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ClayCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.star_rounded, size: 16, color: categoryColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        point.toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        ClayCard(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => FractionallySizedBox(
                                heightFactor: 0.8,
                                child: BenefitModal(
                                  item: _item,
                                  onUpdate: () async {
                                    final updated = await _vaultService.getItem(widget.schema.key, _item['asset_id']);
                                    setState(() => _item = updated);
                                    widget.onUpdate?.call();
                                  },
                                ),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.auto_awesome_outlined, color: categoryColor, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  'Fetch Card Perks using AI',
                                  style: theme.textTheme.titleMedium?.copyWith(color: categoryColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Discover hidden benefits for your ${metadata['variant'] ?? 'card'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ─── Audit info ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    if (_item['created_at'] != null)
                      _auditRow(theme, Icons.add_circle_outline_rounded, 'Created', _item['created_at'].toString()),
                    if (_item['updated_at'] != null) ...[
                      const SizedBox(height: 6),
                      _auditRow(theme, Icons.update_rounded, 'Updated', _item['updated_at'].toString()),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _auditRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value.split('T').first,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
