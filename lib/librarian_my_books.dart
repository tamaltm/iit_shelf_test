import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';

class LibrarianMyBooksPage extends StatelessWidget {
  const LibrarianMyBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
  appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.grey[600], size: 64),
            const SizedBox(height: 16),
            Text(
              'Librarians Cannot Borrow Books',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As a librarian, you manage the library inventory',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 1),
    );
  }
}
