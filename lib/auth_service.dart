import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService now calls the backend PHP APIs (register, verify, login, reset).
class AuthService {
  static String get _baseHost {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) {
      // Use host machine IP for Android devices
      return 'http://32.0.2.182:8000';
    }
    return 'http://localhost:8000';
  }

  static String get _baseUrl => '$_baseHost/auth';
  static const int _cooldownSeconds = 60;

  // Session persistence keys
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _userTokenKey = 'user_token';

  static String? _currentUserEmail;
  static String? _currentUserRole;
  static String? _token; // placeholder for future JWT/session

  // Lightweight in-memory profile cache used by legacy UI screens that
  // expect synchronous getters. Replace with real profile API when ready.
  static final Map<String, dynamic> _profile = {};

  static final Map<String, DateTime> _verifyCooldown = {};
  static final Map<String, DateTime> _resetCooldown = {};

  static AuthResult result({
    required bool ok,
    required String message,
    String? role,
    String? name,
    String? phone,
    Map<String, dynamic>? data,
  }) => AuthResult(
        ok: ok,
        message: message,
        role: role,
        name: name,
        phone: phone,
        data: data,
      );

  static String _norm(String email) => email.trim().toLowerCase();

  static void setCurrentUser(String? email, {String? role, String? token}) {
    _currentUserEmail = email == null ? null : _norm(email);
    _currentUserRole = role;
    _token = token;

    // Persist to SharedPreferences
    _persistSession();
  }

  static String? getCurrentUserEmail() => _currentUserEmail;
  static String? getCurrentUserRole() => _currentUserRole;
  static String? getToken() => _token;

  static Map<String, dynamic> getCurrentUserProfile() {
    return {'email': _currentUserEmail, 'role': _currentUserRole, ..._profile};
  }

  static void updateCurrentUserProfile(Map<String, dynamic> updates) {
    _profile.addAll(updates);
  }

  // Persist session to SharedPreferences
  static Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserEmail != null) {
        await prefs.setString(_userEmailKey, _currentUserEmail!);
        if (_currentUserRole != null) {
          await prefs.setString(_userRoleKey, _currentUserRole!);
        }
        if (_token != null) {
          await prefs.setString(_userTokenKey, _token!);
        }
      } else {
        // Clear session on logout
        await prefs.remove(_userEmailKey);
        await prefs.remove(_userRoleKey);
        await prefs.remove(_userTokenKey);
      }
    } catch (e) {
      // Silent fail - SharedPreferences not critical
    }
  }

  // Restore session from SharedPreferences
  static Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);

      if (email != null) {
        final role = prefs.getString(_userRoleKey);
        final token = prefs.getString(_userTokenKey);

        _currentUserEmail = email;
        _currentUserRole = role;
        _token = token;

        // Load profile data from backend
        await getProfile(email);
      }
    } catch (e) {
      // Silent fail - session restoration not critical
    }
  }

  // Logout and clear session
  static Future<void> logout() async {
    _currentUserEmail = null;
    _currentUserRole = null;
    _token = null;
    _profile.clear();
    await _persistSession();
  }

  // Legacy helper used by older screens; returns role if the email matches
  // the currently signed-in user.
  static String? getUserRole(String email) {
    if (_currentUserEmail == null) return null;
    return _norm(email) == _currentUserEmail ? _currentUserRole : null;
  }

  // ------------------ Registration + email verification ------------------

  /// Step 1: Send registration OTP (email only, no password yet)
  static Future<AuthResult> sendRegisterOtp(
    String email, {
    String? role,
  }) async {
    final body = {'email': _norm(email)};
    final res = await _post('send_register_otp', body);
    if (!res.ok) {
      _applyVerifyCooldown(email);
      return result(ok: false, message: res.message);
    }
    _applyVerifyCooldown(email);
    final userInfo = res.data['user_info'] as Map<String, dynamic>?;
    return result(
      ok: true,
      message: res.message,
      role: res.data['role'] as String?,
      name: userInfo == null ? null : userInfo['full_name'] as String?,
      phone: userInfo == null ? null : userInfo['contact'] as String?,
      data: userInfo,
    );
  }

  static Future<AuthResult> verifyEmailOtp(String email, String otp) async {
    final res = await _post('verify_email', {
      'email': _norm(email),
      'otp': otp,
    });
    if (!res.ok) {
      return result(ok: false, message: res.message);
    }
    return result(ok: true, message: res.message);
  }

  /// Step 3: Set password after verification
  static Future<AuthResult> setPasswordAfterVerification(
    String email,
    String password, {
    String? name,
    String? phone,
    String? role,
  }) async {
    final res = await _post('set_password', {
      'email': _norm(email),
      'new_password': password,
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (role != null && role.isNotEmpty) 'role': role,
    });
    if (!res.ok) {
      return result(ok: false, message: res.message);
    }
    return result(ok: true, message: res.message);
  }

  // ------------------ Login ------------------

  static Future<AuthResult> login(String email, String password) async {
    final res = await _post('login', {
      'email': _norm(email),
      'password': password,
    });
    if (!res.ok) {
      return result(ok: false, message: res.message);
    }
    final role = res.data['role'] as String?;
    final token = res.data['token'] as String?;
    setCurrentUser(email, role: role, token: token);

    // Load profile data (including profile image) after successful login
    await getProfile(_norm(email));

    return result(ok: true, message: res.message, role: role);
  }

  // ------------------ Password reset ------------------

  static int secondsUntilRetry(String email) {
    final ts = _resetCooldown[_norm(email)];
    if (ts == null) return 0;
    final secs = ts.difference(DateTime.now()).inSeconds;
    return secs > 0 ? secs : 0;
  }

  static int secondsUntilVerificationRetry(String email) {
    final ts = _verifyCooldown[_norm(email)];
    if (ts == null) return 0;
    final secs = ts.difference(DateTime.now()).inSeconds;
    return secs > 0 ? secs : 0;
  }

  static Future<bool> sendPasswordResetOtp(String email) async {
    final res = await _post('send_reset_otp', {'email': _norm(email)});
    if (!res.ok) {
      _applyResetCooldown(email);
      return false;
    }
    _applyResetCooldown(email);
    return true;
  }

  static Future<bool> verifyResetOtp(String email, String otp) async {
    final res = await _post('verify_reset_otp', {
      'email': _norm(email),
      'otp': otp,
    });
    return res.ok;
  }

  static Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final res = await _post('reset_password', {
      'email': _norm(email),
      'otp': otp,
      'new_password': newPassword,
    });
    return res.ok;
  }

  static Future<AuthResult> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _post('change_password', {
      'email': _norm(email),
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    return result(ok: res.ok, message: res.message);
  }

  // ------------------ Helpers ------------------

  static String getDefaultRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return '/dashboard';
      case 'teacher':
        return '/teacher-dashboard';
      case 'librarian':
        return '/librarian-dashboard';
      case 'director':
        return '/director-dashboard';
      default:
        return '/dashboard';
    }
  }

  static void _applyVerifyCooldown(String email) {
    _verifyCooldown[_norm(email)] = DateTime.now().add(
      const Duration(seconds: _cooldownSeconds),
    );
  }

  static void _applyResetCooldown(String email) {
    _resetCooldown[_norm(email)] = DateTime.now().add(
      const Duration(seconds: _cooldownSeconds),
    );
  }

  static Future<AuthResult> uploadProfileImage(
    String email,
    String imagePath,
  ) async {
    try {
      final file = await http.MultipartFile.fromPath('image', imagePath);
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/upload_profile_image.php'),
            )
            ..fields['email'] = email
            ..files.add(file);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      final decoded = responseBody.isNotEmpty
          ? jsonDecode(responseBody) as Map<String, dynamic>
          : <String, dynamic>{};

      final success = decoded['success'] == true;
      final message = decoded['message'] as String? ?? 'Upload failed';

      if (success) {
        final url = decoded['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          _profile['profile_image'] = _absolutizeUrl(url);
        }
      }

      return result(ok: success, message: message);
    } catch (e) {
      return result(ok: false, message: 'Network error: $e');
    }
  }

  static Future<AuthResult> updateProfile({
    required String email,
    String? name,
    String? phone,
    String? role,
  }) async {
    final body = {
      'email': _norm(email),
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (role != null && role.isNotEmpty) 'role': role,
    };

    final apiResult = await _post('update_profile', body);

    if (apiResult.ok) {
      return result(ok: true, message: apiResult.message);
    }

    return result(ok: false, message: apiResult.message);
  }

  static Future<AuthResult> getProfile(String email) async {
    final apiResult = await _post('get_profile', {'email': email});

    if (apiResult.ok && apiResult.data['user'] is Map) {
      final userData = apiResult.data['user'] as Map<String, dynamic>;
      // Ensure profile_image is an absolute URL usable across platforms
      final img = userData['profile_image'];
      if (img is String && img.isNotEmpty) {
        userData['profile_image'] = _absolutizeUrl(img);
      }
      _profile.addAll(userData);
      return result(ok: true, message: 'Profile loaded');
    }

    return result(ok: false, message: apiResult.message);
  }

  static Future<_ApiResult> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final normalized = path.endsWith('.php') ? path : '$path.php';
      final uri = Uri.parse('$_baseUrl/$normalized');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final success =
          decoded['success'] == true ||
          (resp.statusCode >= 200 && resp.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      final data = decoded;
      return _ApiResult(ok: success, message: message, data: data);
    } catch (e) {
      return _ApiResult(ok: false, message: 'Network error: $e', data: {});
    }
  }

  /// Convert relative or mismatched URLs to absolute URLs using _baseHost
  static String _absolutizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    // If absolute but pointing to localhost, swap to _baseHost for devices
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          // Preserve path/query while replacing host (and port if present)
          final base = Uri.parse(_baseHost);
          final rebuilt = Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.port,
            path: uri.path,
            query: uri.query,
          );
          return rebuilt.toString();
        }
        return trimmed;
      } catch (_) {
        // Fall through to relative handling
      }
    }
    // Starts with / -> join with host directly
    if (trimmed.startsWith('/')) {
      return '$_baseHost$trimmed';
    }
    // Common backend path variants like 'auth/get_image.php?...'
    return '$_baseHost/$trimmed';
  }
}

class AuthResult {
  final bool ok;
  final String message;
  final String? role;
  final String? name;
  final String? phone;
  final Map<String, dynamic>? data;

  const AuthResult({
    required this.ok,
    required this.message,
    this.role,
    this.name,
    this.phone,
    this.data,
  });
}

class _ApiResult {
  final bool ok;
  final String message;
  final Map<String, dynamic> data;

  const _ApiResult({
    required this.ok,
    required this.message,
    required this.data,
  });
}
