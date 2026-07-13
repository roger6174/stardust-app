import 'dart:convert';
import 'api_client.dart';
import '../models/category_schema.dart';

/// Unified vault service — replaces asset_service, insurance_service,
/// password_service, legal_service, contact_service, others_service.
class VaultService {
  final ApiClient _api = ApiClient();

  // ─── Schemas ───

  /// Fetch all category schemas from backend (for dynamic form generation)
  Future<VaultSchemaResponse> getSchemas() async {
    final response = await _api.get('/vault/schemas');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return VaultSchemaResponse.fromJson(data);
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch schemas';
    }
  }

  // ─── Summary ───

  /// Get dashboard summary (item counts per category and parent)
  Future<Map<String, dynamic>> getSummary() async {
    final response = await _api.get('/vault/summary');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch summary';
    }
  }

  // ─── Search ───

  /// Cross-category search
  Future<List<Map<String, dynamic>>> search(String query) async {
    final response = await _api.get('/vault/search?q=${Uri.encodeQueryComponent(query)}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Search failed';
    }
  }

  // ─── Category CRUD ───

  /// Get all items in a category
  Future<List<Map<String, dynamic>>> getItems(String category) async {
    final response = await _api.get('/vault/$category');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch $category';
    }
  }

  /// Get single item detail
  Future<Map<String, dynamic>> getItem(String category, int id) async {
    final response = await _api.get('/vault/$category/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch item';
    }
  }

  /// Add new item to a category
  Future<Map<String, dynamic>> addItem(String category, Map<String, dynamic> metadata) async {
    final response = await _api.post('/vault/$category', {
      'metadata': metadata,
      'is_encrypted': 1,
    });
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      final errors = body['errors'];
      if (errors != null && errors is List) {
        throw errors.join(', ');
      }
      throw body['message'] ?? 'Failed to add item';
    }
  }

  /// Update an existing item
  Future<void> updateItem(String category, int id, Map<String, dynamic> metadata) async {
    final response = await _api.put('/vault/$category/$id', {
      'metadata': metadata,
      'is_encrypted': 1,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update item';
    }
  }

  /// Delete an item
  Future<void> deleteItem(String category, int id) async {
    final response = await _api.delete('/vault/$category/$id');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete item';
    }
  }

  /// AI-powered feature: Fetch benefits for a credit card
  Future<List<String>> fetchCardBenefits(int id) async {
    final response = await _api.post('/vault/cards/$id/benefits', {});
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> benefits = data['benefits'] ?? [];
      return benefits.cast<String>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch benefits';
    }
  }
}
