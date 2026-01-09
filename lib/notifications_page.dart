import 'package:flutter/material.dart';
import 'book_service.dart';

class NotificationsPage extends StatefulWidget {
  final String userEmail;

  const NotificationsPage({Key? key, required this.userEmail}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorForType(type).withOpacity(0.2),
                            child: Icon(
                              _getIconForType(type),
                              color: _getColorForType(type),
                            ),
                          ),
                          title: Text(
                            message,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            _formatDateTime(sentAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          isThreeLine: message.length > 50,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
