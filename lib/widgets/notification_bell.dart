import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../book_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    this.iconColor,
    this.size = 24,
    this.userRole,
  });

  final Color? iconColor;
  final double size;
  final String? userRole;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _count = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null || _loading) return;
    setState(() {
      _loading = true;
    });
    final count = await BookService.getNotificationCount(email);
    if (!mounted) return;
    setState(() {
      _count = count;
      _loading = false;
    });
  }

  void _openNotifications() {
    Navigator.pushNamed(
      context,
      '/notifications',
      arguments: {'userRole': widget.userRole ?? AuthService.getCurrentUserRole()},
    ).then((_) => _loadCount());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: widget.iconColor ?? Theme.of(context).iconTheme.color,
            size: widget.size,
          ),
          onPressed: _openNotifications,
        ),
        if (_count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                _count > 99 ? '99+' : _count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
