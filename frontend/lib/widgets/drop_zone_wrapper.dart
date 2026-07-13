import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:animate_do/animate_do.dart';
import '../theme.dart';

class DropZoneWrapper extends StatefulWidget {
  final Widget child;
  final Function(XFile) onDrop;

  const DropZoneWrapper({
    super.key,
    required this.child,
    required this.onDrop,
  });

  @override
  State<DropZoneWrapper> createState() => _DropZoneWrapperState();
}

class _DropZoneWrapperState extends State<DropZoneWrapper> {
  bool _isHovering = false;

  bool _isComputer(BuildContext context) {
    if (kIsWeb) {
      // On web, consider it a computer if the width is desktop-class (>= 800px)
      return MediaQuery.sizeOf(context).width >= 800;
    }
    // On native, check for desktop platforms
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final bool isComputer = _isComputer(context);
    final theme = Theme.of(context);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isHovering = true),
      onDragExited: (details) => setState(() => _isHovering = false),
      onDragDone: (details) {
        setState(() => _isHovering = false);
        if (details.files.isNotEmpty) {
          widget.onDrop(details.files.first);
        }
      },
      child: Stack(
        children: [
          widget.child,
          // ─── Permanent Hint Layer (Watermark) ───
          if (isComputer)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeIn(
                  duration: const Duration(seconds: 2),
                  child: Opacity(
                    opacity: 0.08, 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 200,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          'Drag & Drop Zone',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isHovering && isComputer)
            _buildDropOverlay(),
        ],
      ),
    );
  }

  Widget _buildDropOverlay() {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: FadeIn(
        duration: const Duration(milliseconds: 200),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'Drop to Vault',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Release your files to securely upload them',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
