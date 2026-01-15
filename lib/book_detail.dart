import 'package:flutter/material.dart';

import 'book_service.dart';
import 'auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailPage extends StatefulWidget {
  final int? bookId;
  final String image, title, author, description;
  final bool available;
  final bool pdfAvailable;
  final String? pdfUrl;
  final String role;
  final int currentBorrowed;
  final String? isbn;
  final int? pages;
  final int? year;
  final String? publisher;
  final String? courseId;
  final int totalCopies;
  final int? availableCopies;
  final String? edition;
  final String? category;

  const BookDetailPage({
    super.key,
    this.bookId,
    required this.image,
    required this.title,
    required this.author,
    required this.description,
    required this.available,
    this.pdfAvailable = true,
    this.pdfUrl,
    this.role = 'Student',
    this.currentBorrowed = 0,
    this.isbn,
    this.pages,
    this.year,
    this.publisher,
    this.courseId,
    this.totalCopies = 0,
    this.availableCopies,
    this.edition,
    this.category,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool? _isAvailable;
  bool _isLoading = true;
  bool _isUserBorrowed = false; // Track if user has already borrowed this book
  bool _returnRequestSubmitted = false; // Track if return request was submitted
  Map<String, dynamic>? _bookData; // Store fetched complete book data
  String? _userRole; // Track current user role

  @override
  void initState() {
    super.initState();
    _userRole = AuthService.getCurrentUserRole();
    _fetchBookStatus();
    _checkIfUserBorrowed();
    if (widget.isbn != null && widget.isbn!.isNotEmpty) {
      _fetchCompleteBookInfo();
    }
  }

  Future<void> _fetchCompleteBookInfo() async {
    try {
      final books = await BookService.fetchBooks(search: widget.isbn);
      if (books.isNotEmpty) {
        final book = books.firstWhere(
          (b) => b.isbn == widget.isbn,
          orElse: () => books.first,
        );
        if (mounted) {
          setState(() {
            _bookData = {
              'edition': book.edition,
              'category': book.category,
              'publisher': book.publisher,
              'availableQuantity': book.availableQuantity,
              'quantity': book.quantity,
            };
          });
        }
      }
    } catch (e) {
      // Silently fail - use data from widget
    }
  }

  Future<void> _fetchBookStatus() async {
    if (widget.isbn == null || widget.isbn!.isEmpty) {
      setState(() {
        _isAvailable = widget.available;
        _isLoading = false;
      });
      return;
    }

    final status = await BookService.getBookStatus(widget.isbn!);
    if (mounted) {
      setState(() {
        _isAvailable = status?.available ?? widget.available;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestReturn(BuildContext context) async {
    if (widget.isbn == null || widget.isbn!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing ISBN for return request.')),
      );
      return;
    }

    // Get the transaction ID from user's borrowed books
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return;

    try {
      final borrowed = await BookService.getUserTransactions(
        email,
        status: 'borrowed',
      );

      // Find transaction with matching ISBN
      Map<String, dynamic>? transaction;
      for (var book in borrowed) {
        if (book['isbn'] == widget.isbn) {
          transaction = book;
          break;
        }
      }

      if (transaction == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book not found in your borrowed list.'),
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Return'),
          content: Text('Are you sure you want to return "${widget.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Return'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await BookService.requestReturn(
        transactionId: transaction['transaction_id'] as int,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.ok ? Colors.green : Colors.redAccent,
          ),
        );

        if (result.ok) {
          setState(() {
            _returnRequestSubmitted = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing return request.')),
      );
    }
  }

  Future<void> _borrow(BuildContext context) async {
    if (widget.isbn == null || widget.isbn!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing ISBN for borrow action.')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await BookService.borrowBook(isbn: widget.isbn!);
    if (Navigator.canPop(context)) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? Colors.green : Colors.redAccent,
      ),
    );
    // Refresh status after borrowing
    if (result.ok) _fetchBookStatus();
    _checkIfUserBorrowed();
  }

  Future<void> _checkIfUserBorrowed() async {
    final email = AuthService.getCurrentUserEmail();
    final isbn = widget.isbn;

    if (email == null || isbn == null || isbn.isEmpty) return;

    try {
      final borrowed = await BookService.getUserTransactions(
        email,
        status: 'borrowed',
      );
      if (mounted) {
        final alreadyBorrowed = borrowed.any((book) => book['isbn'] == isbn);
        setState(() {
          _isUserBorrowed = alreadyBorrowed;
        });
      }
    } catch (_) {
      // Silently fail if check doesn't work
    }
  }

  Future<void> _reserve(BuildContext context) async {
    if (widget.isbn == null || widget.isbn!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing ISBN for reserve action.')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await BookService.reserveBook(isbn: widget.isbn!);
    if (Navigator.canPop(context)) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? Colors.green : Colors.redAccent,
      ),
    );
    // Refresh status after reserving
    if (result.ok) _fetchBookStatus();
    _checkIfUserBorrowed();
  }

  @override
  Widget build(BuildContext context) {
    final available = _isAvailable ?? widget.available;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Book Details',
          style:
              Theme.of(context).appBarTheme.titleTextStyle ??
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Builder(
                        builder: (ctx) {
                          final img = (widget.image.trim().isEmpty)
                              ? 'lib/assets/data_science.png'
                              : widget.image;
                          if (img.startsWith('http')) {
                            return Image.network(
                              img,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    'lib/assets/data_science.png',
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),
                            );
                          }
                          return Image.asset(
                            img,
                            height: 300,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 96,
                                  color: Colors.white70,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: available ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                available
                                    ? 'Available Now'
                                    : 'Currently Borrowed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  (widget.pdfAvailable &&
                                      (widget.pdfUrl ?? '').isNotEmpty)
                                  ? () async {
                                      final url = Uri.parse(widget.pdfUrl!);
                                      final ok = await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      if (!ok && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open PDF'),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.pdfAvailable
                                      ? Colors.blue
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.pdfAvailable
                                      ? 'Download PDF'
                                      : 'PDF unavailable',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Book Information",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2D35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('ISBN', widget.isbn ?? 'N/A'),
                              const Divider(color: Colors.grey, height: 20),
                              _buildInfoRow('Author', widget.author),
                              const Divider(color: Colors.grey, height: 20),
                              _buildInfoRow('Publisher', (_bookData?['publisher'] ?? widget.publisher) ?? 'N/A'),
                              const Divider(color: Colors.grey, height: 20),
                              _buildInfoRow('Publication Year', widget.year?.toString() ?? 'N/A'),
                              const Divider(color: Colors.grey, height: 20),
                              _buildInfoRow('Edition', (_bookData?['edition'] ?? widget.edition) ?? 'N/A'),
                              const Divider(color: Colors.grey, height: 20),
                              _buildInfoRow('Category', (_bookData?['category'] ?? widget.category) ?? 'N/A'),
                              if ((widget.totalCopies > 0) || (_bookData?['quantity'] ?? 0) > 0) ...[
                                const Divider(color: Colors.grey, height: 20),
                                _buildInfoRow('Total Copies', ((_bookData?['quantity'] ?? widget.totalCopies) ?? 0).toString()),
                                const Divider(color: Colors.grey, height: 20),
                                _buildInfoRow('Available Copies', '${(_bookData?['availableQuantity'] ?? widget.availableCopies) ?? 0}/${(_bookData?['quantity'] ?? widget.totalCopies) ?? 0}'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Hide borrow/reserve buttons for librarians
                        if (_userRole?.toLowerCase() != 'librarian') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _returnRequestSubmitted
                                  ? null
                                  : (_isUserBorrowed
                                        ? () => _requestReturn(context)
                                        : (available
                                              ? () => _borrow(context)
                                              : null)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _returnRequestSubmitted
                                    ? Colors.grey
                                    : (_isUserBorrowed ? Colors.blue : (available ? Colors.blue : Colors.grey)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _returnRequestSubmitted
                                    ? "Requested"
                                    : (_isUserBorrowed
                                          ? "Request to Return"
                                          : (available
                                                ? "Borrow Book"
                                                : "Not Available")),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Show Reserve button only if book has physical copies but NO available copies
                          if (widget.totalCopies > 0 && !(_isAvailable ?? widget.available) && !_isUserBorrowed)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _reserve(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Reserve Book",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ] else ...[
                          // Message for librarians
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Librarians cannot borrow or reserve books',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + ':',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
