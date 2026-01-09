import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'book_image.dart';
import 'book_service.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'payment_service.dart';

class Book {
  final String image;
  final String title;
  final String author;
  final String dueLabel;
  final Color dueColor;
  final String id;
  final int? transactionId;

  Book({
    required this.image,
    required this.title,
    required this.author,
    required this.dueLabel,
    required this.dueColor,
    required this.id,
    this.transactionId,
  });
}

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});
  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  List<Map<String, dynamic>> _borrowedBooks = [];
  List<Book> _recommendedBooks = [];
  bool _isLoading = true;
  int _borrowedCount = 0;
  int _overdueCount = 0;
  int _borrowingLimit = 5;
  double _outstandingFines = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  int _getBorrowingLimit(String? role) {
    switch (role?.toLowerCase()) {
      case 'student':
        return 2;
      case 'teacher':
        return 5;
      case 'librarian':
        return 10;
      case 'director':
        return 10;
      default:
        return 5;
    }
  }

  int _calculateDaysUntilDue(String? dueDate) {
    if (dueDate == null) return 0;
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      return due.difference(now).inDays;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadDashboardData() async {
    final email = AuthService.getCurrentUserEmail();
    final role = AuthService.getCurrentUserRole();

    if (email == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      _borrowingLimit = _getBorrowingLimit(role);

      final borrowedResponse = await BookService.getUserTransactions(
        email,
        status: 'borrowed',
      );
      final allBooksResponse = await BookService.fetchBooks();
      final fine = await PaymentService.fetchOutstandingFines();

      if (!mounted) return;

      setState(() {
        _borrowedBooks = borrowedResponse.take(2).toList();
        _borrowedCount = borrowedResponse.length;
        _overdueCount = borrowedResponse
            .where(
              (book) =>
                  book['status'] == 'Overdue' || book['type'] == 'overdue',
            )
            .length;

        _recommendedBooks = allBooksResponse
            .map(
              (book) => Book(
                image: book.coverImage ?? '',
                title: book.title,
                author: book.author,
                dueLabel: '${book.availableQuantity} available',
                dueColor: book.isAvailable ? Colors.green : Colors.grey,
                id: book.isbn ?? book.id.toString(),
              ),
            )
            .toList();

        _outstandingFines = fine?.totalOutstanding ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(userRole: 'teacher'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Teacher Dashboard",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Books Borrowed",
                          "$_borrowedCount/$_borrowingLimit",
                          Icons.menu_book,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Overdue",
                          _overdueCount.toString(),
                          Icons.warning_amber_rounded,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Outstanding Fines",
                                style: TextStyle(
                                  color:
                                      Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7) ??
                                      Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'BDT ${_outstandingFines.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/payment');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Pay Now",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recommended for You",
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/library');
                        },
                        child: const Text(
                          "View All",
                          style: TextStyle(color: Color(0xFF0A84FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendedBooks.length,
                      itemBuilder: (context, index) {
                        return _buildCarouselBookCard(_recommendedBooks[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Currently Borrowed",
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/borrowed');
                        },
                        child: const Text(
                          "View All",
                          style: TextStyle(color: Color(0xFF0A84FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_borrowedBooks.isEmpty)
                    const Center(
                      child: Text(
                        'No books currently borrowed',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._borrowedBooks.map((book) {
                      final daysUntilDue = _calculateDaysUntilDue(
                        book['due_date'],
                      );
                      String dueLabel = '';
                      Color dueColor = Colors.grey;

                      if (daysUntilDue > 0) {
                        dueLabel = "Due in $daysUntilDue days";
                        dueColor = daysUntilDue <= 3
                            ? Colors.red
                            : Colors.orange;
                      } else {
                        dueLabel = "Overdue by ${daysUntilDue.abs()} days";
                        dueColor = Colors.red;
                      }

                      return _buildBookCard(
                        Book(
                          image: book['pic_path'] ?? '',
                          title: book['title'] ?? 'Unknown Title',
                          author: book['author'] ?? 'Unknown Author',
                          dueLabel: dueLabel,
                          dueColor: dueColor,
                          id: book['isbn'] ?? '',
                          transactionId: book['id'] as int?,
                        ),
                      );
                    }),

                  const SizedBox(height: 16),

                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _QuickButton(
                        icon: Icons.bookmark_rounded,
                        label: "Reservations",
                        onTap: () {
                          Navigator.pushNamed(context, '/reserved');
                        },
                      ),
                      _QuickButton(
                        icon: Icons.book,
                        label: "Request New Book",
                        onTap: () {
                          Navigator.pushNamed(context, '/request-book-details');
                        },
                      ),
                      _QuickButton(
                        icon: Icons.call,
                        label: "Contact Librarian",
                        onTap: () {
                          Navigator.pushNamed(context, '/contact-librarian');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 0),
    );
  }

  Widget _buildCarouselBookCard(Book book) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/book-detail',
            arguments: {
              'title': book.title,
              'author': book.author,
              'image': book.image,
              'description': 'Explore more about ${book.title}.',
              'available': book.dueColor == Colors.green,
              'isbn': book.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BookImage(
                book.image,
                width: 140,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                    Colors.white60,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                  Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/book-detail',
          arguments: {
            'title': book.title,
            'author': book.author,
            'image': book.image,
            'isbn': book.id,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BookImage(
                book.image,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      color:
                          Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                          Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: book.dueColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.dueLabel,
                      style: TextStyle(
                        color: book.dueColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0A84FF), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
