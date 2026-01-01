import 'dart:math';

class AuthService {
  // Map emails to roles for demo purposes
  static final Map<String, String> _userRoles = {
    // Students
    'student@nstu.edu.bd': 'student',
    'john.doe@nstu.edu.bd': 'student',
    'jane.smith@nstu.edu.bd': 'student',
    
    // Teachers
    'teacher@nstu.edu.bd': 'teacher',
    'prof.wilson@nstu.edu.bd': 'teacher',
    'dr.anderson@nstu.edu.bd': 'teacher',
    
    // Librarians
    'librarian@nstu.edu.bd': 'librarian',
    'lib.admin@nstu.edu.bd': 'librarian',
    
    // Directors
    'director@nstu.edu.bd': 'director',
    'admin@nstu.edu.bd': 'director',
  };

  // Dummy password for all users (for demo)
  static const String _dummyPassword = 'password123';

  // Per-user password overrides (for resets in demo)
  static final Map<String, String> _passwordOverrides = {};

  // OTP/reset tracking (demo only)
  static final Map<String, String> _resetOtps = {};
  static final Map<String, DateTime> _otpExpiry = {};
  static final Map<String, DateTime> _otpCooldown = {};

  static String? getUserRole(String email) {
    return _userRoles[email.toLowerCase()];
  }

  // Simple global session state for demo purposes
  static String? _currentUserEmail;

  static void setCurrentUser(String? email) {
    _currentUserEmail = email?.toLowerCase();
  }

  static String? getCurrentUserEmail() => _currentUserEmail;

  static String? getCurrentUserRole() {
    if (_currentUserEmail == null) return null;
    return getUserRole(_currentUserEmail!);
  }

  // Simple in-memory profile store (demo only)
  static final Map<String, Map<String, String>> _profiles = {};

  static Map<String, String> getCurrentUserProfile() {
    final email = _currentUserEmail ?? '';
    return _profiles.putIfAbsent(email, () => {
      'phone': '',
      'image': 'lib/assets/profile.jpg',
    });
  }

  static void updateCurrentUserProfile(Map<String, String> data) {
    final email = _currentUserEmail ?? '';
    final existing = _profiles.putIfAbsent(email, () => {
      'phone': '',
      'image': 'lib/assets/profile.jpg',
    });
    existing.addAll(data);
  }

  static bool validateLogin(String email, String password) {
    final e = email.toLowerCase();
    if (!_userRoles.containsKey(e)) return false;
    final overridden = _passwordOverrides[e];
    if (overridden != null) return overridden == password;
    return password == _dummyPassword;
  }

  // ----- Password reset (demo implementation) -----

  static bool canSendOtp(String email) {
    final e = email.toLowerCase();
    final cooldown = _otpCooldown[e];
    if (cooldown == null) return true;
    return DateTime.now().isAfter(cooldown);
  }

  static int secondsUntilRetry(String email) {
    final e = email.toLowerCase();
    final cooldown = _otpCooldown[e];
    if (cooldown == null) return 0;
    final secs = cooldown.difference(DateTime.now()).inSeconds;
    return secs > 0 ? secs : 0;
  }

  // Simulate sending an OTP to the user's registered email.
  // Returns true if OTP "sent" (email exists and not in cooldown).
  static bool sendPasswordResetOtp(String email) {
    final e = email.toLowerCase();
    if (!_userRoles.containsKey(e)) return false;
    if (!canSendOtp(e)) return false;
    final otp = (Random().nextInt(900000) + 100000).toString();
    _resetOtps[e] = otp;
    _otpExpiry[e] = DateTime.now().add(const Duration(minutes: 5));
    _otpCooldown[e] = DateTime.now().add(const Duration(minutes: 1));
    // For demo purposes, print OTP to console (simulate email)
    // In a real app, replace with email/SMS provider integration.
    // ignore: avoid_print
    print('Password reset OTP for $e: $otp');
    return true;
  }

  static bool verifyResetOtp(String email, String otp) {
    final e = email.toLowerCase();
    final stored = _resetOtps[e];
    final expiry = _otpExpiry[e];
    if (stored == null || expiry == null) return false;
    if (DateTime.now().isAfter(expiry)) return false;
    return stored == otp;
  }

  // Reset password after verifying OTP. Returns true on success.
  static bool resetPassword(String email, String otp, String newPassword) {
    final e = email.toLowerCase();
    if (!verifyResetOtp(e, otp)) return false;
    _passwordOverrides[e] = newPassword;
    _resetOtps.remove(e);
    _otpExpiry.remove(e);
    return true;
  }

  static String getDefaultRouteForRole(String role) {
    switch (role) {
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
}
