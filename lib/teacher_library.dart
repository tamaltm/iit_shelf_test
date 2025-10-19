import 'package:flutter/material.dart';
import 'book_detail.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'book_resources.dart';
import 'book_image.dart';

class TeacherLibraryPage extends StatefulWidget {
  const TeacherLibraryPage({super.key});

  @override
  State<TeacherLibraryPage> createState() => _TeacherLibraryPageState();
}

class _TeacherLibraryPageState extends State<TeacherLibraryPage> {
  String selectedFilter = 'Filters';

  List<Map<String, dynamic>> _buildFromResources() {
    final list = <Map<String, dynamic>>[];
    final start = 1; // different rotation for teacher page
    for (var i = 0; i < bookResources.length; i++) {
      final res = bookResources[(start + i) % bookResources.length];
      list.add({
        'image': res['image']!,
        'title': res['title']!,
        'author': res['author']!,
        'status': i == 2 ? 'Expected: 9/11/2025' : 'Available',
        'statusColor': i == 2 ? Colors.orange : Colors.green,
        'action': i == 2 ? 'Reserve' : 'Borrow',
      });
    }
    // append a demo unavailable book
    list.add({
      'image': 'https://picsum.photos/id/116/400/600',
      'title': 'The Art of Cloud Engineering',
      'author': 'Emily White',
      'status': 'Not Available',
      'statusColor': Colors.red,
      'action': 'E-book Only',
      'isEbookOnly': true,
    });
    return list;
  }

  late final List<Map<String, dynamic>> books = _buildFromResources();

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2D35);
    const Color backgroundColor = Color(0xFF1A1B1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CustomAppBar(userRole: 'teacher'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.white60, size: 22),
                        hintText: "Search books...",
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.tune, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return _buildBookCard(context, book, cardColor);
              },
            ),
          ),
        ],
      ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 0),
    );
  }

  // Filter chips removed — replaced by filter page if needed

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> book, Color cardColor) {
    final bool isEbookOnly = book['isEbookOnly'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BookImage(
              book['image'],
              width: 90,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  book['author'],
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      book['statusColor'] == Colors.green
                          ? Icons.check_circle
                          : book['statusColor'] == Colors.orange
                              ? Icons.access_time
                              : Icons.cancel,
                      color: book['statusColor'],
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      book['status'],
                      style: TextStyle(
                        color: book['statusColor'],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailPage(
                            image: book['image'],
                            title: book['title'],
                            author: book['author'],
                            description: 'A comprehensive guide covering the fundamentals and advanced concepts.',
                            available: book['statusColor'] == Colors.green,
                            role: 'Teacher',
                            currentBorrowed: 2,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEbookOnly ? Colors.white : const Color(0xFF0A84FF),
                      foregroundColor: isEbookOnly ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      book['action'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailPage(
                            image: book['image'],
                            title: book['title'],
                            author: book['author'],
                            description: 'A comprehensive guide covering the fundamentals and advanced concepts.',
                            available: book['statusColor'] == Colors.green,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white, size: 22),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
