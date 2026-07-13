import 'dart:convert';
import 'api_client.dart';

class InsuranceService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getInsurance() async {
    final response = await _api.get('/insurance');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch insurance';
    }
  }

  Future<void> addInsurance(Map<String, dynamic> data) async {
    final response = await _api.post('/insurance', data);
    if (response.statusCode != 201) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to add insurance';
    }
  }

  Future<void> updateInsurance(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/insurance/$id', data);
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update insurance';
    }
  }

  Future<void> deleteInsurance(int id) async {
    final response = await _api.delete('/insurance/$id');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete insurance';
    }
  }
}
