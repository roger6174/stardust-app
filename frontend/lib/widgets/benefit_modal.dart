import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import '../theme.dart';

class BenefitModal extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onUpdate;

  const BenefitModal({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<BenefitModal> createState() => _BenefitModalState();
}

class _BenefitModalState extends State<BenefitModal> with SingleTickerProviderStateMixin {
  final VaultService _vaultService = VaultService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  List<String> _benefits = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _initBenefits();
  }

  void _initBenefits() {
    final metadata = widget.item['metadata'] as Map<String, dynamic>? ?? {};
    final benefitsRaw = metadata['benefits'];
    
    if (benefitsRaw != null && benefitsRaw is List) {
      _benefits = benefitsRaw.cast<String>();
      _animationController.forward();
    } else {
      _fetchBenefits();
    }
  }

  Future<void> _fetchBenefits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assetId = widget.item['asset_id'];
      if (assetId == null) throw 'Invalid asset ID';
      
      final benefits = await _vaultService.fetchCardBenefits(int.parse(assetId.toString()));
      if (mounted) {
        setState(() {
          _benefits = benefits;
          _isLoading = false;
        });
        _animationController.forward(from: 0);
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = widget.item['metadata'] as Map<String, dynamic>? ?? {};
    final cardTitle = widget.item['title'] ?? 'Credit Card';
    final cardVariant = metadata['variant'] ?? '';
    final cardBank = metadata['bank_name'] ?? '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium Benefits', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          Text('$cardBank $cardVariant', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: _isLoading 
                    ? _buildLoadingState(theme)
                    : _error != null 
                      ? _buildErrorState(theme)
                      : _buildBenefitsList(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text('Discovering card perks...', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Using Gemini AI to analyze your card variant', style: theme.textTheme.bodySmall),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.cloud_off_rounded, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Unable to fetch benefits', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _fetchBenefits,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final icons = [
      Icons.stars_rounded,
      Icons.flight_takeoff_rounded,
      Icons.restaurant_rounded,
      Icons.shopping_bag_rounded,
      Icons.support_agent_rounded,
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          ...List.generate(_benefits.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icons[index % icons.length], color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _benefits[index],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Generated by Stardust AI Engine',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetchBenefits,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: const Text('Regenerate Benefits'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
