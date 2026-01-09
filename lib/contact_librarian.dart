import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';
import 'library_settings_service.dart';

class ContactLibrarianPage extends StatefulWidget {
  const ContactLibrarianPage({super.key});

  @override
  State<ContactLibrarianPage> createState() => _ContactLibrarianPageState();
}

class _ContactLibrarianPageState extends State<ContactLibrarianPage> {
  late Future<LibrarySettings?> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = LibrarySettingsService.fetchLibrarySettings();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Librarian",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Have questions or need assistance? Contact the library staff using the information below.",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Librarian Contact Info Cards
            FutureBuilder<LibrarySettings?>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                // Default values while loading or on error
                final settings =
                    snapshot.data ??
                    LibrarySettings(
                      email: 'library@nstu.edu.bd',
                      phone: '+880 1234-567890',
                      hours: 'Mon-Fri: 9:00 AM - 5:00 PM',
                      location: 'Central Library, NSTU Campus',
                    );

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2D35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Library Contact Information",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContactInfoRow(
                        Icons.email_outlined,
                        "Email",
                        settings.email,
                        const Color(0xFF0A84FF),
                      ),
                      const SizedBox(height: 12),
                      _buildContactInfoRow(
                        Icons.phone_outlined,
                        "Phone",
                        settings.phone,
                        const Color(0xFF14B8A6),
                      ),
                      const SizedBox(height: 12),
                      _buildContactInfoRow(
                        Icons.access_time,
                        "Hours",
                        settings.hours,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildContactInfoRow(
                        Icons.location_on_outlined,
                        "Location",
                        settings.location,
                        Colors.red,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Help Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Help",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickHelpItem(
                    "How do I borrow a book?",
                    "Visit the library page, search for your book, and click 'Borrow'.",
                  ),
                  _buildQuickHelpItem(
                    "How do I return a book?",
                    "Go to 'My Books' > 'Borrowed' and click 'Return' on the book.",
                  ),
                  _buildQuickHelpItem(
                    "How do I pay fines?",
                    "Navigate to the Payment page from your dashboard to view and pay outstanding fines.",
                  ),
                  _buildQuickHelpItem(
                    "How do I request a new book?",
                    "Use the 'Request New Book' option in Quick Actions on your dashboard.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 0),
    );
  }

  Widget _buildContactInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickHelpItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
