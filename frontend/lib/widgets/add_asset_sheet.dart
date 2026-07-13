import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'gradient_button.dart';
import '../theme.dart';

class AddAssetSheet extends StatefulWidget {
  final Function(String, String, String) onAdd;
  final String category;
  const AddAssetSheet({super.key, required this.onAdd, this.category = 'Digital'});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _variantController = TextEditingController();
  final _typeDetailController = TextEditingController();
  String _type = 'Digital';

  @override
  void initState() {
    super.initState();
    _type = widget.category == 'Cards' ? 'Physical' : 'Digital';
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCard = widget.category == 'Cards';
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCard ? Icons.credit_card_rounded : Icons.inventory_2_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isCard ? 'Add New Card' : 'Add New Asset',
                            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
                        Text('Vault your ${isCard ? 'card' : 'asset'} details safely',
                            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isCard ? 'Card Name' : 'Asset Name',
                  hintText: isCard ? 'e.g. HDFC Millennia' : '',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              if (isCard) ...[
                TextField(
                  controller: _variantController,
                  decoration: const InputDecoration(
                    labelText: 'Variant',
                    hintText: 'e.g. Gold, Platinum, Signature',
                    prefixIcon: Icon(Icons.star_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _typeDetailController,
                  decoration: const InputDecoration(
                    labelText: 'Card Type',
                    hintText: 'e.g. Visa, Rupay, Mastercard',
                    prefixIcon: Icon(Icons.payments_rounded, size: 20),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value / Identifier',
                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!isCard) ...[
                Text('Category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF697386),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _typeChip('Digital'),
                    const SizedBox(width: 12),
                    _typeChip('Physical'),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              GradientButton(
                text: isCard ? 'Add Card' : 'Add Asset',
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    if (isCard) {
                      final value = '${_variantController.text} | ${_typeDetailController.text}';
                      widget.onAdd(_nameController.text, value, 'Card');
                    } else {
                      widget.onAdd(_nameController.text, _valueController.text, _type);
                    }
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label) {
    final theme = Theme.of(context);
    final selected = _type == label;
    return GestureDetector(
      onTap: () => setState(() => _type = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.small + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: selected 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
