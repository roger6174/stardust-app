import '../../widgets/animated_list_wrapper.dart';
import '../../widgets/document_viewer.dart';
import '../../theme.dart';
import '../../services/others_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/drop_zone_wrapper.dart';
import '../../widgets/add_doc_sheet.dart';
import '../../widgets/login_prompt.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/success_animation.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stardust_background.dart';
import 'package:flutter/material.dart';

class OthersScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isGuest;
  const OthersScreen({super.key, this.onBack, this.isGuest = false});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
  final OthersService _othersService = OthersService();
  List<Map<String, dynamic>> _others = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _fetchOthers();
    }
  }

  Future<void> _fetchOthers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final others = await _othersService.getDocuments();
      setState(() {
        _others = others;
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

  void _addDoc() {
    if (widget.isGuest) {
      LoginRequiredPrompt.show(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddDocSheet(
        type: 'Others',
        onAdd: (title, fileKey, fileUrl) async {
          try {
            await _othersService.addDocument({
              'title': title,
              'description': 'Miscellaneous document',
              'status': 'Vaulted',
              'file_path': fileUrl ?? '',
              'metadata': {
                'file_key': fileKey,
                'file_url': fileUrl,
              },
            });
            _fetchOthers();
            if (mounted) SuccessAnimationOverlay.show(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save document: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
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
        type: 'Others',
        initialFile: file,
        onAdd: (title, fileKey, fileUrl) async {
          try {
            await _othersService.addDocument({
              'title': title,
              'description': 'Dropped file',
              'status': 'Vaulted',
              'file_path': fileUrl ?? '',
              'metadata': {
                'file_key': fileKey,
                'file_url': fileUrl,
              },
            });
            _fetchOthers();
            if (mounted) SuccessAnimationOverlay.show(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save document: $e'), backgroundColor: Colors.redAccent),
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
                          : _others.isEmpty
                              ? _emptyState()
                              : RefreshIndicator(
                                  onRefresh: _fetchOthers,
                                  child: AnimatedListWrapper(
                                    padding: const EdgeInsets.all(AppSpacing.edge),
                                    children: _others.map((d) {
                                      final date = d['created_at'] != null 
                                          ? d['created_at'].toString().split('T')[0] 
                                          : 'Recently';
                                          
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: GlassCard(
                                          onTap: () => DocumentViewer.show(
                                            context,
                                            title: d['title'] ?? 'Document',
                                            fileKey: d['metadata']?['file_key'],
                                            filePath: d['metadata']?['file_url'] ?? d['file_path'],
                                            date: date,
                                            status: d['status'] ?? 'Vaulted',
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.folder_open_rounded,
                                                  color: theme.colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(d['title'] ?? 'Miscellaneous',
                                                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                                                    Text('Added on $date',
                                                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF697386))),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  d['status'] ?? 'Vaulted',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                      color: theme.colorScheme.primary,
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ),
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
        onPressed: _addDoc,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
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
          Text('Others',
              style: isMobile ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.medium),
          Text('No documents added',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
          const SizedBox(height: AppSpacing.small),
          Text('Drop files here or tap + to upload miscellaneous documents',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3))),
          if (!widget.isGuest) ...[
            const SizedBox(height: AppSpacing.medium),
            TextButton(onPressed: _fetchOthers, child: const Text('Refresh')),
          ],
        ],
      ),
    );
  }
}
