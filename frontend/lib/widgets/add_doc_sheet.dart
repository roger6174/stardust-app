import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'gradient_button.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme.dart';
import '../services/upload_service.dart';
import '../utils/scanner_interface.dart'
    if (dart.library.io) '../utils/scanner_mobile.dart'
    if (dart.library.html) '../utils/scanner_web.dart' as scanner;

class AddDocSheet extends StatefulWidget {
  final String type;
  final Function(String title, String? fileKey, String? fileUrl) onAdd;
  final XFile? initialFile;

  const AddDocSheet({
    super.key,
    required this.type,
    required this.onAdd,
    this.initialFile,
  });

  @override
  State<AddDocSheet> createState() => _AddDocSheetState();
}

class _AddDocSheetState extends State<AddDocSheet> {
  final _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final UploadService _uploadService = UploadService();
  XFile? _pickedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _pickedFile = widget.initialFile;
      _populateTitleFromFilename();
    }
  }

  void _populateTitleFromFilename() {
    if (_pickedFile == null) return;
    final nameParts = _pickedFile!.name.split('.');
    if (nameParts.isNotEmpty) {
      final baseName = nameParts[0].replaceAll(RegExp(r'[-_]'), ' ');
      _titleController.text = baseName.split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }
  }

  Future<void> _handleUpload() async {
    if (_pickedFile == null || _titleController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final result = await _uploadService.uploadFile(
        _pickedFile!, 
        folder: widget.type.toLowerCase(),
      );
      
      widget.onAdd(_titleController.text, result.key, result.location);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  /// Launch the native document scanner (camera → edge detection → auto-crop)
  Future<void> _scanDocument() async {
    if (!kIsWeb) {
      try {
        final scannerInstance = scanner.getScanner();
        final XFile? scannedFile = await scannerInstance.scanDocument(widget.type);

        if (scannedFile != null) {
          setState(() {
            _pickedFile = scannedFile;
          });
          _populateTitleFromFilename();
          if (_titleController.text.isEmpty) {
            _titleController.text = '${widget.type} Scan ${DateTime.now().day}/${DateTime.now().month}';
          }
          return;
        }
      } catch (e) {
        debugPrint('Document Scanner Error: $e');
      }
    }

    // Fallback: open camera directly via image_picker
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _pickedFile = image;
        });
        if (_titleController.text.isEmpty) {
          _titleController.text = '${widget.type} Scan ${DateTime.now().day}/${DateTime.now().month}';
        }
      }
    } catch (e) {
      debugPrint('Camera fallback error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _pickedFile = image;
        });
        _populateTitleFromFilename();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upload ${widget.type} Document',
                            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
                        Text('Securely vault your files',
                            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isUploading)
                _uploadingState()
              else ...[
                TextField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  enabled: !_isUploading,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Document Title',
                    hintText: 'e.g. ${widget.type} Policy 2025',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                if (_pickedFile != null)
                  _imagePreview()
                else
                  _selectionOptions(),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Vault to Cloud',
                  onPressed: (_pickedFile != null && _titleController.text.isNotEmpty && !_isUploading)
                      ? _handleUpload
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.medium),
          Text('Securing document in vault...', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          Text('This file is being encrypted and stored in S3', 
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    final theme = Theme.of(context);
    return FadeIn(
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                  : Image.network(_pickedFile!.path, fit: BoxFit.cover), // XFile handles this across platforms
            ),
            if (!_isUploading)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => setState(() {
                    _pickedFile = null;
                    _titleController.clear();
                  }),
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: AppSpacing.medium),
                color: Colors.black.withValues(alpha: 0.6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File selected: ${_pickedFile!.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionOptions() {
    return Row(
      children: [
        Expanded(
          child: _optionButton(
            icon: Icons.document_scanner_rounded,
            label: 'Scan Document',
            onTap: _scanDocument,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: _optionButton(
            icon: Icons.upload_file_rounded,
            label: 'Upload File',
            onTap: _pickFromGallery,
          ),
        ),
      ],
    );
  }

  Widget _optionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.small),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
