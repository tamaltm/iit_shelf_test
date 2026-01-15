import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'book_image.dart';
import 'theme_service.dart';
import 'widgets/notification_bell.dart';

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
    final role = (userRole ?? AuthService.getCurrentUserRole())?.toLowerCase();
    // Show teacher's designation instead of generic role badge when available
    if (role == 'teacher') {
      final designation = AuthService.getCurrentUserProfile()['designation'];
      if (designation != null && designation.toString().trim().isNotEmpty) {
        return designation.toString();
      }
    }
    return (role ?? 'user').toUpperCase();
  }

  String _getDisplayName() {
    if (userName != null && userName!.trim().isNotEmpty) return userName!;
    // Try to get name from current user profile
    final profileName = AuthService.getCurrentUserProfile()['name'];
    if (profileName != null && profileName.toString().trim().isNotEmpty) {
      return profileName.toString();
    }
    // Fallback to hardcoded names by role
    final role = (userRole ?? AuthService.getCurrentUserRole())?.toLowerCase();
    switch (role) {
      case 'student':
        return 'Student';
      case 'teacher':
        return 'Teacher';
      case 'librarian':
        return 'Librarian';
      case 'director':
        return 'Director';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
  // compute display name once before building widgets
  final displayName = _getDisplayName();
  final themeService = ThemeService();
  final profileImage = AuthService.getCurrentUserProfile()['profile_image'];

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
              child: (profileImage != null && profileImage.toString().isNotEmpty)
                  ? BookImage(
                      profileImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: themeService.cardBackgroundColor,
                      child: const Icon(Icons.person, color: Colors.white70),
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
        NotificationBell(
          iconColor: themeService.textColor,
          userRole: userRole,
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
