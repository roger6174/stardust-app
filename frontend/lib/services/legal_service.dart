import 'dart:convert';
import 'api_client.dart';

class LegalService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getDocuments() async {
    final response = await _api.get('/legal');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch documents';
    }
  }

  Future<void> addDocument(Map<String, dynamic> data) async {
    final response = await _api.post('/legal', data);
    if (response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to add document';
    }
  }

  Future<void> updateDocument(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/legal/$id', data);
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update document';
    }
  }

  Future<void> deleteDocument(int id) async {
    final response = await _api.delete('/legal/$id');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete document';
    }
  }
}
