import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../theme.dart';
import '../services/api_service.dart';
import 'succession_claim_screen.dart';

class AppointedVaultsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AppointedVaultsScreen({super.key, required this.onBack});

  @override
  State<AppointedVaultsScreen> createState() => _AppointedVaultsScreenState();
}

class _AppointedVaultsScreenState extends State<AppointedVaultsScreen> {
  bool _isLoading = true;
  List<dynamic> _vaults = [];
  List<dynamic> _opportunities = [];
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final vaults = await _api.getInheritedAccounts();
      final opps = await _api.getNomineeOpportunities();
      setState(() {
        _vaults = vaults;
        _opportunities = opps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointed vaults: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_opportunities.isNotEmpty) ...[
                          _sectionTitle('Discovery', Icons.search_rounded),
                          const SizedBox(height: 12),
                          ..._opportunities.map((o) => _opportunityCard(o)),
                          const SizedBox(height: 32),
                        ],
                        _sectionTitle('Appointed Vaults', Icons.verified_user_rounded),
                        const SizedBox(height: 12),
                        if (_vaults.isEmpty)
                          _emptyState()
                        else
                          ..._vaults.map((v) => _vaultCard(v)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Appointed Vaults',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _opportunityCard(dynamic o) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(Icons.link_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['owner_name'] ?? 'Unknown Owner', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Listed as: ${o['relationship']}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showLinkDialog(o),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Link Account'),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _vaultCard(dynamic v) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _openClaimScreen(v),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _profileImage(v['full_name']),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['full_name'] ?? 'Vault Owner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Relationship: ${v['relationship']}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _profileImage(String? name) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.6)]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (name ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No vaults found.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'Once you are appointed as a nominee and link\nthe account, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(dynamic o) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To link ${o['owner_name']}\'s vault, please enter the 9-character security code provided to you by the owner.'),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Security Code',
                hintText: 'XXX-XXX-XXX',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final res = await _api.linkNomineeAccount(o['nominee_id'], codeController.text);
                if (res['success']) {
                  Navigator.pop(context);
                  _loadAll();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault linked successfully!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to link: $e')));
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _openClaimScreen(dynamic v) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SuccessionClaimScreen(vault: v)),
    ).then((_) => _loadAll());
  }
}
