import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/nominee_service.dart';
import '../../widgets/clay_card.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/login_prompt.dart';
import '../../widgets/success_animation.dart';

class NomineesScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool isGuest;

  const NomineesScreen({super.key, required this.onBack, this.isGuest = false});

  @override
  State<NomineesScreen> createState() => _NomineesScreenState();
}

class _NomineesScreenState extends State<NomineesScreen> {
  final NomineeService _nomineeService = NomineeService();
  List<Map<String, dynamic>> _nominees = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _loadNominees();
    }
  }

  Future<void> _loadNominees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final nominees = await _nomineeService.getNominees();
      setState(() => _nominees = nominees);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addNominee() {
    if (widget.isGuest) {
      LoginRequiredPrompt.show(context);
      return;
    }
    // Placeholder for Add Nominee flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nominee Management in progress...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.primaryBlue;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.edge),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_outline_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Nominees', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Choose who can access your vault when needed.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                  : _nominees.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edge),
                          itemCount: _nominees.length,
                          itemBuilder: (context, index) {
                            final n = _nominees[index];
                            return _nomineeTile(n, index);
                          },
                        ),
        ),

        // Action Footer
        Padding(
          padding: const EdgeInsets.all(AppSpacing.edge),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _addNominee,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Add New Nominee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _nomineeTile(Map<String, dynamic> nominee, int index) {
    final theme = Theme.of(context);
    final status = nominee['status'] ?? 'Active';
    final isVerified = nominee['is_verified'] == 1 || nominee['is_verified'] == true;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 50 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClayCard(
          elevated: true,
          accentColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(nominee['full_name']?.substring(0, 1).toUpperCase() ?? 'N', 
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nominee['full_name'] ?? 'Unknown Member', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(nominee['relationship'] ?? 'Family Member', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(isVerified ? 'Verified' : 'Pending', 
                      style: TextStyle(color: isVerified ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text('No Nominees Added Yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('Add trusted family members or friends who should be notified when necessary.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }
}
