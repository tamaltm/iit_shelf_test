import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String timestamp;
  final String actionLabel;
  final VoidCallback? onAction;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actionLabel,
    this.onAction,
  });
}

class NotificationsPage extends StatefulWidget {
  final String? userRole;

  const NotificationsPage({super.key, this.userRole});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    notifications = [
      NotificationItem(
        icon: Icons.notifications,
        iconColor: const Color(0xFF14B8A6),
        title: 'New report template',
        description: '"Quarterly Sales" is now available for use.',
        timestamp: '2 hours ago',
        actionLabel: 'Read',
        onAction: () {
          _showSnackBar('Opening report template...');
        },
      ),
      NotificationItem(
        icon: Icons.info_outline,
        iconColor: const Color(0xFF14B8A6),
        title: 'Your requested report to payment history has been generated and is ready to view.',
        description: '',
        timestamp: 'Yesterday',
        actionLabel: 'View Report',
        onAction: () {
          _showSnackBar('Opening payment report...');
        },
      ),
      NotificationItem(
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF14B8A6),
        title: 'Your Request to add PDF is at Pending',
        description: '',
        timestamp: '2 days ago',
        actionLabel: 'View Details',
        onAction: () {
          _showSnackBar('Viewing PDF request details...');
        },
      ),
      NotificationItem(
        icon: Icons.access_time,
        iconColor: const Color(0xFF14B8A6),
        title: 'Reminder: Review your pending reports by end of week.',
        description: '',
        timestamp: '3 days ago',
        actionLabel: 'Read',
        onAction: () {
          _showSnackBar('Opening pending reports...');
        },
      ),
      NotificationItem(
        icon: Icons.notifications,
        iconColor: const Color(0xFF14B8A6),
        title: 'Your Due date to Book ID: 823(A) is close. To avoid fine return the book in due date',
        description: '',
        timestamp: '4 days ago',
        actionLabel: 'Read',
        onAction: () {
          _showSnackBar('Opening book details...');
        },
      ),
      NotificationItem(
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF14B8A6),
        title: 'Request at Pending for addition of Introduction...',
        description: '',
        timestamp: '28.9.2025',
        actionLabel: 'Read',
        onAction: () {
          _showSnackBar('Opening request details...');
        },
      ),
    ];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF14B8A6),
      ),
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    _showSnackBar('Notification deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
  appBar: CustomAppBar(userRole: widget.userRole ?? AuthService.getCurrentUserRole()),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index], index);
              },
            ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 0),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (notification.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.description,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                notification.timestamp,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: notification.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  notification.actionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _deleteNotification(index),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
