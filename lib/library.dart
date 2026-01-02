import 'package:flutter/material.dart';
import 'book_detail.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'filter_page.dart';
import 'book_resources.dart';
import 'book_image.dart';

class LibraryPage extends StatefulWidget {
  final String? userRole;

  const LibraryPage({super.key, this.userRole});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String selectedFilter = 'Filters';
  Map<String, dynamic>? activeFilters;

  // books will be built from shared resources below

  // Build books list from shared resources but rotated for this page
  List<Map<String, dynamic>> _buildFromResources() {
    final List<Map<String, dynamic>> list = [];
    // rotate start index to create a different order here (start at 3)
    final start = 3;
    for (var i = 0; i < bookResources.length; i++) {
      final res = bookResources[(start + i) % bookResources.length];
      list.add({
        'image': res['image']!,
        'title': res['title']!,
        'author': res['author']!,
        'status': i == 1 ? 'Expected: 9/11/2025' : 'Available',
        'statusColor': i == 1 ? Colors.orange : Colors.green,
        'action': i == 1 ? 'Reserve' : 'Borrow',
      });
    }
    // add one extra demo book to keep list length similar
    list.add({
      'image': 'https://picsum.photos/id/111/400/600',
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

  // simple demo lists for FilterPage
  final List<String> categories = [
    'All',
    'Computer Science',
    'Mathematics',
    'Physics',
  ];

  final List<String> authors = [
    'All',
    'John Doe',
    'Jane Smith',
    'Robert Johnson',
    'Alice Brown',
    'Emily White',
  ];

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2D35);
    const Color backgroundColor = Color(0xFF1A1B1E);

    return Scaffold(
      backgroundColor: backgroundColor,
  appBar: CustomAppBar(userRole: widget.userRole ?? AuthService.getCurrentUserRole()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Book cover removed from left of search box per UI request
                const SizedBox(width: 0),
                 // Search bar + filter button
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       TextField(
                         style: const TextStyle(color: Colors.white),
                         decoration: InputDecoration(
                           hintText: 'Search books by title or author',
                           hintStyle: const TextStyle(color: Colors.white60),
                           filled: true,
                           fillColor: cardColor,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(10),
                             borderSide: BorderSide.none,
                           ),
                         ),
                         onChanged: (v) {
                           // optionally implement search logic
                         },
                       ),
                       const SizedBox(height: 8),
                       if (activeFilters != null)
                         Text(
                           'Filters: ${activeFilters!['author'] ?? activeFilters!['category'] ?? ''}',
                           style: const TextStyle(color: Colors.white60),
                         ),
                     ],
                   ),
                 ),
                 const SizedBox(width: 12),
                 // Filter button
                 GestureDetector(
                   onTap: () async {
                     final result = await Navigator.push<Map<String, dynamic>?>(
                       context,
                       MaterialPageRoute(
                         builder: (_) => FilterPage(availableCategories: categories, availableAuthors: authors),
                       ),
                     );
                     if (result != null) {
                       setState(() {
                         activeFilters = result;
                       });
                     }
                   },
                   child: Container(
                     decoration: BoxDecoration(
                       color: cardColor,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     padding: const EdgeInsets.all(12),
                     child: const Icon(Icons.tune, color: Colors.white, size: 22),
                   ),
                 ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _getFilteredBooks().length,
              itemBuilder: (context, index) {
                final book = _getFilteredBooks()[index];
                return _buildBookCard(context, book, cardColor);
              },
            ),
          ),
        ],
      ),
  bottomNavigationBar: RoleBottomNav(currentIndex: 0, role: widget.userRole),
    );
  }

  List<Map<String, dynamic>> _getFilteredBooks() {
    if (activeFilters == null) return books;
  final category = activeFilters!['category'] as String?;
  final author = activeFilters!['author'] as String?;

    return books.where((b) {
      if (author != null && author.isNotEmpty && b['author'] != author) return false;
      if (category != null && category.isNotEmpty && category != 'All') {
        // demo: no category field in mock data — skip unless implemented
      }
      // session/semester demo filters are no-ops unless book metadata includes them
      return true;
    }).toList();
  }

  // Filter chips removed — replaced by dedicated filter page

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
                            role: 'Student', // demo: this page is for students
                            currentBorrowed: 1, // demo current borrowed count
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
