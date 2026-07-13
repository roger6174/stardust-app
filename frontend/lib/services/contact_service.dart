import 'dart:convert';
import 'api_client.dart';

class ContactService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getContacts() async {
    final response = await _api.get('/contacts');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch contacts';
    }
  }

  Future<void> addContact(Map<String, dynamic> data) async {
    final response = await _api.post('/contacts', data);
    if (response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to add contact';
    }
  }

  Future<void> updateContact(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/contacts/$id', data);
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update contact';
    }
  }

  Future<void> deleteContact(int id) async {
    final response = await _api.delete('/contacts/$id');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete contact';
    }
  }
}
