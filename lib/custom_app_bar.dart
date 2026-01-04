import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'book_image.dart';
import 'theme_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String profileImageUrl;
  final String? userRole;

  const CustomAppBar({
    super.key,
    this.userName,
  this.profileImageUrl = 'lib/assets/profile.jpg',
    this.userRole,
  });

  Color _getRoleColor() {
    final role = (userRole ?? AuthService.getCurrentUserRole())?.toLowerCase();
    switch (role) {
      case 'student':
        return const Color(0xFF0A84FF);
      case 'teacher':
        return const Color(0xFF34C759);
      case 'librarian':
        return const Color(0xFFFF9500);
      case 'director':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _getRoleDisplayName() {
    final role = (userRole ?? AuthService.getCurrentUserRole());
    return role?.toUpperCase() ?? 'USER';
  }

  String _getDisplayName() {
    if (userName != null && userName!.trim().isNotEmpty) return userName!;
    final role = (userRole ?? AuthService.getCurrentUserRole())?.toLowerCase();
    switch (role) {
      case 'student':
        return 'Tamal Mazumder';
      case 'teacher':
        return 'Md. Eusha Kadir';
      case 'librarian':
        return 'Jamal Uddin';
      case 'director':
        return 'Nizam Uddin';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
  // compute display name once before building widgets
  final displayName = _getDisplayName();
  final themeService = ThemeService();

  return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRoleColor(),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: BookImage(
                AuthService.getCurrentUserProfile()['profile_image'] ?? profileImageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getRoleColor(),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRoleDisplayName(),
                    style: TextStyle(
                      color: _getRoleColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Greeting with username
                Text(
                  'Hello, $displayName',
                  style: TextStyle(
                    color: themeService.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: themeService.textColor),
          onPressed: () {
            Navigator.pushNamed(context, '/library', arguments: {'userRole': userRole});
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: themeService.textColor),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications', arguments: {'userRole': userRole});
          },
        ),
        IconButton(
          icon: Icon(Icons.logout_outlined, color: themeService.textColor),
          onPressed: () {
            // Show confirmation dialog before logout
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) => AlertDialog(
                backgroundColor: const Color(0xFF2C2D35),
                title: const Text('Logout', style: TextStyle(color: Colors.white)),
                content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop(); // Close dialog first
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
