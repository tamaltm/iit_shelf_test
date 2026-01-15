import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String? userRole;

  const TransactionHistoryPage({
    super.key,
    this.userRole,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String selectedFilter = 'All';
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController searchController = TextEditingController();
  
  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      final params = {
        'filter': selectedFilter,
        'search': searchController.text,
      };
      
      if (startDate != null) {
        params['start_date'] = '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
      }
      
      if (endDate != null) {
        params['end_date'] = '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
      }
      
      final uri = Uri.parse('$_baseUrl/librarian/get_transaction_history.php').replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            transactions = (data['transactions'] as List).map((t) {
              // Add icon and color based on type
              IconData icon;
              Color color;
              
              switch (t['type']) {
                case 'Borrow':
                  icon = Icons.book;
                  color = Colors.blue;
                  break;
                case 'Return':
                  icon = Icons.assignment_return;
                  color = Colors.green;
                  break;
                case 'Fine Payment':
                  icon = Icons.payment;
                  color = Colors.orange;
                  break;
                case 'Reservation':
                  icon = Icons.bookmark;
                  color = Colors.purple;
                  break;
                default:
                  icon = Icons.info;
                  color = Colors.grey;
              }
              
              return {
                'type': t['type'],
                'bookTitle': t['book_title'] ?? 'Unknown',
                'userId': t['user_id'] ?? '',
                'userName': t['user_name'] ?? 'Unknown',
                'date': t['date'] ?? '',
                'time': t['time'] ?? '',
                'status': t['status'] ?? '',
                'amount': t['amount'],
                'icon': icon,
                'color': color,
              };
            }).toList();
            _isLoading = false;
          });
        } else {
          _showError('Failed to load transactions');
        }
      } else {
        _showError('Failed to connect to server');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
  appBar: CustomAppBar(userRole: widget.userRole ?? AuthService.getCurrentUserRole()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2C2D35),
            child: Column(
              children: [
                // Search Bar with export button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by user ID or book title...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1A1B1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          _loadTransactions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.file_download, color: Colors.white),
                      onPressed: _showExportDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Borrow'),
                      _buildFilterChip('Return'),
                      _buildFilterChip('Fine Payment'),
                      _buildFilterChip('Reservation'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date Range Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        'Start Date',
                        startDate,
                        () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        'End Date',
                        endDate,
                        () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Transaction List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredTransactions().length,
              itemBuilder: (context, index) {
                final transaction = _getFilteredTransactions()[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
  ),
  bottomNavigationBar: RoleBottomNav(currentIndex: 3, role: widget.userRole),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = label;
          });
          _loadTransactions();
        },
        backgroundColor: const Color(0xFF1A1B1E),
        selectedColor: const Color(0xFF0A84FF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.white : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: transaction['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  transaction['icon'],
                  color: transaction['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['type'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction['bookTitle'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _getStatusColor(transaction['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction['status'],
                  style: TextStyle(
                    color: _getStatusColor(transaction['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.person, 'User', transaction['userName']),
              ),
              Expanded(
                child: _buildInfoRow(Icons.badge, 'ID', transaction['userId']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.calendar_today, 'Date', transaction['date']),
              ),
              Expanded(
                child: _buildInfoRow(Icons.access_time, 'Time', transaction['time']),
              ),
            ],
          ),
          if (transaction['amount'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Amount', transaction['amount']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    // Filtering is done server-side, just return all transactions
    return transactions;
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0A84FF),
              surface: Color(0xFF2C2D35),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
      _loadTransactions();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D35),
        title: const Text(
          'Export Transaction History',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as CSV...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
