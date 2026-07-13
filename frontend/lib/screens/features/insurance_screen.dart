import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/stardust_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_list_wrapper.dart';
import '../../widgets/drop_zone_wrapper.dart';
import '../../widgets/login_prompt.dart';
import '../../widgets/success_animation.dart';
import '../../widgets/add_doc_sheet.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/document_viewer.dart';
import '../../theme.dart';
import '../../services/insurance_service.dart';

class InsuranceScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isGuest;
  const InsuranceScreen({super.key, this.onBack, this.isGuest = false});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  final InsuranceService _insuranceService = InsuranceService();
  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _fetchPolicies();
    }
  }

  Future<void> _fetchPolicies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final policies = await _insuranceService.getInsurance();
      setState(() {
        _policies = policies;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addPolicy() {
    if (widget.isGuest) {
      LoginRequiredPrompt.show(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddPolicySheet(onAdd: (provider, policyNo, type) async {
        try {
          await _insuranceService.addInsurance({
            'policy_name': provider,
            'provider': provider,
            'type': type,
            'policy_number': policyNo,
          });
          _fetchPolicies();
          if (mounted) SuccessAnimationOverlay.show(context);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save policy: $e'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }),
    );
  }

  void _onFileDropped(XFile file) {
    if (widget.isGuest) {
      LoginRequiredPrompt.show(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddDocSheet(
        type: 'Insurance',
        initialFile: file,
        onAdd: (title, fileKey, fileUrl) async {
          try {
            await _insuranceService.addInsurance({
              'policy_name': title,
              'provider': title,
              'type': 'General',
              'policy_number': 'SCAN-${DateTime.now().millisecond}',
              'metadata': {
                'file_key': fileKey,
                'file_url': fileUrl,
              },
            });
            _fetchPolicies();
            if (mounted) SuccessAnimationOverlay.show(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save policy document: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DropZoneWrapper(
        onDrop: _onFileDropped,
        child: StardustBackground(
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                          : _policies.isEmpty
                              ? _emptyState(context)
                              : RefreshIndicator(
                                  onRefresh: _fetchPolicies,
                                  child: AnimatedListWrapper(
                                    padding: const EdgeInsets.all(AppSpacing.edge),
                                    children: _policies.map((policy) {
                                      final type = policy['type'] ?? 'General';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: GlassCard(
                                          onTap: (policy['metadata']?['file_key'] != null || policy['metadata']?['file_url'] != null) ? () {
                                            DocumentViewer.show(
                                              context,
                                              title: policy['provider'] ?? 'Policy',
                                              fileKey: policy['metadata']?['file_key'],
                                              filePath: policy['metadata']?['file_url'],
                                            );
                                          } : null,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  type == 'Health'
                                                      ? Icons.health_and_safety_rounded
                                                      : Icons.directions_car_rounded,
                                                  color: theme.colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(policy['provider'] ?? 'Unknown',
                                                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                                                    Text(type,
                                                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386))),
                                                  ],
                                                ),
                                              ),
                                              Text(policy['policy_number'] ?? '',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.onSurface)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPolicy,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.edge),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: theme.colorScheme.onSurface, size: isMobile ? 20 : 24),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Text('Insurance',
              style: isMobile ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety_outlined,
              size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.medium),
          Text('No policies added yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
          if (!widget.isGuest) ...[
            const SizedBox(height: AppSpacing.medium),
            TextButton(onPressed: _fetchPolicies, child: const Text('Refresh')),
          ],
        ],
      ),
    );
  }
}

class _AddPolicySheet extends StatefulWidget {
  final Function(String, String, String) onAdd;
  const _AddPolicySheet({required this.onAdd});

  @override
  State<_AddPolicySheet> createState() => _AddPolicySheetState();
}

class _AddPolicySheetState extends State<_AddPolicySheet> {
  final _providerController = TextEditingController();
  final _policyNoController = TextEditingController();
  String _type = 'Health';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      margin: EdgeInsets.fromLTRB(
          AppSpacing.medium,
          100,
          AppSpacing.medium,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xlarge),
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Policy', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.large),
          TextField(
            controller: _providerController,
            decoration: const InputDecoration(labelText: 'Provider Name'),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _policyNoController,
            decoration: const InputDecoration(labelText: 'Policy Number'),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text('Type',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.small),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('Health'),
                const SizedBox(width: AppSpacing.medium),
                _typeChip('Vehicle'),
                const SizedBox(width: AppSpacing.medium),
                _typeChip('Life'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xlarge),
          GradientButton(
            text: 'Add Policy',
            onPressed: () {
              if (_providerController.text.isNotEmpty) {
                widget.onAdd(_providerController.text, _policyNoController.text, _type);
                Navigator.pop(context);
              }
            },
          ),
        ],
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
