import '../../widgets/animated_list_wrapper.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stardust_background.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: AnimatedListWrapper(
                  padding: const EdgeInsets.all(AppSpacing.edge),
                  children: [
                    _sectionHeader(context, 'Profile'),
                    _settingsTile(context, Icons.person_outline_rounded, 'Account Details', 'Guest User'),
                    _settingsTile(context, Icons.alternate_email_rounded, 'Email Address', 'guest@example.com'),
                    const SizedBox(height: 24),
                    _sectionHeader(context, 'Security'),
                    _settingsTile(context, Icons.fingerprint_rounded, 'Biometric Lock', 'Enabled', toggle: true),
                    _settingsTile(context, Icons.verified_user_rounded, 'Two-Factor Auth', 'Enabled'),
                    _settingsTile(context, Icons.key_rounded, 'Change Password', ''),
                    const SizedBox(height: 24),
                    _sectionHeader(context, 'Preferences'),
                    _settingsTile(context, Icons.notifications_none_rounded, 'Notifications', 'On', toggle: true),
                    _settingsTile(context, Icons.language_rounded, 'Language', 'English'),
                    _sectionHeader(context, 'Account Management'),
                    _settingsTile(
                      context, 
                      Icons.delete_forever_rounded, 
                      'Delete Account', 
                      'Permanent action',
                      textColor: Colors.redAccent,
                      onTap: () => _showDeleteConfirmationDialog(context),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleLogout,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Log Out', style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await _authService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.edge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
                const SizedBox(height: 16),
                Text('Delete Account?', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'This will permanently delete your vault and all nominee links. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF697386)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Type "delete" below to confirm',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onChanged: (val) {
                    setDialogState(() {
                      canDelete = val.toLowerCase() == 'delete';
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'delete',
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canDelete ? () async {
                          Navigator.pop(context);
                          _handleDeleteAccount();
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Permanent Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    setState(() => _isLoading = true);
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account permanently deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                color: theme.colorScheme.onSurface,
                size: isMobile ? 20 : 24),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Text('Settings',
              style: isMobile ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF697386),
              letterSpacing: 1.2,
              fontSize: 11)),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title, String value, {bool toggle = false, Color? textColor, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (textColor ?? theme.colorScheme.onSurface).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor ?? const Color(0xFF697386), size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  )),
            ),
            if (toggle)
              Switch(
                value: true, 
                onChanged: (_) {}, 
                activeColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            else if (value.isNotEmpty)
              Text(value,
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386))),
            if (!toggle) const SizedBox(width: 8),
            if (!toggle)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: (textColor ?? const Color(0xFF697386)).withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
