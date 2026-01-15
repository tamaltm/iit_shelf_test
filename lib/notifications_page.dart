import 'package:flutter/material.dart';
import 'book_service.dart';
import 'librarian_requests.dart';
import 'library.dart';
import 'profile.dart';

class NotificationsPage extends StatefulWidget {
  final String userEmail;
  final String? userRole;

  const NotificationsPage({
    Key? key, 
    required this.userEmail,
    this.userRole,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    final data = await BookService.getNotifications(widget.userEmail);
    setState(() {
      notifications = data;
      isLoading = false;
    });
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
        return Colors.blue;
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

  void _handleNotificationTap(dynamic notification) {
    final type = notification['type'] ?? 'System';

    // Route based on notification type
    if (type == 'BorrowRequestApproved' || type == 'ReturnRequestApproved') {
      // Navigate to library to view the book
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    } else if (type == 'ReservedBookAvailable') {
      // Navigate to library to view reserved book
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    } else if (type == 'ReservationQueueUpdate') {
      // Navigate to requests page to view reservation details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LibrarianRequestsPage(),
        ),
      );
    } else if (type == 'DueDateReminder' || type == 'FineReminder') {
      // Navigate to profile to view borrowed books
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else if (type == 'AdditionRequestApproved') {
      // Navigate to library to view newly added book
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(userRole: widget.userRole),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final type = notification['type'] ?? 'System';
                      final message = notification['message'] ?? '';
                      final sentAt = notification['sent_at'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getColorForType(type).withOpacity(0.2),
                                    child: Icon(
                                      _getIconForType(type),
                                      color: _getColorForType(type),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(sentAt),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _handleNotificationTap(notification),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Read'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      // Delete notification
                                      setState(() {
                                        notifications.removeAt(index);
                                      });
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
