import 'dart:convert';
import 'api_client.dart';

class NomineeService {
  final ApiClient _api = ApiClient();

  /// Get all nominees for the current user
  Future<List<Map<String, dynamic>>> getNominees() async {
    final response = await _api.get('/auth/nominee');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> nominees = data['nominees'] ?? [];
      return nominees.cast<Map<String, dynamic>>();
    }
    throw jsonDecode(response.body)['message'] ?? 'Failed to fetch nominees';
  }

  /// Add or update a nominee
  Future<void> saveNominee({
    required String fullName,
    required String mobile,
    required String relationship,
    String countryCode = '+91',
  }) async {
    final response = await _api.post('/auth/nominee', {
      'full_name': fullName,
      'mobile': mobile,
      'relationship': relationship,
      'country_code': countryCode,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to save nominee';
    }
  }

  /// Send email OTP to verify nominee's email
  Future<void> sendNomineeEmailOTP(String email) async {
    final response = await _api.post('/auth/nominee/send-email-otp', {
      'email': email,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to send OTP';
    }
  }

  /// Verify nominee email OTP
  Future<void> verifyNomineeEmailOTP(String otp, String email) async {
    final response = await _api.post('/auth/nominee/verify-email-otp', {
      'otp': otp,
      'email': email,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to verify OTP';
    }
  }

  /// Send phone OTP to verify nominee's phone
  Future<void> sendNomineePhoneOTP(String mobile, {String countryCode = '+91'}) async {
    final response = await _api.post('/auth/nominee/send-phone-otp', {
      'mobile': mobile,
      'country_code': countryCode,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to send OTP';
    }
  }

  /// Verify nominee phone OTP
  Future<void> verifyNomineePhoneOTP(String otp) async {
    final response = await _api.post('/auth/nominee/verify-phone-otp', {
      'otp': otp,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to verify OTP';
    }
  }

  /// Get nominee opportunities (vaults where current user is listed as nominee)
  Future<List<Map<String, dynamic>>> getNomineeOpportunities() async {
    final response = await _api.get('/auth/nominee-opportunities');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw jsonDecode(response.body)['message'] ?? 'Failed to fetch opportunities';
  }

  /// Link nominee account using owner's security code
  Future<void> linkNomineeAccount(int nomineeId, String securityCode) async {
    final response = await _api.post('/auth/link-account', {
      'nomineeId': nomineeId,
      'securityCode': securityCode,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to link account';
    }
  }
}
