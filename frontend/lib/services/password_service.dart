import 'dart:convert';
import 'api_client.dart';

class PasswordService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getPasswords() async {
    final response = await _api.get('/passwords');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch passwords';
    }
  }

  Future<void> addPassword(Map<String, dynamic> data) async {
    final response = await _api.post('/passwords', data);
    if (response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to add password';
    }
  }

  Future<void> updatePassword(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/passwords/$id', data);
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update password';
    }
  }

  Future<void> deletePassword(int id) async {
    final response = await _api.delete('/passwords/$id');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete password';
    }
  }
}
