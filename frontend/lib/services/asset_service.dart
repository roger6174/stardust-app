import 'dart:convert';
import 'api_client.dart';

class AssetService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getAssets({String? category}) async {
    final endpoint = category != null ? '/assets?category=$category' : '/assets';
    final response = await _api.get(endpoint);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to fetch assets';
    }
  }

  Future<Map<String, dynamic>> addAsset(Map<String, dynamic> assetData) async {
    final response = await _api.post('/assets', assetData);
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw jsonDecode(response.body)['message'] ?? 'Failed to add asset';
    }
  }

  Future<void> updateAsset(int id, Map<String, dynamic> assetData) async {
    final response = await _api.put('/assets/$id', assetData);
    
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update asset';
    }
  }

  Future<void> deleteAsset(int id) async {
    final response = await _api.delete('/assets/$id');
    
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete asset';
    }
  }
}
