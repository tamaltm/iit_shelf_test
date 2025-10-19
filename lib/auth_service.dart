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
    // For demo purposes, accept the dummy password for any registered email
    return _userRoles.containsKey(email.toLowerCase()) && 
           password == _dummyPassword;
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
