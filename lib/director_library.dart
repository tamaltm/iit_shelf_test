import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'book_detail.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'book_resources.dart';
import 'book_image.dart';
import 'book_service.dart';

class DirectorLibraryPage extends StatefulWidget {
  const DirectorLibraryPage({super.key});

  @override
  State<DirectorLibraryPage> createState() => _DirectorLibraryPageState();
}

class _DirectorLibraryPageState extends State<DirectorLibraryPage> {
  String selectedFilter = 'Filters';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final books = await BookService.fetchBooks(search: search);
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2C2D35);
    const Color backgroundColor = Color(0xFF1A1B1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const CustomAppBar(userRole: 'director'),
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
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white60,
                          size: 22,
                        ),
                        hintText: "Search books...",
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white70,
                            size: 22,
                          ),
                          onPressed: () =>
                              _loadBooks(search: _searchController.text.trim()),
                        ),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
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

  Widget _buildBookCard(BuildContext context, Book book, Color cardColor) {
    final bool isAvailable = book.isAvailable;
    final bool hasPhysicalCopies = book.quantity > 0;
    final bool hasPdf = (book.pdfUrl ?? '').isNotEmpty;
    final statusColor = (!hasPhysicalCopies && hasPdf)
        ? Colors.blue
        : (isAvailable ? Colors.green : Colors.orange);
    final statusText = (!hasPhysicalCopies && hasPdf)
        ? 'Digital Only'
        : (isAvailable ? 'Available' : 'Borrowed / Reserve');
    final pdfAvailable = hasPdf;

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
              book.coverImage ?? bookResources.first['image']!,
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
                  book.title,
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
                  book.author,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.access_time,
                      color: statusColor,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
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
                    onPressed: () async {
                      if (!hasPhysicalCopies && hasPdf) {
                        // Download PDF directly
                        final url = Uri.parse(book.pdfUrl!);
                        final ok = await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open PDF')),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailPage(
                              bookId: book.id,
                              image: book.coverImage ?? '',
                              title: book.title,
                              author: book.author,
                              description:
                                  book.description ??
                                  'No description available',
                              available: isAvailable,
                              role: 'Director',
                              currentBorrowed: 0,
                              isbn: book.isbn,
                              pages: book.pages,
                              year: book.publicationYear,
                              publisher: book.publisher,
                              courseId: book.courseId,
                              pdfAvailable: pdfAvailable,
                              pdfUrl: book.pdfUrl,
                              totalCopies: book.quantity,
                            ),
                          ),
                        ).then(
                          (_) =>
                              _loadBooks(search: _searchController.text.trim()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!hasPhysicalCopies && hasPdf)
                          ? Colors.blue
                          : (isAvailable
                                ? const Color(0xFF0A84FF)
                                : Colors.orange),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      (!hasPhysicalCopies && hasPdf)
                          ? 'Download PDF'
                          : (isAvailable ? 'Borrow' : 'Reserve'),
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
                            bookId: book.id,
                            image: book.coverImage ?? '',
                            title: book.title,
                            author: book.author,
                            description:
                                book.description ?? 'No description available',
                            available: isAvailable,
                            pdfAvailable: pdfAvailable,
                            pdfUrl: book.pdfUrl,
                            isbn: book.isbn,
                            pages: book.pages,
                            year: book.publicationYear,
                            publisher: book.publisher,
                            courseId: book.courseId,
                          ),
                        ),
                      ).then(
                        (_) =>
                            _loadBooks(search: _searchController.text.trim()),
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
                icon: const Icon(
                  Icons.ios_share,
                  color: Colors.white,
                  size: 22,
                ),
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
