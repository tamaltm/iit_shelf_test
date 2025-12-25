import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class LibrarianInventoryPage extends StatelessWidget {
  const LibrarianInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: const CustomAppBar(userRole: 'librarian'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Inventory",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 40),
            
            // Action Cards
            _buildActionCard(
              context,
              "Add Book/PDF",
              Icons.menu_book,
              Colors.blue,
              () {
                Navigator.pushNamed(context, '/add-book');
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              "Delete or Edit\nBook/PDF",
              Icons.delete,
              Colors.red,
              () {
                Navigator.pushNamed(context, '/remove-book');
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              "Add Shelves",
              Icons.shelves,
              Colors.blue,
              () {
                Navigator.pushNamed(context, '/add-shelf');
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              "Remove Shelves",
              Icons.shelves,
              Colors.red,
              () {
                Navigator.pushNamed(context, '/remove-shelf');
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2D35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              icon,
              color: color,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, "Dashboard", activeIndex == 0, () {
                Navigator.pushReplacementNamed(context, '/librarian-dashboard');
              }),
              _buildNavItem(Icons.inventory_2, "Inventory", activeIndex == 1, () {
                Navigator.pushReplacementNamed(context, '/librarian-inventory');
              }),
              _buildNavItem(Icons.assessment, "Reports", activeIndex == 2, () {
                Navigator.pushReplacementNamed(context, '/librarian-reports');
              }),
              _buildNavItem(Icons.request_page, "Requests", activeIndex == 3, () {
                Navigator.pushReplacementNamed(context, '/librarian-requests');
              }),
              _buildNavItem(Icons.person, "Profile", activeIndex == 4, () {
                Navigator.pushReplacementNamed(context, '/librarian-profile');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF0A84FF) : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF0A84FF) : Colors.white54,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
