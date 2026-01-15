import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'book_image.dart';
import 'book_service.dart';

class BookHistoryPage extends StatefulWidget {
  const BookHistoryPage({super.key});

  @override
  State<BookHistoryPage> createState() => _BookHistoryPageState();
}

class _BookHistoryPageState extends State<BookHistoryPage> {
  String _activeTab = 'borrowed';
  List<Map<String, dynamic>> _borrowedBooks = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _reservedBooks = [];
  List<Map<String, dynamic>> _returnedBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
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
          _borrowedBooks = response
              .where(
                (t) => t['status'] == 'Borrowed' || t['status'] == 'Overdue',
              )
              .toList();

          _pendingRequests = response
              .where((t) => t['status'] == 'Pending' || t['status'] == 'Pending Return')
              .toList();

          _returnedBooks = response
              .where((t) => t['status'] == 'Returned')
              .toList();

          _isLoading = false;
        });
      }

      // Load reservations separately
      try {
        final reservations = await BookService.getUserReservations(email);
        if (mounted) {
          setState(() {
            _reservedBooks = reservations;
          });
        }
      } catch (e) {
        // Reservations failed but don't block other data
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAllData, child: const Text('Retry')),
          ],
        ),
      );
    }

    switch (_activeTab) {
      case 'borrowed':
        return _buildBorrowedList();
      case 'pending':
        return _buildPendingList();
      case 'reserved':
        return _buildReservedList();
      case 'returned':
        return _buildReturnedList();
      default:
        return const Center(child: Text('Invalid tab'));
    }
  }

  Widget _buildBorrowedList() {
    if (_borrowedBooks.isEmpty) {
      return const Center(
        child: Text('No borrowed books', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _borrowedBooks.length,
        itemBuilder: (context, index) {
          final book = _borrowedBooks[index];
          final dueDateStr = book['due_date'];
          final dueDate = dueDateStr != null
              ? DateTime.parse(dueDateStr)
              : DateTime.now();
          final daysRemaining = dueDate.difference(DateTime.now()).inDays;
          final isOverdue = daysRemaining < 0;
          final coverImage = (book['cover'] ?? book['pic_path']) ?? '';

          return _BookCard(
            title: book['title'] ?? 'Unknown',
            author: book['author'] ?? 'Unknown',
            isbn: book['isbn'] ?? '',
            cover: coverImage.isNotEmpty
                ? coverImage
                : 'assets/book_placeholder.png',
            status: isOverdue ? 'Overdue' : 'Borrowed',
            statusColor: isOverdue ? Colors.red : Colors.green,
            subtitle: isOverdue
                ? 'Overdue by ${daysRemaining.abs()} days'
                : 'Due in $daysRemaining days',
            dueDate: book['due_date'],
            showRequestReturn: true,
            onRequestReturn: () async {
              await _requestReturn(book['transaction_id'] ?? 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Text(
          'No pending requests',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final book = _pendingRequests[index];
          final createdAtStr = book['created_at'] ?? book['request_date'];
          final requestDate = createdAtStr != null
              ? DateTime.parse(createdAtStr)
              : DateTime.now();
          final daysSinceRequest = DateTime.now()
              .difference(requestDate)
              .inDays;
          final coverImage = (book['cover'] ?? book['pic_path']) ?? '';
          final isPendingReturn = book['status'] == 'Pending Return';

          return _BookCard(
            title: book['title'] ?? 'Unknown',
            author: book['author'] ?? 'Unknown',
            isbn: book['isbn'] ?? '',
            cover: coverImage,
            status: isPendingReturn ? 'Return Pending' : 'Pending',
            statusColor: Colors.orange,
            subtitle: daysSinceRequest == 0
                ? 'Requested today'
                : 'Requested $daysSinceRequest days ago',
            showCancel: !isPendingReturn,
            onCancel: !isPendingReturn ? () async {
              await _cancelRequest(
                book['transaction_id'] ?? book['request_id'] ?? 0,
              );
            } : null,
          );
        },
      ),
    );
  }

  Widget _buildReservedList() {
    if (_reservedBooks.isEmpty) {
      return const Center(
        child: Text('No reserved books', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _reservedBooks.length,
        itemBuilder: (context, index) {
          final reservation = _reservedBooks[index];
          final queuePosition =
              reservation['queuePosition'] ??
              reservation['queue_position'] ??
              0;
          final isReady = reservation['isReady'] ?? false;
          final coverImage =
              (reservation['cover'] ?? reservation['pic_path']) ?? '';

          String subtitle;
          if (isReady) {
            final hoursRemaining = reservation['hoursRemaining'] ?? 0;
            subtitle = 'Ready for pickup - $hoursRemaining hours remaining';
          } else {
            subtitle = 'Position in queue: #$queuePosition';
          }

          return _BookCard(
            title: reservation['title'] ?? 'Unknown',
            author: reservation['author'] ?? 'Unknown',
            isbn: reservation['isbn'] ?? '',
            cover: coverImage,
            status: isReady ? 'Ready' : 'Reserved',
            statusColor: isReady ? Colors.blue : Colors.purple,
            subtitle: subtitle,
            showCancel: true,
            onCancel: () async {
              await _cancelReservation(
                reservation['reservationId'] ??
                    reservation['reservation_id'] ??
                    0,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReturnedList() {
    if (_returnedBooks.isEmpty) {
      return const Center(
        child: Text('No returned books', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _returnedBooks.length,
        itemBuilder: (context, index) {
          final book = _returnedBooks[index];
          final returnDateStr = book['return_date'];
          final dueDateStr = book['due_date'];
          
          final returnDate = returnDateStr != null
              ? DateTime.parse(returnDateStr)
              : null;
          final dueDate = dueDateStr != null
              ? DateTime.parse(dueDateStr)
              : null;
          
          // Calculate if returned on time
          int daysLate = 0;
          String statusText = 'Returned On Time';
          Color statusColor = Colors.green;
          
          if (returnDate != null && dueDate != null) {
            daysLate = returnDate.difference(dueDate).inDays;
            if (daysLate > 0) {
              statusText = 'Late by $daysLate ${daysLate == 1 ? 'day' : 'days'}';
              statusColor = Colors.orange;
            }
          }
          
          final coverImage = (book['cover'] ?? book['pic_path']) ?? '';
          final fineAmount = book['fine_amount'] != null 
              ? double.tryParse(book['fine_amount'].toString()) ?? 0.0
              : 0.0;
          final finePaid = book['fine_paid'] == 1 || book['fine_paid'] == true;

          return _BookCard(
            title: book['title'] ?? 'Unknown',
            author: book['author'] ?? 'Unknown',
            isbn: book['isbn'] ?? '',
            cover: coverImage,
            status: statusText,
            statusColor: statusColor,
            subtitle: 'Returned: ${returnDate?.toLocal().toString().split(' ')[0] ?? 'Unknown date'}',
            fineAmount: fineAmount,
            finePaid: finePaid,
          );
        },
      ),
    );
  }

  Future<void> _requestReturn(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Return'),
          content: const Text('Are you sure you want to request to return this book?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        final response = await BookService.requestReturn(transactionId: transactionId);
        if (response.ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Return request submitted')),
            );
            await _loadAllData();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response.message}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting return request: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelRequest(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this pending request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        final email = AuthService.getCurrentUserEmail();
        if (email != null) {
          final response = await BookService.cancelBorrowRequest(
            email,
            transactionId,
          );
          if (response.ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request cancelled successfully')),
            );
            await _loadAllData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel: ${response.message}')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
      }
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Reservation'),
          content: const Text('Are you sure you want to cancel this reservation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        final email = AuthService.getCurrentUserEmail();
        if (email != null) {
          final response = await BookService.cancelReservation(
            reservationId: reservationId,
            userEmail: email,
          );
          if (response.ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reservation cancelled successfully')),
            );
            await _loadAllData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel: ${response.message}')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
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
                _TabButton(
                  label: "Borrowed (${_borrowedBooks.length})",
                  active: _activeTab == 'borrowed',
                  onTap: () => setState(() => _activeTab = 'borrowed'),
                ),
                _TabButton(
                  label: "Pending (${_pendingRequests.length})",
                  active: _activeTab == 'pending',
                  onTap: () => setState(() => _activeTab = 'pending'),
                ),
                _TabButton(
                  label: "Reserved (${_reservedBooks.length})",
                  active: _activeTab == 'reserved',
                  onTap: () => setState(() => _activeTab = 'reserved'),
                ),
                _TabButton(
                  label: "Returned",
                  active: _activeTab == 'returned',
                  onTap: () => setState(() => _activeTab = 'returned'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildTabContent()),
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

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String isbn;
  final String? cover;
  final String status;
  final Color statusColor;
  final String subtitle;
  final String? dueDate;
  final bool showRequestReturn;
  final bool showCancel;
  final VoidCallback? onRequestReturn;
  final VoidCallback? onCancel;
  final double fineAmount;
  final bool finePaid;

  const _BookCard({
    required this.title,
    required this.author,
    required this.isbn,
    this.cover,
    required this.status,
    required this.statusColor,
    required this.subtitle,
    this.dueDate,
    this.showRequestReturn = false,
    this.showCancel = false,
    this.onRequestReturn,
    this.onCancel,
    this.fineAmount = 0.0,
    this.finePaid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF22232A),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book info section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/book-detail',
                      arguments: {
                        'isbn': isbn,
                        'title': title,
                        'author': author,
                        'cover': cover,
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BookImage(
                      cover ?? '',
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/book-detail',
                            arguments: {
                              'isbn': isbn,
                              'title': title,
                              'author': author,
                              'cover': cover,
                            },
                          );
                        },
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (fineAmount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: finePaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: finePaid ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            '${finePaid ? '✓' : '💳'} Fine: ${fineAmount.toStringAsFixed(2)} BDT ${finePaid ? '(Paid)' : '(Unpaid)'}',
                            style: TextStyle(
                              color: finePaid ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Action buttons section
            if (showRequestReturn || showCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (showRequestReturn)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRequestReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Request Return',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  if (showCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
