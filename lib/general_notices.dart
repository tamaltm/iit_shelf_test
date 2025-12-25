import 'package:flutter/material.dart';

class GeneralNoticesPage extends StatelessWidget {
  const GeneralNoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'General Notices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNoticeCard(
            icon: Icons.campaign,
            iconColor: Colors.blue,
            title: 'Library Hours Extended',
            message: 'The library will now be open until 10 PM on weekdays starting next week.',
            timestamp: '2 hours ago',
          ),
          const SizedBox(height: 12),
          _buildNoticeCard(
            icon: Icons.event,
            iconColor: Colors.green,
            title: 'New Book Collection Available',
            message: 'We have added 500+ new books to our collection in Computer Science and Engineering.',
            timestamp: 'Yesterday',
          ),
          const SizedBox(height: 12),
          _buildNoticeCard(
            icon: Icons.warning,
            iconColor: Colors.orange,
            title: 'System Maintenance',
            message: 'The library system will undergo maintenance on Sunday from 2 AM to 6 AM.',
            timestamp: '2 days ago',
          ),
          const SizedBox(height: 12),
          _buildNoticeCard(
            icon: Icons.info,
            iconColor: Colors.purple,
            title: 'Late Fee Policy Update',
            message: 'New late fee policy will be effective from next month. Please check the updated guidelines.',
            timestamp: '3 days ago',
          ),
          const SizedBox(height: 12),
          _buildNoticeCard(
            icon: Icons.celebration,
            iconColor: Colors.pink,
            title: 'Reading Week Event',
            message: 'Join us for the annual Reading Week celebration with special guest authors and book discussions.',
            timestamp: '1 week ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String timestamp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
