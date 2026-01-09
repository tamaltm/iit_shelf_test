import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'custom_app_bar.dart';

class LibrarianDashboardPage extends StatefulWidget {
  const LibrarianDashboardPage({super.key});

  @override
  State<LibrarianDashboardPage> createState() => _LibrarianDashboardPageState();
}

class _LibrarianDashboardPageState extends State<LibrarianDashboardPage> {
  int _totalBooks = 0;
  int _pendingReturns = 0;
  int _pendingRequests = 0;
  double _finesCollectedToday = 0.0;
  int _returnApprovals = 0;
  int _newBookRequests = 0;
  int _paymentVerifications = 0;
  List<dynamic> _recentActivity = [];
  bool _isLoading = true;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/librarian/dashboard_stats.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _totalBooks = data['stats']['total_books'];
            _pendingReturns = data['stats']['pending_returns'];
            _pendingRequests = data['stats']['pending_requests'];
            _finesCollectedToday = data['stats']['fines_collected_today']
                .toDouble();
            _returnApprovals = data['stats']['return_approvals'];
            _newBookRequests = data['stats']['new_book_requests'];
            _paymentVerifications = data['stats']['payment_verifications'];
            _recentActivity = data['recent_activity'] ?? [];
            _isLoading = false;
          });
        } else {
          _handleError(
            'Failed to load dashboard data: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        _handleError('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Error: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1B1E),
        appBar: const CustomAppBar(userRole: 'librarian'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: const CustomAppBar(userRole: 'librarian'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  context,
                  "Total Books",
                  _totalBooks.toString(),
                  Icons.menu_book,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  "Pending Returns",
                  _pendingReturns.toString(),
                  Icons.hourglass_empty,
                  Colors.red,
                ),
                _buildStatCard(
                  context,
                  "Pending Requests",
                  _pendingRequests.toString(),
                  Icons.calendar_today,
                  Colors.red,
                ),
                _buildStatCard(
                  context,
                  "Fines Collected Today",
                  "TK ${_finesCollectedToday.toStringAsFixed(2)}",
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pending Tasks
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pending Tasks",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTaskItem(
                    context,
                    "Return Approvals",
                    _returnApprovals,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildTaskItem(
                    context,
                    "New Book Requests",
                    _newBookRequests,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildTaskItem(
                    context,
                    "Payment Verifications",
                    _paymentVerifications,
                    Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Text(
              "Quick Actions",
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
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
                _buildActionButton(context, "Search books", Icons.search, () {
                  Navigator.pushNamed(
                    context,
                    '/library',
                    arguments: {'userRole': 'librarian'},
                  );
                }),
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
                _buildActionButton(context, "Request New Book", Icons.book, () {
                  Navigator.pushNamed(context, '/request-book-details');
                }),
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

            const SizedBox(height: 16),

            // Recent Activity Feed
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recent Activity Feed",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentActivity.isEmpty)
                    Text(
                      "No recent activity",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    )
                  else
                    ..._recentActivity.map((activity) {
                      String activityDesc = _formatActivityItem(activity);
                      String timeAgo = _getTimeAgo(activity['issue_date']);
                      IconData icon = activity['status'] == 'Returned'
                          ? Icons.check_circle
                          : Icons.menu_book;
                      Color color = activity['status'] == 'Returned'
                          ? Colors.green
                          : Colors.blue;

                      return Column(
                        children: [
                          _buildActivityItem(
                            context,
                            timeAgo,
                            activityDesc,
                            icon,
                            color,
                          ),
                          if (activity != _recentActivity.last)
                            const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
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

  String _formatActivityItem(dynamic activity) {
    final String title = activity['title'] ?? 'Unknown';
    final String name = activity['name'] ?? 'User';
    final String status = activity['status'] ?? 'Borrowed';

    String truncatedTitle = title.length > 20
        ? '${title.substring(0, 20)}...'
        : title;

    if (status == 'Borrowed') {
      return 'User ${name.split(' ')[0]} borrowed "$truncatedTitle"';
    } else if (status == 'Returned') {
      return 'User ${name.split(' ')[0]} returned "$truncatedTitle"';
    }
    return 'User ${name.split(' ')[0]} interacted with "$truncatedTitle"';
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      DateTime dateTime = DateTime.parse(timestamp.toString());
      Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                        Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
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
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
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
    BuildContext context,
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
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.54) ??
                  Colors.white54,
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
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.54) ??
                        Colors.white54,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white,
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
        color: Theme.of(context).cardColor.withOpacity(0.8),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    return Flexible(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0A84FF) : Colors.white54,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
