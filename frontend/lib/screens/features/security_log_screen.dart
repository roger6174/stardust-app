import 'package:flutter/material.dart';
import '../../widgets/stardust_background.dart';
import '../../widgets/glass_card.dart';
import '../../theme.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/security_service.dart';
import '../../widgets/animated_list_wrapper.dart';

class SecurityLogScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SecurityLogScreen({super.key, this.onBack});

  @override
  State<SecurityLogScreen> createState() => _SecurityLogScreenState();
}

class _SecurityLogScreenState extends State<SecurityLogScreen> {
  final SecurityService _securityService = SecurityService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final logs = await _securityService.getLogs();
      setState(() {
        _logs = logs;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      body: StardustBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.edge),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      onPressed: widget.onBack ?? () => Navigator.pop(context),
                      iconSize: isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Security Log',
                      style: isMobile ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge,
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _fetchLogs,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                        : AnimatedListWrapper(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edge),
                            children: [
                              GlassCard(
                                padding: const EdgeInsets.all(0),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.04),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text('EVENT', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF697386)))),
                                          Expanded(flex: 2, child: Text('IP ADDRESS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF697386)))),
                                          Expanded(flex: 2, child: Text('TIMESTAMP', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF697386)))),
                                        ],
                                      ),
                                    ),
                                    if (_logs.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(48),
                                        child: Text('No security events logged yet.', style: theme.textTheme.bodySmall),
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _logs.length,
                                        separatorBuilder: (context, index) => Divider(
                                          height: 1,
                                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                        itemBuilder: (context, index) {
                                          final log = _logs[index];
                                          final date = log['created_at'] != null 
                                              ? log['created_at'].toString().split('T')[0] + ' ' + 
                                                log['created_at'].toString().split('T')[1].substring(0, 5)
                                              : 'Recently';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    log['event_type'] ?? 'Unknown Event',
                                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    log['ip_address'] ?? 'N/A',
                                                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    date,
                                                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
