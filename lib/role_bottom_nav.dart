import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'theme_service.dart';

class RoleBottomNav extends StatelessWidget {
  final int currentIndex;
  final String? role;

  const RoleBottomNav({super.key, required this.currentIndex, this.role});

  @override
  Widget build(BuildContext context) {
    final role = (this.role ?? AuthService.getCurrentUserRole() ?? 'student').toLowerCase();

    if (role == 'director') {
      return _buildDirectorNav(context);
    }

    if (role == 'librarian') {
      return _buildLibrarianNav(context);
    }

    // student and teacher use the same 4-button layout (student design)
    return _buildStudentTeacherNav(context, role);
  }

  Widget _buildStudentTeacherNav(BuildContext context, String role) {
    final themeService = ThemeService();
    return Container(
      decoration: BoxDecoration(
        color: themeService.backgroundColor,
        border: Border(
          top: BorderSide(color: themeService.cardBackgroundColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: themeService.backgroundColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeService.textColor,
        unselectedItemColor: themeService.tertiaryTextColor,
        currentIndex: currentIndex.clamp(0, 3),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index == 0) {
            // teachers should go to their teacher dashboard, students to regular dashboard
            if (role == 'teacher') {
              Navigator.pushReplacementNamed(context, '/teacher-dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          }
          if (index == 1) Navigator.pushReplacementNamed(context, '/my-books');
          if (index == 2) Navigator.pushReplacementNamed(context, '/payment');
          if (index == 3) {
            // This nav is only for students and teachers, but add safety check
            if (role == 'teacher') {
              Navigator.pushReplacementNamed(context, '/teacher-profile');
            } else if (role == 'librarian') {
              Navigator.pushReplacementNamed(context, '/librarian-profile');
            } else if (role == 'director') {
              Navigator.pushReplacementNamed(context, '/director-profile');
            } else {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet_outlined), activeIcon: Icon(Icons.wallet), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDirectorNav(BuildContext context) {
    final themeService = ThemeService();
    return Container(
      decoration: BoxDecoration(
        color: themeService.backgroundColor,
        border: Border(
          top: BorderSide(color: themeService.cardBackgroundColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: themeService.backgroundColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeService.textColor,
        unselectedItemColor: themeService.tertiaryTextColor,
        currentIndex: currentIndex.clamp(0, 3),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/director-dashboard');
          if (index == 1) Navigator.pushReplacementNamed(context, '/director-my-books');
          if (index == 2) Navigator.pushReplacementNamed(context, '/generate-reports', arguments: {'userRole': 'director'});
          if (index == 3) Navigator.pushReplacementNamed(context, '/director-profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLibrarianNav(BuildContext context) {
    final themeService = ThemeService();
    // keep current librarian design but ensure consistent behavior
    return Container(
      decoration: BoxDecoration(
        color: themeService.secondaryCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _navItem(context, Icons.dashboard, 'Dashboard', currentIndex == 0, () => Navigator.pushReplacementNamed(context, '/librarian-dashboard'))),
              Expanded(child: _navItem(context, Icons.inventory_2, 'Inventory', currentIndex == 1, () => Navigator.pushReplacementNamed(context, '/librarian-inventory'))),
              Expanded(child: _navItem(context, Icons.assessment, 'Reports', currentIndex == 2, () => Navigator.pushReplacementNamed(context, '/librarian-reports'))),
              Expanded(child: _navItem(context, Icons.request_page, 'Requests', currentIndex == 3, () => Navigator.pushReplacementNamed(context, '/librarian-requests'))),
              Expanded(child: _navItem(context, Icons.person, 'Profile', currentIndex == 4, () => Navigator.pushReplacementNamed(context, '/librarian-profile'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap) {
    final themeService = ThemeService();
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFF0A84FF) : themeService.tertiaryTextColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? const Color(0xFF0A84FF) : themeService.tertiaryTextColor, fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}
