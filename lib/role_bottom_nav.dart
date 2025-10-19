import 'package:flutter/material.dart';
import 'auth_service.dart';

class RoleBottomNav extends StatelessWidget {
  final int currentIndex;

  const RoleBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final role = (AuthService.getCurrentUserRole() ?? 'student').toLowerCase();

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF22232A), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
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
          if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF22232A), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex.clamp(0, 4),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/director-dashboard');
          if (index == 1) Navigator.pushReplacementNamed(context, '/director-my-books');
          if (index == 2) Navigator.pushReplacementNamed(context, '/generate-reports', arguments: {'userRole': 'director'});
          if (index == 3) Navigator.pushReplacementNamed(context, '/transaction-history', arguments: {'userRole': 'director'});
          if (index == 4) Navigator.pushReplacementNamed(context, '/director-profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLibrarianNav(BuildContext context) {
    // keep current librarian design but ensure consistent behavior
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
              Expanded(child: _navItem(context, Icons.dashboard, 'Dashboard', true, () => Navigator.pushReplacementNamed(context, '/librarian-dashboard'))),
              Expanded(child: _navItem(context, Icons.inventory_2, 'Inventory', false, () => Navigator.pushReplacementNamed(context, '/librarian-inventory'))),
              Expanded(child: _navItem(context, Icons.assessment, 'Reports', false, () => Navigator.pushReplacementNamed(context, '/librarian-reports'))),
              Expanded(child: _navItem(context, Icons.request_page, 'Requests', false, () => Navigator.pushReplacementNamed(context, '/librarian-requests'))),
              Expanded(child: _navItem(context, Icons.person, 'Profile', false, () => Navigator.pushReplacementNamed(context, '/librarian-profile'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFF0A84FF) : Colors.white54, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? const Color(0xFF0A84FF) : Colors.white54, fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}
