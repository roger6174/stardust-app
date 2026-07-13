import 'dart:convert';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  // ─── LOGIN ───
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await _api.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Login failed';
    return data;
  }

  // ─── REGISTER ───
  Future<Map<String, dynamic>> register({
    required String fullName,
    String? email,
    required String mobile,
    required String password,
    required List<Map<String, dynamic>> securityAnswers,
  }) async {
    final response = await _api.post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'securityAnswers': securityAnswers,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Registration failed';
    return data;
  }

  // ─── VERIFY OTP ───
  Future<Map<String, dynamic>> verifyOtp({
    int? userId,
    required String otp,
    String? email,
    String? mobile,
  }) async {
    final response = await _api.post('/auth/verify-otp', {
      if (userId != null) 'userId': userId,
      'otp': otp,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Verification failed';
    if (data['token'] != null) await _api.setToken(data['token']);
    return data;
  }

  // ─── PROFILE ───
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/auth/profile');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Failed to fetch profile';
    return data;
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final response = await _api.put('/auth/profile', fields);
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update profile';
    }
  }

  Future<Map<String, dynamic>> getProfileCompletion() async {
    final response = await _api.get('/auth/profile-completion');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Failed to fetch completion';
    return data;
  }

  // ─── FORGOT PASSWORD ───
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    final response = await _api.post('/auth/forgot-password', {
      'identifier': identifier,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw data['message'] ?? 'Failed';
    }
    return data;
  }

  Future<Map<String, dynamic>> verifyForgotOtp(int userId, String otp) async {
    final response = await _api.post('/auth/verify-forgot-otp', {
      'userId': userId,
      'otp': otp,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'OTP verification failed';
    return data;
  }

  Future<void> resetPasswordAfterForgot(String resetToken, String newPassword) async {
    final response = await _api.post('/auth/reset-password-forgot', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Reset failed';
    }
  }

  // ─── ACCOUNT RECOVERY (Multi-method) ───
  Future<Map<String, dynamic>> recoverLookup(String identifier) async {
    final response = await _api.post('/auth/recover/lookup', {
      'identifier': identifier,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Lookup failed';
    return data;
  }

  Future<void> recoverSendOTP(int userId, String method) async {
    final response = await _api.post('/auth/recover/send-otp', {
      'userId': userId,
      'method': method,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to send OTP';
    }
  }

  Future<Map<String, dynamic>> recoverVerify({
    required int userId,
    required String phase,
    String? otp,
    List<Map<String, dynamic>>? answers,
  }) async {
    final response = await _api.post('/auth/recover/verify', {
      'userId': userId,
      'phase': phase,
      if (otp != null) 'otp': otp,
      if (answers != null) 'answers': answers,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) throw data['message'] ?? 'Verification failed';
    return data;
  }

  Future<void> recoverUpdateAccount({
    required String resetToken,
    String? email,
    String? mobile,
    String? password,
  }) async {
    final response = await _api.put('/auth/recover/update-account', {
      'resetToken': resetToken,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (password != null) 'password': password,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Update failed';
    }
  }

  // ─── ONBOARDING ───
  Future<void> completeOnboarding() async {
    final response = await _api.post('/auth/complete-onboarding', {});
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed';
    }
  }

  Future<bool> getOnboardingStatus() async {
    final response = await _api.get('/auth/onboarding-status');
    final data = jsonDecode(response.body);
    return data['has_completed_onboarding'] == true;
  }

  // ─── EMAIL VERIFICATION ───
  Future<void> sendEmailOtp({String? email}) async {
    final response = await _api.post('/auth/send-email-otp', {
      if (email != null) 'email': email,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to send OTP';
    }
  }

  Future<void> verifyEmailOtp(String otp, {String? email}) async {
    final response = await _api.post('/auth/verify-email-otp', {
      'otp': otp,
      if (email != null) 'email': email,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to verify OTP';
    }
  }

  // ─── VAULT POLICY ───
  Future<void> updateVaultPolicy({
    required int inactivityTriggerPeriod,
    required int reminderInterval,
  }) async {
    final response = await _api.put('/auth/vault-policy', {
      'inactivity_trigger_period': inactivityTriggerPeriod,
      'reminder_interval': reminderInterval,
    });
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to update policy';
    }
  }

  // ─── SECURITY QUESTIONS ───
  Future<List<Map<String, dynamic>>> getSecurityQuestions() async {
    final response = await _api.get('/auth/questions');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw 'Failed to fetch security questions';
  }

  // ─── AUDIT LOGS ───
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final response = await _api.get('/auth/audit-logs');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw 'Failed to fetch audit logs';
  }

  // ─── SESSION ───
  Future<void> logout() async {
    await _api.logout();
  }

  Future<bool> isLoggedIn() async {
    return await _api.isAuthenticated();
  }

  Future<String?> getToken() async {
    return await _api.getToken();
  }

  // ─── ACCOUNT DELETION ───
  Future<void> deleteAccount() async {
    final response = await _api.delete('/auth/account');
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['message'] ?? 'Failed to delete account';
    }
    await _api.logout(); // Clear local session
  }
}
