import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class LibrarianDashboardPage extends StatelessWidget {
  const LibrarianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Librarian Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  "Total Books",
                  "450",
                  Icons.menu_book,
                  Colors.blue,
                ),
                _buildStatCard(
                  "Pending Returns",
                  "28",
                  Icons.hourglass_empty,
                  Colors.red,
                ),
                _buildStatCard(
                  "Pending Requests",
                  "7",
                  Icons.calendar_today,
                  Colors.red.shade700,
                ),
                _buildStatCard(
                  "Fines Collected Today",
                  "300",
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pending Tasks
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pending Tasks",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTaskItem("Return Approvals", 7, Colors.red),
                  const SizedBox(height: 12),
                  _buildTaskItem("New Book Requests", 3, Colors.blue),
                  const SizedBox(height: 12),
                  _buildTaskItem("Payment Verifications", 2, Colors.green),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildActionButton(
                  context,
                  "Manage Inventory",
                  Icons.inventory_2,
                  () {
                    Navigator.pushNamed(context, '/librarian-inventory');
                  },
                ),
                _buildActionButton(
                  context,
                  "Search books",
                  Icons.search,
                  () {
                    Navigator.pushNamed(context, '/library');
                  },
                ),
                _buildActionButton(
                  context,
                  "Transaction History",
                  Icons.history,
                  () {
                    Navigator.pushNamed(
                      context,
                      '/transaction-history',
                      arguments: {'userRole': 'librarian'},
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Generate Report",
                  Icons.assessment,
                  () {
                    Navigator.pushNamed(
                      context,
                      '/generate-reports',
                      arguments: {'userRole': 'librarian'},
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Request New Book",
                  Icons.book,
                  () {
                    Navigator.pushNamed(context, '/request-book-details');
                  },
                ),
                _buildActionButton(
                  context,
                  "Contact Support",
                  Icons.support_agent,
                  () {
                    Navigator.pushNamed(context, '/contact-librarian');
                  },
                ),
                _buildActionButton(
                  context,
                  "Upload PDF",
                  Icons.upload_file,
                  () {
                    Navigator.pushNamed(context, '/upload-pdf');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity Feed
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Activity Feed",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    "2 min ago",
                    'User Sarah B. borrowed "The Complete Gui..."',
                    Icons.menu_book,
                    Colors.blue,
                  ),
                  _buildActivityItem(
                    "10 min ago",
                    'User John D. returned "Database Manage..."',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    "30 min ago",
                    "User Alex L. paid TK 20.00 fine",
                    Icons.payment,
                    Colors.red,
                  ),
                  _buildActivityItem(
                    "1 hour ago",
                    'User Maria G. borrowed "System Engineer..."',
                    Icons.menu_book,
                    Colors.blue,
                  ),
                  _buildActivityItem(
                    "2 hours ago",
                    'User David P. requested for addition "Sapi..."',
                    Icons.add_circle,
                    Colors.green,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String time,
    String description,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, "Dashboard", true, () {}),
              _buildNavItem(Icons.inventory_2, "Inventory", false, () {
                Navigator.pushReplacementNamed(context, '/librarian-inventory');
              }),
              _buildNavItem(Icons.assessment, "Reports", false, () {
                Navigator.pushReplacementNamed(context, '/librarian-reports');
              }),
              _buildNavItem(Icons.request_page, "Requests", false, () {
                Navigator.pushReplacementNamed(context, '/librarian-requests');
              }),
              _buildNavItem(Icons.person, "Profile", false, () {
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
