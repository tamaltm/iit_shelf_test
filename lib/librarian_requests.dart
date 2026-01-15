import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'custom_app_bar.dart';
import 'book_service.dart';

class LibrarianRequestsPage extends StatefulWidget {
  const LibrarianRequestsPage({super.key});

  @override
  State<LibrarianRequestsPage> createState() => _LibrarianRequestsPageState();
}

class _LibrarianRequestsPageState extends State<LibrarianRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Data lists
  List<Map<String, dynamic>> _borrowRequests = [];
  List<Map<String, dynamic>> _returnRequests = [];
  List<Map<String, dynamic>> _reserveRequests = [];
  List<Map<String, dynamic>> _additionRequests = [];

  // Track optional damage fines/conditions keyed by transaction id
  final Map<int, Map<String, dynamic>> _damageNotes = {};

  bool _approvingBorrow = false;

  bool _loading = true;
  String? _error;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final search = _searchController.text.trim();
      final borrow = await _fetch('borrow', search);
      final ret = await _fetch('return', search);
      final reserve = await _fetch('reserve', search);
      final addition = await _fetch('addition', search);

      if (!mounted) return;
      setState(() {
        _borrowRequests = borrow;
        _returnRequests = ret;
        _reserveRequests = reserve;
        _additionRequests = addition;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load requests: $e';
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(String type, String search) async {
    final uri = Uri.parse('$_baseUrl/librarian/get_requests.php').replace(
      queryParameters: {'type': type, if (search.isNotEmpty) 'search': search},
    );
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = json.decode(resp.body) as Map<String, dynamic>;
      if (decoded['success'] == true && decoded['items'] is List) {
        return (decoded['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw decoded['message'] ?? 'Unknown error';
    }
    throw 'HTTP ${resp.statusCode}';
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableCopies(String isbn) async {
    final uri = Uri.parse('$_baseUrl/librarian/get_available_copies.php')
        .replace(queryParameters: {'isbn': isbn});
    final resp = await http.get(uri);
    final decoded = json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 &&
        resp.statusCode < 300 &&
        decoded['success'] == true &&
        decoded['copies'] is List) {
      return (decoded['copies'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw decoded['message'] ?? 'Failed to load copies';
  }

  Future<void> _approveBorrowWithCopy(int requestId, String copyId) async {
    final uri = Uri.parse('$_baseUrl/librarian/approve_borrow_request.php');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'request_id': requestId, 'copy_id': copyId}),
    );
    final decoded = json.decode(resp.body);
    if (resp.statusCode >= 200 &&
        resp.statusCode < 300 &&
        decoded['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Approved. Copy ${decoded['copy_id'] ?? copyId} issued'),
        ),
      );
      await _loadAll();
    } else {
      throw decoded['message'] ?? 'Failed to approve';
    }
  }

  Future<void> _rejectBorrowRequest(int requestId) async {
    final uri = Uri.parse('$_baseUrl/librarian/reject_borrow_request.php');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'request_id': requestId}),
    );
    final decoded = json.decode(resp.body);
    if (resp.statusCode >= 200 &&
        resp.statusCode < 300 &&
        decoded['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
      await _loadAll();
    } else {
      throw decoded['message'] ?? 'Failed to reject';
    }
  }

  Future<void> _approveReturn(
    int transactionId, {
    double? damageFine,
    String? bookCondition,
  }) async {
    final res = await BookService.returnBook(
      transactionId: transactionId,
      damageFine: damageFine,
      bookCondition: bookCondition,
    );
    if (!mounted) return;
    if (res.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Return approved')));
      await _loadAll();
      setState(() {
        _damageNotes.remove(transactionId);
      });
    } else {
      throw res.message;
    }
  }

  Future<void> _promptDamageFine(int transactionId) async {
    final existing = _damageNotes[transactionId];
    final controller = TextEditingController(
      text: existing != null ? (existing['fine']?.toString() ?? '') : '',
    );
    String condition = existing != null
        ? (existing['condition']?.toString() ?? 'damaged')
        : 'damaged';

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2D35),
          title: const Text(
            'Damage / Lost Fine',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Fine amount (BDT)',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g. 150',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: condition,
                dropdownColor: const Color(0xFF2C2D35),
                decoration: const InputDecoration(
                  labelText: 'Book condition',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'damaged',
                    child: Text('Damaged', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'discarded',
                    child:
                        Text('Discarded', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'lost',
                    child: Text('Lost', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (v) {
                  condition = v ?? 'damaged';
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amt = double.tryParse(controller.text.trim());
                if (amt == null || amt < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid non-negative amount'),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop({'fine': amt, 'condition': condition});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _damageNotes[transactionId] = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: const CustomAppBar(userRole: 'librarian'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Requests",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF0A84FF),
                  labelColor: const Color(0xFF0A84FF),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: "Borrow"),
                    Tab(text: "Return"),
                    Tab(text: "Reserve"),
                    Tab(text: "Addition"),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by Name or Email",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2C2D35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: _searchController,
                  onSubmitted: (_) => _loadAll(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBorrowTab(),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildReturnTab(),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildReserveTab(),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAdditionTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildBorrowTab() {
    if (_borrowRequests.isEmpty) {
      return const Center(
        child: Text(
          'No pending borrow requests',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _borrowRequests.length,
      itemBuilder: (context, index) {
        final r = _borrowRequests[index];
        
        // Calculate expiration info
        final hoursRemaining = r['expires_in_hours'] ?? 0;
        final minutesRemaining = r['expires_in_minutes'] ?? 0;
        final isExpired = r['is_expired'] ?? false;
        
        String expirationText = '';
        if (isExpired) {
          expirationText = 'EXPIRED';
        } else if (hoursRemaining > 0) {
          expirationText = 'Expires in ${hoursRemaining}h ${minutesRemaining}m';
        } else {
          expirationText = 'Expires in ${minutesRemaining}m';
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBorrowRequestCard(
            r['name'] ?? 'User',
            r['email'] ?? '',
            'Request to Borrow',
            r['title'] ?? 'Unknown',
            r['isbn'] ?? '',
            _timeAgo(r['request_date']),
            expirationText: expirationText,
            isExpired: isExpired,
            onApprove: () => _promptCopySelection(r),
            onReject: () => _rejectBorrowRequestWithConfirmation(int.tryParse(r['request_id']?.toString() ?? '0') ?? 0),
          ),
        );
      },
    );
  }

  Future<void> _promptCopySelection(Map<String, dynamic> request) async {
    if (_approvingBorrow) return;
    final isbn = request['isbn']?.toString() ?? '';
    final requestId = int.tryParse(request['request_id']?.toString() ?? '');

    if (isbn.isEmpty || requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request data missing ISBN or ID')),
      );
      return;
    }

    setState(() {
      _approvingBorrow = true;
    });

    try {
      final copies = await _fetchAvailableCopies(isbn);

      if (!mounted) return;

      if (copies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available copies to lend.')),
        );
        return;
      }

      final selected = await showDialog<String>(
        context: context,
        builder: (context) {
          String current = copies.first['copy_id']?.toString() ?? '';
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2D35),
            title: const Text(
              'Select Copy',
              style: TextStyle(color: Colors.white),
            ),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return DropdownButtonFormField<String>(
                  value: current.isNotEmpty ? current : null,
                  dropdownColor: const Color(0xFF2C2D35),
                  decoration: const InputDecoration(
                    labelText: 'Copy ID',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0A84FF)),
                    ),
                  ),
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  items: copies.map((c) {
                    final cid = c['copy_id']?.toString() ?? '';
                    final shelf = c['shelf_id']?.toString() ?? '';
                    final compartment = c['compartment_no']?.toString() ?? '';
                    final sub = c['subcompartment_no']?.toString() ?? '';
                    final label = [
                      cid,
                      if (shelf.isNotEmpty) 'Shelf $shelf',
                      if (compartment.isNotEmpty) 'Comp $compartment',
                      if (sub.isNotEmpty) 'Sub $sub',
                    ].join(' · ');
                    return DropdownMenuItem<String>(
                      value: cid,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      current = val ?? '';
                    });
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(current),
                child: const Text('Approve'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (selected != null && selected.isNotEmpty) {
        await _approveBorrowWithCopy(requestId, selected);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not approve: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _approvingBorrow = false;
        });
      }
    }
  }

  Future<void> _rejectBorrowRequestWithConfirmation(int requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: const Text('Are you sure you want to reject this borrow request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        await _rejectBorrowRequest(requestId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reject: $e')),
        );
      }
    }
  }

  Widget _buildReturnTab() {
    if (_returnRequests.isEmpty) {
      return const Center(
        child: Text(
          'No return approvals pending',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _returnRequests.length,
      itemBuilder: (context, index) {
        final r = _returnRequests[index];
        final fine =
            (r['days_overdue'] is int
                ? r['days_overdue']
                : int.tryParse(r['days_overdue']?.toString() ?? '0')) ??
            0;
        final fineTk = (fine * 5).toStringAsFixed(2);
        final txnId = int.parse(r['transaction_id'].toString());
        final damage = _damageNotes[txnId];
        final damageLabel = damage == null
            ? 'Damaged Fine (If any)'
            : 'Damage: BDT ${damage['fine']} (${damage['condition']})';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildReturnRequestCard(
            r['name'] ?? 'User',
            r['email'] ?? '',
            'Request to Return',
            r['title'] ?? 'Unknown',
            r['isbn'] ?? '',
            'BDT $fineTk',
            _timeAgo(r['due_date']),
            damageLabel: damageLabel,
            onSetDamage: () => _promptDamageFine(txnId),
            onApprove: () => _approveReturn(
              txnId,
              damageFine:
                  damage != null ? (damage['fine'] as double? ?? 0.0) : null,
              bookCondition:
                  damage != null ? damage['condition']?.toString() : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReserveTab() {
    if (_reserveRequests.isEmpty) {
      return const Center(
        child: Text(
          'No active reservations',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reserveRequests.length,
      itemBuilder: (context, index) {
        final r = _reserveRequests[index];
        final pos = r['queue_position']?.toString() ?? '-';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildReserveRequestCard(
            r['name'] ?? 'User',
            r['email'] ?? '',
            'Joined Queue at $pos',
            r['title'] ?? 'Unknown',
            r['isbn'] ?? '',
            _timeAgo(r['created_at']),
          ),
        );
      },
    );
  }

  Widget _buildAdditionTab() {
    if (_additionRequests.isEmpty) {
      return const Center(
        child: Text(
          'No pending addition requests',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _additionRequests.length,
      itemBuilder: (context, index) {
        final r = _additionRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAdditionRequestCard(
            r['name'] ?? 'User',
            r['email'] ?? r['email'] ?? '',
            'Request to Add',
            r['requested_title'] ?? r['title'] ?? 'Unknown',
            _timeAgo(
              r['approved_at'] ?? r['created_at'] ?? DateTime.now().toString(),
            ),
            requestId: r['request_id'],
          ),
        );
      },
    );
  }

  Widget _buildBorrowRequestCard(
    String userName,
    String userEmail,
    String requestType,
    String bookName,
    String isbn,
    String time, {
    String? expirationText,
    bool isExpired = false,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
        border: isExpired ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning : Icons.info_outline,
                color: isExpired ? Colors.red : const Color(0xFF0A84FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (expirationText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      expirationText,
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Approve",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Reject",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnRequestCard(
    String userName,
    String userEmail,
    String requestType,
    String bookName,
    String isbn,
    String fine,
    String time, {
    String damageLabel = 'Damaged Fine (If any)',
    VoidCallback? onSetDamage,
    VoidCallback? onApprove,
  }) {
    return Container(
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF0A84FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            "Late Fine: $fine",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSetDamage,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    damageLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Approve",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveRequestCard(
    String userName,
    String userEmail,
    String queueInfo,
    String bookName,
    String isbn,
    String time,
  ) {
    return Container(
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
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            queueInfo,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "ISBN: $isbn",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Request",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return 'Recently';
    try {
      final d = DateTime.parse(ts.toString());
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  Widget _buildAdditionRequestCard(
    String userName,
    String userEmail,
    String requestType,
    String bookName,
    String time, {
    dynamic requestId,
  }) {
    return Container(
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF0A84FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requestType,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Book Name: $bookName",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: requestId != null
                  ? () {
                      Navigator.pushNamed(
                        context,
                        '/librarian-addition-request-details',
                        arguments: {
                          'request_id': requestId,
                        },
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Request",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, "Dashboard", activeIndex == 0, () {
                Navigator.pushReplacementNamed(context, '/librarian-dashboard');
              }),
              _buildNavItem(
                Icons.inventory_2,
                "Inventory",
                activeIndex == 1,
                () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/librarian-inventory',
                  );
                },
              ),
              _buildNavItem(Icons.assessment, "Reports", activeIndex == 2, () {
                Navigator.pushReplacementNamed(context, '/librarian-reports');
              }),
              _buildNavItem(
                Icons.request_page,
                "Requests",
                activeIndex == 3,
                () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/librarian-requests',
                  );
                },
              ),
              _buildNavItem(Icons.person, "Profile", activeIndex == 4, () {
                Navigator.pushReplacementNamed(context, '/librarian-profile');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF0A84FF) : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF0A84FF) : Colors.white54,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
