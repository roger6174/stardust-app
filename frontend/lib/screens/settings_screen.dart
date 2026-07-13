import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  int _triggerMonths = 3;
  int _reminderWeeks = 1;
  String? _securityCode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _api.getProfile();
      setState(() {
        _triggerMonths = profile['inactivity_trigger_period'] ?? 3;
        _reminderWeeks = profile['reminder_interval'] ?? 1;
        _securityCode = profile['security_code'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePolicy() async {
    setState(() => _isSaving = true);
    try {
      await _api.updateVaultPolicy(
        triggerPeriod: _triggerMonths,
        reminderInterval: _reminderWeeks,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault policy updated successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      setState(() => _isSaving = false);
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
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _sectionTitle('Legacy Protection Protocol', Icons.auto_awesome_rounded),
                    const SizedBox(height: 16),
                    _policyCard(),
                    const SizedBox(height: 32),
                    _sectionTitle('Vault Governance', Icons.gavel_rounded),
                    const SizedBox(height: 16),
                    _securityCodeCard(),
                    const SizedBox(height: 32),
                    _sectionTitle('Account Continuity', Icons.manage_accounts_rounded),
                    const SizedBox(height: 16),
                    _settingItem(Icons.alternate_email_rounded, 'Communication Preferences', 'Manage pulse notifications'),
                    _settingItem(Icons.logout_rounded, 'Delete Account', 'Permanently remove all vault data', isDestructive: true),
                    const SizedBox(height: 40),
                  ],
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
            'Vault Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey)),
      ],
    );
  }

  Widget _policyCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _policyRow('Inactivity Trigger', '$_triggerMonths Months', Icons.timer_rounded, () => _showPicker('Trigger Period', 1, 12, _triggerMonths, (v) => setState(() => _triggerMonths = v))),
          const Divider(height: 32),
          _policyRow('Pulse Frequency', 'Every $_reminderWeeks Week', Icons.notifications_active_rounded, () => _showPicker('Reminder Interval', 1, 4, _reminderWeeks, (v) => setState(() => _reminderWeeks = v))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePolicy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Apply Governance Policy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyRow(String label, String value, IconData icon, VoidCallback onTap) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const Spacer(),
        TextButton(onPressed: onTap, child: const Text('Change')),
      ],
    );
  }

  Widget _securityCodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Master Security Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Share this code ONLY with your trusted nominees. It is required to initiate the succession protocol.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_securityCode ?? 'LOADING...', style: const TextStyle(color: AppTheme.primaryBlue, letterSpacing: 4, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(width: 16),
                const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _settingItem(IconData icon, String title, String subtitle, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : theme.iconTheme.color),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : null, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () {},
    );
  }

  void _showPicker(String title, int min, int max, int current, Function(int) onSelect) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: (max - min) + 1,
                itemBuilder: (context, i) {
                  final val = min + i;
                  return ListTile(
                    title: Text('$val ${title.split(' ')[1]}'),
                    trailing: val == current ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                    onTap: () {
                      onSelect(val);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
