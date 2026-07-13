import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/upload_service.dart';
import '../utils/scanner_interface.dart'
    if (dart.library.io) '../utils/scanner_mobile.dart'
    if (dart.library.html) '../utils/scanner_web.dart' as scanner;
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';

import '../models/category_schema.dart';
import 'gradient_button.dart';
import '../theme.dart';
import '../screens/document_enhance_screen.dart';

class SchemaDrivenForm extends StatefulWidget {
  final CategorySchema schema;
  final Function(Map<String, dynamic> data) onSubmit;
  final Map<String, dynamic>? initialData;

  const SchemaDrivenForm({
    super.key,
    required this.schema,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<SchemaDrivenForm> createState() => _SchemaDrivenFormState();
}

class _SchemaDrivenFormState extends State<SchemaDrivenForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, XFile?> _fileValues = {};
  final UploadService _uploadService = UploadService();
  int _currentStep = 0;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  late List<List<FieldSchema>> _steps;

  @override
  void initState() {
    super.initState();
    _buildSteps();
    _initControllers();
  }

  void _buildSteps() {
    final formFields = widget.schema.formFields;
    _steps = [];
    for (int i = 0; i < formFields.length; i += 3) {
      final end = (i + 3 > formFields.length) ? formFields.length : i + 3;
      _steps.add(formFields.sublist(i, end));
    }
    if (_steps.isEmpty) _steps.add([]);
  }

  void _initControllers() {
    for (final field in widget.schema.fields) {
      _focusNodes[field.key] = FocusNode();
      _focusNodes[field.key]!.addListener(() => setState(() {}));

      if (field.type == FieldType.select) {
        _selectValues[field.key] = widget.initialData?[field.key]?.toString();
      } else if (field.type != FieldType.file) {
        _controllers[field.key] = TextEditingController(
          text: widget.initialData?[field.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  Map<String, dynamic> _collectData() {
    final data = <String, dynamic>{};
    for (final field in widget.schema.fields) {
      if (field.type == FieldType.select) {
        data[field.key] = _selectValues[field.key] ?? '';
      } else if (field.type == FieldType.file) {
        data[field.key] = _fileValues[field.key]?.path ?? '';
      } else {
        data[field.key] = _controllers[field.key]?.text ?? '';
      }
    }
    return data;
  }

  bool _validateCurrentStep() {
    if (_currentStep >= _steps.length) return true;
    for (final field in _steps[_currentStep]) {
      if (field.required) {
        if (field.type == FieldType.select) {
          if (_selectValues[field.key] == null || _selectValues[field.key]!.isEmpty) return false;
        } else if (field.type != FieldType.file) {
          if (_controllers[field.key]?.text.isEmpty ?? true) return false;
        }
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      _formKey.currentState?.validate();
      return;
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() => setState(() => _currentStep > 0 ? _currentStep-- : null);

  Future<void> _submit() async {
    if (!_validateCurrentStep()) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final data = _collectData();
      for (final field in widget.schema.fields) {
        if (field.type == FieldType.file && _fileValues[field.key] != null) {
          final result = await _uploadService.uploadFile(
            _fileValues[field.key]!,
            folder: widget.schema.key.toLowerCase(),
          );
          data[field.key] = result.key; 
        }
      }
      await widget.onSubmit(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _currentStep >= _steps.length - 1;
    final categoryColor = widget.schema.parsedColor;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),

                    _buildHeader(theme, categoryColor),
                    const SizedBox(height: 24),
                    
                    if (_steps.length > 1) ..._buildStepIndicator(theme, categoryColor),
                    
                    const SizedBox(height: 24),

                    // ─── Form Card ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: _buildCurrentStepFields(theme, categoryColor),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        if (_currentStep > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              ),
                              child: Text('Back', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            text: _isSubmitting ? 'Securing Item...' : (isLastStep ? 'Vault Item' : 'Next Step'),
                            onPressed: _isSubmitting ? null : _nextStep,
                            icon: isLastStep ? Icons.verified_user_rounded : Icons.arrow_forward_ios_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color categoryColor) {
    return Row(
      children: [
        FadeInLeft(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [categoryColor, categoryColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: categoryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(AppTheme.categoryIcons[widget.schema.key] ?? Icons.folder_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialData != null ? 'Edit ${widget.schema.label}' : 'New ${widget.schema.label}', 
                   style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text(widget.schema.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
      ],
    );
  }

  List<Widget> _buildStepIndicator(ThemeData theme, Color categoryColor) {
    return [
      Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == _currentStep;
          final isCompleted = i < _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _steps.length - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? categoryColor : (isCompleted ? categoryColor.withValues(alpha: 0.4) : theme.colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isActive ? [BoxShadow(color: categoryColor.withValues(alpha: 0.3), blurRadius: 4)] : [],
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('PROGRESS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
          Text('${_currentStep + 1} / ${_steps.length}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: categoryColor)),
        ],
      ),
    ];
  }

  List<Widget> _buildCurrentStepFields(ThemeData theme, Color categoryColor) {
    if (_currentStep >= _steps.length) return [];
    return _steps[_currentStep].map((field) => Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildField(field, theme, categoryColor))).toList();
  }

  Widget _buildField(FieldSchema field, ThemeData theme, Color categoryColor) {
    switch (field.type) {
      case FieldType.file: return _buildFilePicker(field, theme, categoryColor);
      case FieldType.select: return _buildSelectField(field, theme, categoryColor);
      case FieldType.date: return _buildDateField(field, theme, categoryColor);
      case FieldType.password: return _buildPasswordField(field, theme, categoryColor);
      case FieldType.currency: return _buildCurrencyField(field, theme, categoryColor);
      case FieldType.textarea: return _buildTextArea(field, theme, categoryColor);
      default: return _buildTextField(field, theme, categoryColor);
    }
  }

  InputDecoration _inputDecoration(FieldSchema field, ThemeData theme, Color categoryColor) {
    final focusNode = _focusNodes[field.key];
    final isFocused = focusNode?.hasFocus ?? false;
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: field.label,
      hintText: field.placeholder,
      labelStyle: TextStyle(color: isFocused ? categoryColor : theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: isFocused ? FontWeight.w700 : FontWeight.w500),
      floatingLabelStyle: TextStyle(color: categoryColor, fontWeight: FontWeight.w900),
      prefixIconColor: isFocused ? categoryColor : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fillColor: isFocused 
          ? categoryColor.withValues(alpha: isDark ? 0.08 : 0.04) 
          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
      filled: true,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: categoryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
    );
  }

  Widget _buildTextField(FieldSchema field, ThemeData theme, Color categoryColor, {TextInputType? keyboardType}) {
    return FadeIn(
      child: TextFormField(
        controller: _controllers[field.key],
        focusNode: _focusNodes[field.key],
        keyboardType: keyboardType,
        decoration: _inputDecoration(field, theme, categoryColor),
        validator: field.required ? (v) => (v == null || v.isEmpty) ? '${field.label} is required' : null : null,
      ),
    );
  }

  Widget _buildTextArea(FieldSchema field, ThemeData theme, Color categoryColor) {
    return FadeIn(
      child: TextFormField(
        controller: _controllers[field.key],
        focusNode: _focusNodes[field.key],
        maxLines: 3,
        decoration: _inputDecoration(field, theme, categoryColor).copyWith(alignLabelWithHint: true),
        validator: field.required ? (v) => (v == null || v.isEmpty) ? '${field.label} is required' : null : null,
      ),
    );
  }

  bool _obscureText = true;
  Widget _buildPasswordField(FieldSchema field, ThemeData theme, Color categoryColor) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FadeIn(
          child: TextFormField(
            controller: _controllers[field.key],
            focusNode: _focusNodes[field.key],
            obscureText: _obscureText,
            decoration: _inputDecoration(field, theme, categoryColor).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                onPressed: () => setLocalState(() => _obscureText = !_obscureText),
              ),
            ),
            validator: field.required ? (v) => (v == null || v.isEmpty) ? '${field.label} is required' : null : null,
          ),
        );
      },
    );
  }

  Widget _buildCurrencyField(FieldSchema field, ThemeData theme, Color categoryColor) {
    return FadeIn(
      child: TextFormField(
        controller: _controllers[field.key],
        focusNode: _focusNodes[field.key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: _inputDecoration(field, theme, categoryColor).copyWith(
          prefixText: '₹ ',
          prefixStyle: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900, color: categoryColor),
        ),
      ),
    );
  }

  Widget _buildSelectField(FieldSchema field, ThemeData theme, Color categoryColor) {
    return FadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              if (field.required) Text(' *', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: field.options.map((option) {
              final isSelected = _selectValues[field.key] == option;
              return GestureDetector(
                onTap: () => setState(() => _selectValues[field.key] = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? categoryColor.withValues(alpha: 0.15) : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? categoryColor : theme.colorScheme.outline.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: categoryColor.withValues(alpha: 0.1), blurRadius: 8)] : [],
                  ),
                  child: Text(option, style: theme.textTheme.bodyMedium?.copyWith(color: isSelected ? categoryColor : theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(FieldSchema field, ThemeData theme, Color categoryColor) {
    return FadeIn(
      child: GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(data: theme.copyWith(colorScheme: theme.colorScheme.copyWith(primary: categoryColor)), child: child!),
          );
          if (date != null) {
            setState(() => _controllers[field.key]?.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _controllers[field.key],
            decoration: _inputDecoration(field, theme, categoryColor).copyWith(
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: categoryColor),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enhanceAndSetFile(FieldSchema field, XFile file) async {
    final enhancedFile = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEnhanceScreen(
          image: file,
          category: field.label,
        ),
      ),
    );
    
    if (enhancedFile != null && mounted) {
      setState(() => _fileValues[field.key] = enhancedFile);
    }
  }

  Widget _buildFilePicker(FieldSchema field, ThemeData theme, Color categoryColor) {
    final file = _fileValues[field.key];
    final hasFile = file != null;
    final isDark = theme.brightness == Brightness.dark;

    return FadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              if (field.required) Text(' *', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showPickerOptions(field),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(hasFile ? 16 : 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasFile ? categoryColor.withValues(alpha: 0.05) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: hasFile ? categoryColor : theme.colorScheme.outline.withValues(alpha: 0.1), width: hasFile ? 2 : 1),
                boxShadow: hasFile ? [BoxShadow(color: categoryColor.withValues(alpha: 0.1), blurRadius: 10)] : [],
              ),
              child: hasFile 
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60, height: 60,
                          color: categoryColor.withValues(alpha: 0.1),
                          child: (file!.name.endsWith('.pdf')) 
                            ? Icon(Icons.picture_as_pdf_rounded, color: categoryColor, size: 30)
                            : Image.file(File(file.path), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Securely attached', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => setState(() => _fileValues[field.key] = null), icon: const Icon(Icons.delete_outline_rounded, color: Colors.orange)),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.add_a_photo_rounded, color: categoryColor, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text('Click to Capture / Upload', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: categoryColor)),
                      Text('PDF, JPG or PNG supported', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(FieldSchema field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryBlue),
              title: const Text('Scan Document', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Auto-crop and edge detection'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  // Try the document scanner first (real device only)
                  final scannerInstance = scanner.getScanner();
                  final file = await scannerInstance.scanDocument(field.label);
                  if (file != null && mounted) _enhanceAndSetFile(field, file);
                } catch (e) {
                  // Fallback: use camera directly or gallery on simulator
                  try {
                    final file = await _picker.pickImage(source: ImageSource.camera);
                    if (file != null && mounted) _enhanceAndSetFile(field, file);
                  } catch (_) {
                    // No camera (simulator) — fall back to gallery
                    if (!mounted) return;
                    final file = await _picker.pickImage(source: ImageSource.gallery);
                    if (file != null && mounted) _enhanceAndSetFile(field, file);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.cloud_upload_rounded, color: Colors.green),
              title: const Text('Upload from Device', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Select existing file or photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null && mounted) _enhanceAndSetFile(field, file);
              },
            ),
          ],
        ),
      ),
    );
  }
}
