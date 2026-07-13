import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';

class SuccessionClaimScreen extends StatefulWidget {
  final dynamic vault;

  const SuccessionClaimScreen({super.key, required this.vault});

  @override
  State<SuccessionClaimScreen> createState() => _SuccessionClaimScreenState();
}

class _SuccessionClaimScreenState extends State<SuccessionClaimScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String _status = 'NOT_STARTED';
  String? _securityCode;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final claims = await _api.getMyClaims();
      final claim = claims.firstWhere((c) => c['owner_id'] == widget.vault['user_id'], orElse: () => null);
      
      if (claim != null) {
        _status = claim['status'];
        if (_status == 'APPROVED') {
          final codeRes = await _api.getApprovedSecurityCode(widget.vault['user_id']);
          _securityCode = codeRes['security_code'];
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error checking claim status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submitClaim() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.submitManualClaim(
        targetUserId: widget.vault['user_id'],
        nomineeId: widget.vault['nominee_id'],
        file: _selectedFile!,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      _checkStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit claim: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.vault['full_name'] ?? 'Vault Claim', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F1A2E), const Color(0xFF0A101D)]
              : [const Color(0xFFF0F4F8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   _statusHeader(),
                   const SizedBox(height: 32),
                   if (_status == 'NOT_STARTED') _buildInitiationForm(),
                   if (_status == 'PENDING') _buildPendingState(),
                   if (_status == 'APPROVED') _buildApprovedState(),
                   if (_status == 'REJECTED') _buildRejectedState(),
                ],
              ),
        ),
      ),
    );
  }

  Widget _statusHeader() {
    Color statusColor;
    String statusDesc;
    IconData statusIcon;

    switch (_status) {
      case 'APPROVED': 
        statusColor = Colors.green; statusIcon = Icons.check_circle_rounded; 
        statusDesc = 'Succession claim approved for vault handover.'; break;
      case 'PENDING': 
        statusColor = Colors.orange; statusIcon = Icons.hourglass_empty_rounded; 
        statusDesc = 'Claim document is currently under manual review.'; break;
      case 'REJECTED': 
        statusColor = Colors.red; statusIcon = Icons.error_outline_rounded; 
        statusDesc = 'Handover request was rejected due to missing documentation.'; break;
      default: 
        statusColor = AppTheme.primaryBlue; statusIcon = Icons.security_rounded; 
        statusDesc = 'You are a listed nominee for this vault. Proof of succession is required for secure access.';
    }

    return Column(
      children: [
        Icon(statusIcon, size: 64, color: statusColor).animate().scale().fadeIn(),
        const SizedBox(height: 16),
        Text(_status.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(statusDesc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildInitiationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit Succession Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'To process the legacy transition, please upload a verified copy of the death certificate or a legal court order granting vault access.',
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _pickFile,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.none),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: DashedBorderPainter(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded, color: AppTheme.primaryBlue, size: 32),
                        const SizedBox(height: 8),
                        Text(_selectedFile?.name ?? 'Select PDF or Image', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedFile == null ? null : _submitClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Initiate Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildPendingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
             Icon(Icons.info_outline_rounded, color: Colors.orange),
             SizedBox(height: 12),
             Text(
               'Your request is in the "Verification Queue". We manually verify all succession documents within 12-24 hours for security.',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.orange, height: 1.5),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Text('Master PIN Revealed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _securityCode ?? 'PENDING...',
                  style: const TextStyle(color: Colors.white, letterSpacing: 6, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Use this code to unlock the vault and export secure documents.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ).animate().shimmer(duration: 2.seconds).scale(),
        const SizedBox(height: 32),
        const Text(
          'Security Note: This code provides full administrative access to the vault. Please treat it with ultimate confidentiality.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildRejectedState() {
    return Column(
      children: [
        const Text('The claim was rejected. Please re-upload with correct documentation.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _status = 'NOT_STARTED'),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)));

    var dashedPath = Path();
    double dashWidth = 8, dashSpace = 6, distance = 0;
    for (var i in path.computeMetrics()) {
      while (distance < i.length) {
        dashedPath.addPath(i.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
