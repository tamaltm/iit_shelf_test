import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'book_image.dart';
import 'book_service.dart';
import 'auth_service.dart';
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

class DirectorDashboardPage extends StatefulWidget {
  const DirectorDashboardPage({super.key});
  @override
  State<DirectorDashboardPage> createState() => _DirectorDashboardPageState();
}

class _DirectorDashboardPageState extends State<DirectorDashboardPage> {
  List<Book> _borrowedBooks = [];
  List<Book> _recommendedBooks = [];
  int _borrowedCount = 0;
  int _overdueCount = 0;
  double _outstandingFines = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final email = AuthService.getCurrentUserEmail();

    if (email == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final borrowedResponse = await BookService.getUserTransactions(
        email,
        status: 'borrowed',
      );
      final allBooksResponse = await BookService.fetchBooks();
      final fine = await PaymentService.fetchOutstandingFines();

      if (!mounted) return;

      setState(() {
        _borrowedBooks = borrowedResponse
            .map(
              (transaction) => Book(
                image: transaction['cover_image'] ?? '',
                title: transaction['title'] ?? 'Unknown',
                author: transaction['author'] ?? 'Unknown',
                dueLabel: 'Due: ${transaction['due_date'] ?? 'N/A'}',
                dueColor: _calculateDaysUntilDue(transaction['due_date']) < 0
                    ? Colors.red
                    : Colors.orange,
                id: transaction['isbn'] ?? transaction['id'].toString(),
                transactionId: transaction['id'] as int?,
              ),
            )
            .take(2)
            .toList();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _calculateDaysUntilDue(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return 0;
    try {
      final due = DateTime.parse(dueDate);
      return due.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CustomAppBar(userRole: 'director'),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const RoleBottomNav(
          currentIndex: 0,
          role: 'director',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(userRole: 'director'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard header removed per request
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Books Borrowed",
                    "$_borrowedCount/5",
                    Icons.menu_book,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Overdue",
                    "$_overdueCount",
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.red,
                          size: isSmallScreen ? 24 : 28,
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
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BDT ${_outstandingFines.toStringAsFixed(2)}',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color ??
                                    Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isSmallScreen) const SizedBox(height: 12),
                  if (isSmallScreen)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Pay Now",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (!isSmallScreen)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 400 ? 16 : 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Pay Now",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth < 400 ? 13 : 14,
                          ),
                        ),
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
                    Navigator.pushNamed(
                      context,
                      '/library',
                      arguments: {'userRole': 'director'},
                    );
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
                    Navigator.pushNamed(
                      context,
                      '/borrowed',
                      arguments: {'userRole': 'director'},
                    );
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xFF0A84FF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._borrowedBooks.map((book) => _buildBookCard(book)),

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
              crossAxisCount: isSmallScreen ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isSmallScreen
                  ? 3.5
                  : (screenWidth < 400 ? 1.3 : 1.5),
              children: [
                _QuickButton(
                  icon: Icons.bookmark_rounded,
                  label: "Reservations",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/reserved');
                  },
                ),
                _QuickButton(
                  icon: Icons.assessment,
                  label: "Generate Reports",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/generate-reports',
                      arguments: {'userRole': 'director'},
                    );
                  },
                ),
                _QuickButton(
                  icon: Icons.book,
                  label: "Request New Book",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/request-book-details');
                  },
                ),
                _QuickButton(
                  icon: Icons.call,
                  label: "Contact Librarian",
                  isSmallScreen: isSmallScreen,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
                width: isSmallScreen ? 50 : 60,
                height: isSmallScreen ? 75 : 90,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
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
                      fontSize: isSmallScreen ? 13 : 15,
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
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: book.dueColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.dueLabel,
                      style: TextStyle(
                        color: book.dueColor,
                        fontSize: isSmallScreen ? 10 : 12,
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
  final bool isSmallScreen;

  const _QuickButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isSmallScreen
            ? Row(
                children: [
                  Icon(icon, color: const Color(0xFF0A84FF), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
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
