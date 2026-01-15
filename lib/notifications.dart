import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'book_service.dart';
import 'library.dart';
import 'librarian_requests.dart';
import 'profile.dart';

class NotificationItem {
  final int id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String timestamp;
  final String actionLabel;
  final String type;
  final VoidCallback? onAction;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actionLabel,
    required this.type,
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    final email = AuthService.getCurrentUserEmail();
    if (email == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final data = await BookService.getNotifications(email);
      final items = <NotificationItem>[];

      for (var notif in data) {
        final type = notif['type'] ?? 'System';
        final message = notif['message'] ?? '';
        final sentAt = notif['sent_at'] ?? '';
        final notifId = notif['notification_id'] ?? notif['id'] ?? 0;

        items.add(NotificationItem(
          id: notifId,
          icon: _getIconForType(type),
          iconColor: _getColorForType(type),
          title: message,
          description: '',
          timestamp: _formatDateTime(sentAt),
          actionLabel: 'Read',
          type: type,
          onAction: () => _handleNotificationAction(type),
        ));
      }

      setState(() {
        notifications = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to load notifications');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'BorrowRequestApproved':
      case 'ReturnRequestApproved':
        return Icons.check_circle;
      case 'ReservedBookAvailable':
        return Icons.notification_important;
      case 'ReservationQueueUpdate':
        return Icons.update;
      case 'DueDateReminder':
        return Icons.schedule;
      case 'FineReminder':
        return Icons.warning;
      case 'AdditionRequestApproved':
        return Icons.library_add_check;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'BorrowRequestApproved':
      case 'ReturnRequestApproved':
      case 'AdditionRequestApproved':
        return Colors.green;
      case 'ReservedBookAvailable':
      case 'DueDateReminder':
        return Colors.orange;
      case 'FineReminder':
        return Colors.red;
      case 'ReservationQueueUpdate':
        return const Color(0xFF14B8A6);
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return dateTime;
    }
  }

  void _handleNotificationAction(String type) {
    // Route based on notification type
    if (type == 'BorrowRequestApproved' || type == 'ReturnRequestApproved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    } else if (type == 'ReservedBookAvailable') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    } else if (type == 'ReservationQueueUpdate') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LibrarianRequestsPage(),
        ),
      );
    } else if (type == 'DueDateReminder' || type == 'FineReminder') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else if (type == 'AdditionRequestApproved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    }
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
    final notification = notifications[index];
    
    setState(() {
      notifications.removeAt(index);
    });
    
    // Call API to delete from backend
    BookService.deleteNotification(notification.id, widget.userRole ?? '').then((success) {
      if (success) {
        _showSnackBar('Notification deleted');
      } else {
        // Re-add if deletion failed
        setState(() {
          notifications.insert(index, notification);
        });
        _showSnackBar('Failed to delete notification');
      }
    });
  }

  void _deleteAllNotifications() {
    if (notifications.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notifications'),
          content: const Text('Are you sure you want to delete all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final email = AuthService.getCurrentUserEmail();
                if (email == null) return;
                
                // Delete all notifications from backend
                final notifsCopy = List<NotificationItem>.from(notifications);
                setState(() {
                  notifications.clear();
                });
                
                bool allSuccess = true;
                for (var notif in notifsCopy) {
                  final success = await BookService.deleteNotification(notif.id, email);
                  if (!success) {
                    allSuccess = false;
                  }
                }
                
                if (allSuccess) {
                  _showSnackBar('All notifications deleted');
                } else {
                  _showSnackBar('Some notifications could not be deleted');
                  // Reload to get current state
                  _loadNotifications();
                }
              },
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _markAllAsRead() async {
    if (notifications.isEmpty) return;
    
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return;
    
    final success = await BookService.markAllNotificationsAsRead(email);
    if (success) {
      _showSnackBar('All notifications marked as read');
    } else {
      _showSnackBar('Failed to mark all as read');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'delete_all') {
                  _deleteAllNotifications();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Mark All as Read'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
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
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index], index);
                    },
                  ),
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
