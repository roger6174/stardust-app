/// Category schema models for the Stardust Vault.
/// These mirror the backend category_schemas.js structure.
/// Used to dynamically generate forms and render asset details.
import 'dart:ui' show Color;

enum FieldType { text, password, currency, select, date, file, email, phone, textarea }

class FieldSchema {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final String placeholder;
  final List<String> options;

  const FieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder = '',
    this.options = const [],
  });

  factory FieldSchema.fromJson(Map<String, dynamic> json) {
    return FieldSchema(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      type: _parseFieldType(json['type']),
      required: json['required'] ?? false,
      placeholder: json['placeholder'] ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static FieldType _parseFieldType(String? type) {
    switch (type) {
      case 'text':     return FieldType.text;
      case 'password': return FieldType.password;
      case 'currency': return FieldType.currency;
      case 'select':   return FieldType.select;
      case 'date':     return FieldType.date;
      case 'file':     return FieldType.file;
      case 'email':    return FieldType.email;
      case 'phone':    return FieldType.phone;
      case 'textarea': return FieldType.textarea;
      default:         return FieldType.text;
    }
  }
}

class ParentCategory {
  final String key;
  final String label;
  final String icon;
  final String color;

  const ParentCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? 'folder',
      color: json['color'] ?? '#2563EB',
    );
  }

  Color get parsedColor {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class CategorySchema {
  final String key;
  final String? parent;
  final String label;
  final String icon;
  final String description;
  final String color;
  final List<FieldSchema> fields;

  const CategorySchema({
    required this.key,
    this.parent,
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
    required this.fields,
  });

  factory CategorySchema.fromJson(Map<String, dynamic> json) {
    return CategorySchema(
      key: json['key'] ?? '',
      parent: json['parent'],
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#2563EB',
      fields: (json['fields'] as List<dynamic>?)
          ?.map((f) => FieldSchema.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Get all fields for the form — file fields appear last so camera/upload shows after text inputs
  List<FieldSchema> get formFields {
    final nonFile = fields.where((f) => f.type != FieldType.file).toList();
    final file = fields.where((f) => f.type == FieldType.file).toList();
    return [...nonFile, ...file];
  }

  /// Get file upload fields
  List<FieldSchema> get fileFields => fields.where((f) => f.type == FieldType.file).toList();

  /// Get required fields
  List<FieldSchema> get requiredFields => fields.where((f) => f.required).toList();

  /// Parse hex color string to Color
  Color get parsedColor {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class VaultSchemaResponse {
  final Map<String, ParentCategory> parents;
  final Map<String, CategorySchema> categories;

  const VaultSchemaResponse({
    required this.parents,
    required this.categories,
  });

  factory VaultSchemaResponse.fromJson(Map<String, dynamic> json) {
    final parentsJson = json['parents'] as Map<String, dynamic>? ?? {};
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};

    return VaultSchemaResponse(
      parents: parentsJson.map((k, v) => MapEntry(k, ParentCategory.fromJson(v))),
      categories: categoriesJson.map((k, v) => MapEntry(k, CategorySchema.fromJson(v))),
    );
  }
}
