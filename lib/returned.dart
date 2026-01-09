import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'book_image.dart';
import 'book_service.dart';

class ReturnedBooksPage extends StatefulWidget {
  const ReturnedBooksPage({super.key});

  @override
  State<ReturnedBooksPage> createState() => _ReturnedBooksPageState();
}

class _ReturnedBooksPageState extends State<ReturnedBooksPage> {
  List<Map<String, dynamic>> _returnedBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReturnedBooks();
  }

  Future<void> _loadReturnedBooks() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await BookService.getUserTransactions(
        email,
        status: 'returned',
      );
      if (mounted) {
        setState(() {
          _returnedBooks = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load returned books';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  hintText: "Search books...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabButton(
                  label: "History",
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/my-books'),
                ),
                _TabButton(
                  label: "Borrowed",
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/borrowed'),
                ),
                _TabButton(label: "Returned", active: true, onTap: null),
                _TabButton(
                  label: "Reserved",
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/reserved'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              "Book History",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _returnedBooks.isEmpty
                ? const Center(
                    child: Text(
                      'No returned books',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _returnedBooks.length,
                    itemBuilder: (context, index) {
                      final book = _returnedBooks[index];
                      return ReturnedBookCard(
                        image: book['pic_path'] ?? '',
                        title: book['title'] ?? 'Unknown Title',
                        author: book['author'] ?? 'Unknown Author',
                        id: book['copy_id'] ?? '',
                        returned: book['return_date'] ?? '',
                        isbn: book['isbn'],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 1),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _TabButton({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class ReturnedBookCard extends StatelessWidget {
  final String image, title, author, id, returned;
  final String? isbn;

  const ReturnedBookCard({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.id,
    required this.returned,
    this.isbn,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF23232A);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookImage(
                    image,
                    width: 90,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        author,
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                              Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          returned,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "ID:$id",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/book-detail',
                        arguments: {
                          'title': title,
                          'author': author,
                          'image': image,
                          'description': 'Book details for $title',
                          'available': true,
                          if (isbn != null && isbn!.isNotEmpty) 'isbn': isbn,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Details",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
