import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../config.dart';

class UploadResult {
  final String key;
  final String location;

  UploadResult({required this.key, required this.location});
}

class UploadService {
  static final String _baseUrl = '${AppConfig.baseUrl}/uploads';
  final AuthService _authService = AuthService();

  Future<UploadResult> uploadFile(XFile file, {String folder = 'documents'}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = folder;
    
    // Read bytes for universal compatibility (Web/Mobile)
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file', 
      bytes,
      filename: file.name,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UploadResult(
        key: data['file_key'],
        location: data['location'],
      );
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  Future<String> getViewUrl(String key) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.get(
      Uri.parse('$_baseUrl/view?key=$key'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      throw Exception('Failed to get view URL');
    }
  }
}
