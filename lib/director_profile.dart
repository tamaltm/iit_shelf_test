import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';
import 'book_image.dart';

class DirectorProfilePage extends StatelessWidget {
  const DirectorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(userRole: 'director'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BookImage(
                AuthService.getCurrentUserProfile()['image'] ?? 'lib/assets/profile.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Nizam Uddin",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 4),
            const Text(
              "Director",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "nizam.uddin@iit.edu",
              style: TextStyle(color: Colors.blue, fontSize: 14),
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
                    _StatColumn(label: "Borrowed", value: "2"),
                    _StatColumn(label: "Returned", value: "45"),
                    _StatColumn(label: "Reserved", value: "3"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ProfileMenuItem(
              icon: Icons.person,
              title: "Edit Profile",
              onTap: () { Navigator.pushNamed(context, '/edit-profile'); },
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
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Logout", style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 4),
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
