import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class LibrarianRequestsPage extends StatefulWidget {
  const LibrarianRequestsPage({super.key});

  @override
  State<LibrarianRequestsPage> createState() => _LibrarianRequestsPageState();
}

class _LibrarianRequestsPageState extends State<LibrarianRequestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: const CustomAppBar(userRole: 'librarian'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Requests",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF0A84FF),
                  labelColor: const Color(0xFF0A84FF),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: "Borrow"),
                    Tab(text: "Return"),
                    Tab(text: "Reserve"),
                    Tab(text: "Addition"),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by User ID",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2C2D35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBorrowTab(),
                _buildReturnTab(),
                _buildReserveTab(),
                _buildAdditionTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildBorrowTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBorrowRequestCard(
          "123456",
          "Request to Borrow",
          "Database Management",
          "234612AB",
          "2 hours ago",
        ),
      ],
    );
  }

  Widget _buildReturnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReturnRequestCard(
          "123456",
          "Request to Return",
          "Database Management",
          "234612AB",
          "BDT 0.00",
          "2 hours ago",
        ),
      ],
    );
  }

  Widget _buildReserveTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReserveRequestCard(
          "123456",
          "Joined Queue in 4",
          "Database Management",
          "234612AB",
          "2 hours ago",
        ),
        const SizedBox(height: 12),
        _buildReserveRequestCard(
          "234561",
          "Joined Queue in 3",
          "Database Management",
          "234612AB",
          "3 hours ago",
        ),
      ],
    );
  }

  Widget _buildAdditionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdditionRequestCard(
          "123456",
          "Request to Add",
          "System Engineering",
          "2 hours ago",
        ),
      ],
    );
  }

  Widget _buildBorrowRequestCard(
    String userId,
    String requestType,
    String bookName,
    String isbn,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "User ID: $userId",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (val) {},
                fillColor: WidgetStateProperty.all(Colors.transparent),
                side: const BorderSide(color: Colors.white54),
              ),
              const Text("832(A)", style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(width: 16),
              Checkbox(
                value: false,
                onChanged: (val) {},
                fillColor: WidgetStateProperty.all(Colors.transparent),
                side: const BorderSide(color: Colors.white54),
              ),
              const Text("834(B)", style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(width: 16),
              Checkbox(
                value: false,
                onChanged: (val) {},
                fillColor: WidgetStateProperty.all(Colors.transparent),
                side: const BorderSide(color: Colors.white54),
              ),
              const Text("835(C)", style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Approve",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnRequestCard(
    String userId,
    String requestType,
    String bookName,
    String isbn,
    String fine,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "User ID: $userId",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Late Fine: $fine",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Damaged Fine (If any)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Approve",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveRequestCard(
    String userId,
    String queueInfo,
    String bookName,
    String isbn,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "User ID: $userId",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            queueInfo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Request",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionRequestCard(
    String userId,
    String requestType,
    String bookName,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "User ID: $userId",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Request",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
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
