import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _api = ApiClient();

  // ─── Profile & Policy ───
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/auth/profile');
    return jsonDecode(response.body);
  }

  Future<void> updateVaultPolicy({required int triggerPeriod, required int reminderInterval}) async {
    await _api.put('/auth/vault-policy', {
      'inactivity_trigger_period': triggerPeriod,
      'reminder_interval': reminderInterval,
    });
  }

  // ─── Nominee Discovery ───
  Future<List<dynamic>> getNomineeOpportunities() async {
    final response = await _api.get('/auth/nominee-opportunities');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> linkNomineeAccount(int nomineeId, String securityCode) async {
    final response = await _api.post('/auth/link-account', {
      'nomineeId': nomineeId,
      'securityCode': securityCode,
    });
    return jsonDecode(response.body);
  }

  // ─── Succession Claims ───
  Future<List<dynamic>> getInheritedAccounts() async {
    final response = await _api.get('/succession/inherited-accounts');
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMyClaims() async {
    final response = await _api.get('/succession/my-claims');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getApprovedSecurityCode(int targetUserId) async {
    final response = await _api.get('/succession/approved-code?targetUserId=$targetUserId');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> submitManualClaim({
    required int targetUserId,
    required int nomineeId,
    required PlatformFile file,
  }) async {
    final token = await _api.getToken();
    final uri = Uri.parse('${_api.baseUrl}/succession/submit-claim');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });
    
    request.fields['targetUserId'] = targetUserId.toString();
    request.fields['nomineeId'] = nomineeId.toString();
    
    request.files.add(http.MultipartFile.fromBytes(
      'proof',
      file.bytes!,
      filename: file.name,
    ));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }
}
