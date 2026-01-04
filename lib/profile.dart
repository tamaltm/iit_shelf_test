import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'theme_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ThemeService _themeService = ThemeService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  String? _profileImagePath;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = AuthService.getCurrentUserEmail();
    if (email != null) {
      final result = await AuthService.getProfile(email);
      if (result.ok) {
        setState(() {
          _profileData = AuthService.getCurrentUserProfile();
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _profileImagePath = pickedFile.path;
        });

        final email = AuthService.getCurrentUserEmail();
        if (email != null) {
          final result = await AuthService.uploadProfileImage(email, pickedFile.path);
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            if (result.ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile image updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              await _loadProfile();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${result.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = _themeService.cardBackgroundColor;

    final role = AuthService.getCurrentUserRole();
    final email = AuthService.getCurrentUserEmail() ?? '';
    
    // Get profile data (now from database)
    final displayName = _profileData['name'] ?? 'User';
    final displayRole = _profileData['role'] ?? role ?? 'student';
    final displayPhone = _profileData['phone'] ?? 'Not provided';
    final profileImage = _profileData['profile_image'];

    return Scaffold(
      backgroundColor: _themeService.backgroundColor,
      appBar: CustomAppBar(userRole: role),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image with Edit Button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!))
                        : profileImage != null && profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : const AssetImage("assets/profile.jpg") as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback
                    },
                    child: profileImage == null || profileImage.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                ),
                // Edit Button
                GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: TextStyle(
                color: _themeService.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayRole.toUpperCase(),
              style: TextStyle(color: _themeService.secondaryTextColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              displayPhone,
              style: TextStyle(color: _themeService.secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatColumn(label: "Borrowed", value: "1"),
                    _StatColumn(label: "Returned", value: "23"),
                    _StatColumn(label: "Reserved", value: "1"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.brightness_6, color: Colors.blue),
                title: Text('Dark Mode',
                    style: TextStyle(
                        color: _themeService.textColor, fontWeight: FontWeight.w500)),
                trailing: Switch(
                  value: _themeService.isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _themeService.toggleTheme();
                    });
                  },
                  activeThumbColor: Colors.blue,
                ),
              ),
            ),
            ProfileMenuItem(
              icon: Icons.person,
              title: "Edit Profile",
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              cardColor: cardColor,
            ),
            ProfileMenuItem(
              icon: Icons.settings,
              title: "Settings",
              onTap: () {},
              cardColor: cardColor,
            ),
            ProfileMenuItem(
              icon: Icons.help,
              title: "Help & Support",
              onTap: () {},
              cardColor: cardColor,
            ),
            ProfileMenuItem(
              icon: Icons.info,
              title: "About",
              onTap: () {},
              cardColor: cardColor,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Clear session and navigate to login
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Logout",
                    style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 3),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color cardColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: onTap,
      ),
    );
  }
}
