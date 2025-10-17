import 'package:flutter/material.dart';
import 'book_detail.dart';
import 'custom_app_bar.dart';
import 'custom_bottom_nav.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String selectedFilter = 'Filters';

  final List<Map<String, dynamic>> books = [
    {
      'image': 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
      'title': 'Foundations of Data Science',
      'author': 'John Doe',
      'status': 'Available',
      'statusColor': Colors.green,
      'action': 'Borrow',
    },
    {
      'image': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400',
      'title': 'The Future of Artificial Intelligence',
      'author': 'Jane Smith',
      'status': 'Expected: 9/11/2025',
      'statusColor': Colors.orange,
      'action': 'Reserve',
    },
    {
      'image': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
      'title': 'Introduction to Quantum Computing',
      'author': 'Robert Johnson',
      'status': 'Available',
      'statusColor': Colors.green,
      'action': 'Borrow',
    },
    {
      'image': 'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
      'title': 'Digital Dreamscapes: Exploring Virtual',
      'author': 'Alice Brown',
      'status': 'Available',
      'statusColor': Colors.green,
      'action': 'Borrow',
    },
    {
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
      'title': 'The Art of Cloud Engineering',
      'author': 'Emily White',
      'status': 'Not Available',
      'statusColor': Colors.red,
      'action': 'E-book Only',
      'isEbookOnly': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2D35);
    const Color backgroundColor = Color(0xFF1A1B1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CustomAppBar(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Filters', true),
                const SizedBox(width: 10),
                _buildFilterChip('Category', false),
                const SizedBox(width: 10),
                _buildFilterChip('Author', false),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
              ],
            ),
          ),
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
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C2D35) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

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
            child: Image.network(
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
