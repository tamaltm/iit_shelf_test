import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';
import 'theme_service.dart';
import 'book_service.dart';

class LibrarianProfilePage extends StatefulWidget {
  const LibrarianProfilePage({super.key});

  @override
  State<LibrarianProfilePage> createState() => _LibrarianProfilePageState();
}

class _LibrarianProfilePageState extends State<LibrarianProfilePage> {
  final ThemeService _themeService = ThemeService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _statsLoading = false;
  String? _profileImagePath;
  Map<String, dynamic> _profileData = {};
  int _borrowedCount = 0;
  int _returnedCount = 0;
  int _reservedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  void _showResetPasswordDialog(BuildContext context, Color cardColor) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool _showCurrentPassword = false;
    bool _showNewPassword = false;
    bool _showConfirmPassword = false;
    bool _isChanging = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _themeService.cardBackgroundColor,
              title: Text(
                'Reset Password',
                style: TextStyle(color: _themeService.textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordCtrl,
                      obscureText: !_showCurrentPassword,
                      style: TextStyle(color: _themeService.textColor),
                      decoration: InputDecoration(
                        hintText: 'Current Password',
                        hintStyle: TextStyle(color: _themeService.secondaryTextColor),
                        fillColor: _themeService.secondaryCardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: !_showNewPassword,
                      style: TextStyle(color: _themeService.textColor),
                      decoration: InputDecoration(
                        hintText: 'New Password',
                        hintStyle: TextStyle(color: _themeService.secondaryTextColor),
                        fillColor: _themeService.secondaryCardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: !_showConfirmPassword,
                      style: TextStyle(color: _themeService.textColor),
                      decoration: InputDecoration(
                        hintText: 'Confirm New Password',
                        hintStyle: TextStyle(color: _themeService.secondaryTextColor),
                        fillColor: _themeService.secondaryCardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isChanging ? null : () { Navigator.of(context).pop(); },
                  child: Text('Cancel', style: TextStyle(color: _themeService.textColor)),
                ),
                ElevatedButton(
                  onPressed: _isChanging ? null : () async {
                    final currentPass = currentPasswordCtrl.text.trim();
                    final newPass = newPasswordCtrl.text.trim();
                    final confirmPass = confirmPasswordCtrl.text.trim();
                    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All fields are required'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    setDialogState(() { _isChanging = true; });
                    final email = AuthService.getCurrentUserEmail();
                    if (email != null) {
                      final result = await AuthService.changePassword(
                        email: email,
                        currentPassword: currentPass,
                        newPassword: newPass,
                        confirmPassword: confirmPass,
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: result.ok ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isChanging ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
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

  Future<void> _loadStats() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return;

    setState(() {
      _statsLoading = true;
    });

    try {
      final results = await Future.wait([
        BookService.getUserTransactions(email, status: 'borrowed'),
        BookService.getUserTransactions(email, status: 'returned'),
        BookService.getUserTransactions(email, status: 'reserved'),
      ]);

      if (!mounted) return;

      setState(() {
        _borrowedCount = results[0].length;
        _returnedCount = results[1].length;
        _reservedCount = results[2].length;
      });
    } catch (_) {
      // Keep defaults if stats fail to load.
    } finally {
      if (mounted) {
        setState(() {
          _statsLoading = false;
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
    final cardColor = _themeService.cardBackgroundColor;

    final email = AuthService.getCurrentUserEmail() ?? '';
    final displayName = _profileData['name'] ?? 'Librarian';
    final displayRole = _profileData['role'] ?? 'librarian';
    final displayPhone = _profileData['phone'] ?? 'Not provided';
    final profileImage = _profileData['profile_image'] ?? _profileData['image'];

    return Scaffold(
      backgroundColor: _themeService.backgroundColor,
      appBar: const CustomAppBar(userRole: 'librarian'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                            : const AssetImage('assets/profile.jpg') as ImageProvider,
                    child: profileImage == null || profileImage.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                ),
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
                  children: [
                    _StatColumn(
                      label: 'Borrowed',
                      value: _statsLoading ? '...' : _borrowedCount.toString(),
                    ),
                    _StatColumn(
                      label: 'Returned',
                      value: _statsLoading ? '...' : _returnedCount.toString(),
                    ),
                    _StatColumn(
                      label: 'Reserved',
                      value: _statsLoading ? '...' : _reservedCount.toString(),
                    ),
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
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
              title: 'Edit Profile',
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              cardColor: cardColor,
            ),
            ProfileMenuItem(
              icon: Icons.lock,
              title: 'Reset Password',
              onTap: () {
                _showResetPasswordDialog(context, cardColor);
              },
              cardColor: cardColor,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 4, role: 'librarian'),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: onTap,
      ),
    );
  }
}
