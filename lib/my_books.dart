import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'book_image.dart';
import 'book_service.dart';

class BookHistoryPage extends StatelessWidget {
  const BookHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                const _TabButton(label: "History", active: true, onTap: null),
                _TabButton(
                  label: "Borrowed",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/borrowed');
                  },
                ),
                _TabButton(
                  label: "Returned",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/returned');
                  },
                ),
                _TabButton(
                  label: "Reserved",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/reserved');
                  },
                ),
              ],
            ),
          ),
          const Expanded(child: BookHistoryList()),
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class BookHistoryList extends StatefulWidget {
  const BookHistoryList({super.key});

  @override
  State<BookHistoryList> createState() => _BookHistoryListState();
}

class _BookHistoryListState extends State<BookHistoryList> {
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
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
        status: 'all',
      );
      if (mounted) {
        setState(() {
          _allTransactions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transaction history';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_allTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No transaction history',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _allTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _allTransactions[index];

        // Determine label and color based on transaction type
        String dueLabel = '';
        Color dueColor = Colors.grey;

        if (transaction['type'] == 'borrowed' ||
            transaction['type'] == 'overdue') {
          final daysUntilDue = _calculateDaysUntilDue(transaction['due_date']);
          if (daysUntilDue > 0) {
            dueLabel = "Due in $daysUntilDue days";
            dueColor = daysUntilDue <= 3 ? Colors.red : Colors.teal;
          } else {
            dueLabel = "Overdue by ${daysUntilDue.abs()} days";
            dueColor = Colors.red;
          }
        } else if (transaction['type'] == 'returned') {
          final daysSinceReturn = _calculateDaysSinceReturn(
            transaction['return_date'],
          );
          dueLabel = "Returned $daysSinceReturn days ago";
          dueColor = Colors.grey;
        } else if (transaction['type'] == 'reserved') {
          dueLabel = "Expected: ${transaction['expiry_date']}";
          dueColor = Colors.orange;
        } else if (transaction['type'] == 'pending') {
          final hoursRemaining = transaction['expires_in_hours'] ?? 0;
          final minutesRemaining = transaction['expires_in_minutes'] ?? 0;
          final isExpired = transaction['is_expired'] ?? false;

          if (isExpired) {
            dueLabel = "Request expired";
            dueColor = Colors.red;
          } else if (hoursRemaining > 0) {
            dueLabel = "Expires in ${hoursRemaining}h ${minutesRemaining}m";
            dueColor = hoursRemaining < 6 ? Colors.orange : Colors.blue;
          } else {
            dueLabel = "Expires in ${minutesRemaining}m";
            dueColor = Colors.red;
          }
        }

        return BookHistoryCard(
          image: transaction['pic_path'] ?? '',
          title: transaction['title'] ?? 'Unknown Title',
          author: transaction['author'] ?? 'Unknown Author',
          dueLabel: dueLabel,
          dueColor: dueColor,
          id: transaction['isbn'] ?? '',
        );
      },
    );
  }

  int _calculateDaysUntilDue(String? dueDate) {
    if (dueDate == null) return 0;
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      return due.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  int _calculateDaysSinceReturn(String? returnDate) {
    if (returnDate == null) return 0;
    try {
      final returned = DateTime.parse(returnDate);
      final now = DateTime.now();
      return now.difference(returned).inDays;
    } catch (e) {
      return 0;
    }
  }
}

class BookHistoryCard extends StatelessWidget {
  final String image, title, author, dueLabel, id;
  final Color dueColor;

  const BookHistoryCard({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.dueLabel,
    required this.dueColor,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);
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
                    width: 54,
                    height: 60,
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
                      Text(
                        dueLabel,
                        style: TextStyle(
                          color: dueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.cloud_download,
                      color: Colors.white,
                      size: 22,
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
                          'available': false,
                          'isbn': id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      "Details",
                      style: TextStyle(color: Colors.white),
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
