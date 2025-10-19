import 'package:flutter/material.dart';

class TeacherBottomNav extends StatelessWidget {
  final int currentIndex;

  const TeacherBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFF22232A),
      selectedItemColor: const Color(0xFF34C759),
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/teacher-library'),
            child: const Icon(Icons.home),
          ),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/teacher-my-books'),
            child: const Icon(Icons.book),
          ),
          label: 'My Books',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/teacher-profile'),
            child: const Icon(Icons.person),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
