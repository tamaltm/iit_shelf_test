import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';
import 'auth_service.dart';
import 'book_image.dart';
import 'book_service.dart';

class ReservedBooksPage extends StatefulWidget {
  const ReservedBooksPage({super.key});

  @override
  State<ReservedBooksPage> createState() => _ReservedBooksPageState();
}

class _ReservedBooksPageState extends State<ReservedBooksPage> {
  List<Map<String, dynamic>> _reservedBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservedBooks();
  }

  Future<void> _loadReservedBooks() async {
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
        status: 'reserved',
      );
      if (mounted) {
        setState(() {
          _reservedBooks = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reserved books';
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
                _TabButton(
                  label: "Returned",
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/returned'),
                ),
                _TabButton(label: "Reserved", active: true, onTap: null),
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
                : _reservedBooks.isEmpty
                ? const Center(
                    child: Text(
                      'No reserved books',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _reservedBooks.length,
                    itemBuilder: (context, index) {
                      final book = _reservedBooks[index];
                      return ReservedBookCard(
                        image: book['pic_path'] ?? '',
                        title: book['title'] ?? 'Unknown Title',
                        author: book['author'] ?? 'Unknown Author',
                        expected: book['expiry_date'] ?? '',
                        reservationId: book['reservation_id'],
                        isbn: book['isbn'],
                        onCancelled: _loadReservedBooks,
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

class ReservedBookCard extends StatelessWidget {
  final String image, title, author, expected;
  final int? reservationId;
  final VoidCallback onCancelled;
  final String? isbn;

  const ReservedBookCard({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.expected,
    this.reservationId,
    required this.onCancelled,
    this.isbn,
  });

  Future<void> _cancelReservation(BuildContext context) async {
    if (reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot cancel: Invalid reservation')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF22232A),
          title: const Text(
            'Cancel Reservation',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to cancel your reservation for "$title"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final email = AuthService.getCurrentUserEmail();
      if (email == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        }
        return;
      }

      final result = await BookService.cancelReservation(
        reservationId: reservationId!,
        userEmail: email,
      );

      if (context.mounted) {
        if (result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reservation for "$title" cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          onCancelled(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
                          color: Colors.brown,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expected,
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
                const Icon(Icons.cloud_download, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelReservation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "Cancel Queue",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
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
                          if (isbn != null && isbn!.isNotEmpty) 'isbn': isbn,
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
