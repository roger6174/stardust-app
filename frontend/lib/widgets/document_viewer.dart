import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:animate_do/animate_do.dart';
import 'dart:ui' as ui;
import '../theme.dart';
import '../services/upload_service.dart';

class DocumentViewer extends StatefulWidget {
  final String title;
  final String? filePath; // Can be a local path or a URL
  final String? fileKey;  // S3 key for presigned URL fetching
  final String? date;
  final String? status;

  const DocumentViewer({
    super.key,
    required this.title,
    this.filePath,
    this.fileKey,
    this.date,
    this.status,
  });

  /// Show the viewer as a full-screen overlay
  static void show(BuildContext context, {
    required String title,
    String? filePath,
    String? fileKey,
    String? date,
    String? status,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: DocumentViewer(
              title: title,
              filePath: filePath,
              fileKey: fileKey,
              date: date,
              status: status,
            ),
          );
        },
      ),
    );
  }

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  final UploadService _uploadService = UploadService();
  String? _displayUrl;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveFilePath();
  }

  Future<void> _resolveFilePath() async {
    if (widget.fileKey != null && widget.fileKey!.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final url = await _uploadService.getViewUrl(widget.fileKey!);
        if (mounted) {
          setState(() {
            _displayUrl = url;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch secure URL: $e';
            _isLoading = false;
            // Fallback to filePath if key fails
            _displayUrl = widget.filePath;
          });
        }
      }
    } else {
      setState(() {
        _displayUrl = widget.filePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContent = _displayUrl != null && _displayUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.3),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping content
                child: Column(
                  children: [
                    _header(context, theme),
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : (hasContent ? _imageViewer(context, theme) : _noFileState(theme)),
                    ),
                    _footer(context, theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ThemeData theme) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, AppSpacing.medium, AppSpacing.medium, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.date != null)
                    Text(
                      'Added on ${widget.date}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.status != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(widget.status!).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor(widget.status!).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.status!,
                  style: TextStyle(
                    color: _statusColor(widget.status!),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageViewer(BuildContext context, ThemeData theme) {
    bool isNetwork = _displayUrl!.startsWith('http');
    
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isNetwork || kIsWeb
                    ? Image.network(
                        _displayUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _errorState(theme),
                      )
                    : Image.file(
                        File(_displayUrl!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _errorState(theme),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noFileState(ThemeData theme) {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xlarge),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              widget.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _error ?? 'No preview available for this document.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            if (widget.date != null) ...[
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Added on ${widget.date}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.huge),
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'Unable to load image',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, ThemeData theme) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_displayUrl != null) ...[
              _footerHint(Icons.pinch_rounded, 'Pinch to zoom'),
              const SizedBox(width: AppSpacing.xlarge),
            ],
            _footerHint(Icons.touch_app_outlined, 'Tap outside to close'),
          ],
        ),
      ),
    );
  }

  Widget _footerHint(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'signed':
      case 'verified':
        return Colors.greenAccent;
      case 'vaulted':
        return Colors.cyanAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }
}
