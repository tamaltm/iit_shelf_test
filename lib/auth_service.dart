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

  static bool validateLogin(String email, String password) {
    // For demo purposes, accept the dummy password for any registered email
    return _userRoles.containsKey(email.toLowerCase()) && 
           password == _dummyPassword;
  }

  static String getDefaultRouteForRole(String role) {
    switch (role) {
      case 'student':
      case 'teacher':
        return '/dashboard';
      case 'librarian':
        return '/librarian-dashboard';
      case 'director':
        return '/director-dashboard';
      default:
        return '/dashboard';
    }
  }
}
