import 'dart:convert';
import 'api_client.dart';

class SuccessionService {
  final ApiClient _api = ApiClient();

  /// Discover vaults where the current user is a registered nominee
  Future<List<Map<String, dynamic>>> discoverAccounts() async {
    final response = await _api.get('/succession/discover');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw jsonDecode(response.body)['message'] ?? 'Failed to discover accounts';
  }

  /// Get inherited accounts (vaults the user has been granted access to)
  Future<List<Map<String, dynamic>>> getInheritedAccounts() async {
    final response = await _api.get('/succession/inherited-accounts');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw jsonDecode(response.body)['message'] ?? 'Failed to fetch inherited accounts';
  }

  /// Initiate a succession claim using the vault owner's security code
  Future<Map<String, dynamic>> initiateClaim({
    required String ownerMobile,
    required String claimCode,
  }) async {
    final response = await _api.post('/succession/initiate-claim', {
      'ownerMobile': ownerMobile,
      'claimCode': claimCode,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Claim initiation failed';
    return data;
  }

  /// Verify the succession claim OTP
  Future<Map<String, dynamic>> verifyClaimOTP({
    required String ownerMobile,
    required String otp,
  }) async {
    final response = await _api.post('/succession/verify-claim-otp', {
      'ownerMobile': ownerMobile,
      'otp': otp,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Verification failed';
    return data;
  }

  /// Verify a succession token from a notification link
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _api.get('/succession/verify?token=$token');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Invalid token';
    return data;
  }
}
