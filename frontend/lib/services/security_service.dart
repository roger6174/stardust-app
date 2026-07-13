import 'dart:convert';
import 'api_client.dart';

class SecurityService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getLogs() async {
    final response = await _apiClient.get('/security-logs');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}
