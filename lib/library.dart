import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'book_detail.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'filter_page.dart';
import 'book_image.dart';
import 'book_service.dart';

class LibraryPage extends StatefulWidget {
  final String? userRole;

  const LibraryPage({super.key, this.userRole});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String selectedFilter = 'Filters';
  Map<String, dynamic>? activeFilters;

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Book> _books = [];
  Set<String> _borrowedBookIsbns = {}; // Track borrowed book ISBNs

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
  void initState() {
    super.initState();
    _loadBooks();
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return;

    try {
      final borrowedResponse = await BookService.getUserTransactions(
        email,
        status: 'borrowed',
      );
      if (mounted) {
        setState(() {
          _borrowedBookIsbns = Set.from(
            borrowedResponse.map((book) => book['isbn'] as String? ?? ''),
          );
        });
      }
    } catch (e) {
      // Silently fail - doesn't affect main functionality
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks({
    String search = '',
    String? courseId,
    String? category,
    String? semester,
    String? availability,
    String? bookType,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final books = await BookService.fetchBooks(
        search: search.isEmpty ? null : search,
        courseId: courseId,
        category: category,
        semester: semester,
        availability: availability,
        bookType: bookType,
      );
      setState(() {
        _books = books;
        _loading = false;
      });
      // Refresh borrowed books list
      await _loadBorrowedBooks();
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
      appBar: CustomAppBar(
        userRole: widget.userRole ?? AuthService.getCurrentUserRole(),
      ),
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
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search books by title or author',
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            onPressed: () => _loadBooks(
                              search: _searchController.text.trim(),
                              courseId:
                                  activeFilters?['course_code'] as String?,
                              category: activeFilters?['category'] as String?,
                              semester: activeFilters?['semester'] as String?,
                              availability:
                                  activeFilters?['availability'] as String?,
                              bookType: activeFilters?['book_type'] as String?,
                            ),
                          ),
                        ),
                        onSubmitted: (v) => _loadBooks(
                          search: v.trim(),
                          courseId: activeFilters?['course_code'] as String?,
                          category: activeFilters?['category'] as String?,
                          semester: activeFilters?['semester'] as String?,
                          availability:
                              activeFilters?['availability'] as String?,
                          bookType: activeFilters?['book_type'] as String?,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (activeFilters != null)
                        Text(
                          'Filters: ${activeFilters!['course_code'] ?? activeFilters!['author'] ?? activeFilters!['category'] ?? ''}',
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
                        builder: (_) => FilterPage(
                          availableCategories: categories,
                          availableAuthors: authors,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        activeFilters = result;
                      });
                      _loadBooks(
                        search: _searchController.text.trim(),
                        courseId: result['course_code'] as String?,
                        category: result['category'] as String?,
                        semester: result['semester'] as String?,
                        availability: result['availability'] as String?,
                        bookType: result['book_type'] as String?,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
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
                : RefreshIndicator(
                    onRefresh: () => _loadBooks(
                      search: _searchController.text.trim(),
                      courseId: activeFilters?['course_code'] as String?,
                      category: activeFilters?['category'] as String?,
                      semester: activeFilters?['semester'] as String?,
                      availability: activeFilters?['availability'] as String?,
                      bookType: activeFilters?['book_type'] as String?,
                    ),
                    child: _getFilteredBooks().isEmpty
                        ? const Center(
                            child: Text(
                              'No books found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _getFilteredBooks().length,
                            itemBuilder: (context, index) {
                              final book = _getFilteredBooks()[index];
                              return _buildBookCard(context, book, cardColor);
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: 0,
        role: widget.userRole,
      ),
    );
  }

  List<Book> _getFilteredBooks() {
    if (activeFilters == null) return _books;
    final author = activeFilters!['author'] as String?;

    return _books.where((b) {
      if (author != null &&
          author.isNotEmpty &&
          author != 'All' &&
          b.author != author) {
        return false;
      }
      return true;
    }).toList();
  }

  // Filter chips removed — replaced by dedicated filter page

  Widget _buildBookCard(BuildContext context, Book book, Color cardColor) {
    final bool isAvailable = book.isAvailable;
    final bool isAlreadyBorrowed = _borrowedBookIsbns.contains(book.isbn);
    final bool hasPhysicalCopies = book.quantity > 0;
    final bool hasPdf = (book.pdfUrl ?? '').isNotEmpty;
    final statusColor = (!hasPhysicalCopies && hasPdf)
        ? Colors.blue
        : (isAlreadyBorrowed
              ? Colors.grey
              : (isAvailable ? Colors.green : Colors.orange));
    final statusText = (!hasPhysicalCopies && hasPdf)
        ? 'Digital Only'
        : (isAlreadyBorrowed
              ? 'Already Borrowed'
              : (isAvailable ? 'Available' : 'Borrowed / Reserve'));

    // Determine button state
    late String buttonText;
    late Color buttonColor;
    late bool isButtonEnabled;

    if (!hasPhysicalCopies && hasPdf) {
      // Digital-only book - show Download PDF
      buttonText = 'Download PDF';
      buttonColor = Colors.blue;
      isButtonEnabled = true;
    } else if (isAlreadyBorrowed) {
      buttonText = 'Borrowed';
      buttonColor = Colors.grey;
      isButtonEnabled = false;
    } else if (isAvailable) {
      buttonText = 'Borrow';
      buttonColor = const Color(0xFF0A84FF);
      isButtonEnabled = true;
    } else {
      buttonText = 'Reserve';
      buttonColor = Colors.orange;
      isButtonEnabled = true;
    }

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
              book.coverImage ??
                  'https://picsum.photos/seed/${book.id}/400/600',
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
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
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
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                        Colors.white60,
                    fontSize: 14,
                  ),
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
                    onPressed: isButtonEnabled
                        ? () async {
                            // If it's a digital-only book, download PDF directly
                            if (!hasPhysicalCopies && hasPdf) {
                              final url = Uri.parse(book.pdfUrl!);
                              final ok = await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open PDF'),
                                  ),
                                );
                              }
                            } else {
                              // For physical books, navigate to detail page
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
                                    pdfAvailable:
                                        (book.pdfUrl ?? '').isNotEmpty,
                                    pdfUrl: book.pdfUrl,
                                    role: widget.userRole ?? 'Student',
                                    currentBorrowed: 0,
                                    isbn: book.isbn,
                                    pages: book.pages,
                                    year: book.publicationYear,
                                    publisher: book.publisher,
                                    courseId: book.courseId,
                                    totalCopies: book.quantity,
                                  ),
                                ),
                              ).then(
                                (_) => _loadBooks(
                                  search: _searchController.text.trim(),
                                  courseId:
                                      activeFilters?['course_code'] as String?,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonText,
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
                            pdfAvailable: (book.pdfUrl ?? '').isNotEmpty,
                            pdfUrl: book.pdfUrl,
                            isbn: book.isbn,
                            pages: book.pages,
                            year: book.publicationYear,
                            publisher: book.publisher,
                            courseId: book.courseId,
                            totalCopies: book.quantity,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
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
