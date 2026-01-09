import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'book_service.dart';
import 'custom_app_bar.dart';
import 'role_bottom_nav.dart';

class UploadPdfPage extends StatefulWidget {
  const UploadPdfPage({super.key});

  @override
  State<UploadPdfPage> createState() => _UploadPdfPageState();
}

class _UploadPdfPageState extends State<UploadPdfPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBookTitle;
  int? _selectedBookId;
  String? _selectedRequestedBook;
  String _pdfUrl = '';
  bool _appliedRouteArgs = false;

  List<Book> _books = [];
  bool _loadingBooks = true;
  bool _submitting = false;

  final requestedBooks = [
    {
      'title': 'System Engineering',
      'isbn': '123512ASED',
      'author': 'Emily Davis',
    },
    {
      'title': 'Advanced Algorithms',
      'isbn': '234612AB',
      'author': 'Michael Chen',
    },
    {'title': 'Data Pipelines', 'isbn': '345713BC', 'author': 'Rahim Uddin'},
  ];

  late List<Map<String, dynamic>> pendingUploads;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    pendingUploads = [
      {
        'bookTitle': requestedBooks.isNotEmpty
            ? requestedBooks.first['title']!
            : 'Requested Book',
        'uploadType': 'Update',
        'status': 'Pending',
        'submittedDate': '2024-12-20',
        'notes': 'Updated edition with new chapters',
      },
      {
        'bookTitle': requestedBooks.length > 1
            ? requestedBooks[1]['title']!
            : 'Requested Book',
        'uploadType': 'New Request',
        'status': 'Approved',
        'submittedDate': '2024-12-18',
        'notes': 'PDF for newly requested book',
      },
      {
        'bookTitle': 'Machine Learning Basics',
        'uploadType': 'Update',
        'status': 'Rejected',
        'submittedDate': '2024-12-15',
        'notes': 'File format not supported',
      },
    ];
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await BookService.fetchBooks();
      setState(() {
        _books = books;
        _loadingBooks = false;

        if (_selectedBookTitle != null) {
          final match = books.firstWhere(
            (b) => b.title == _selectedBookTitle,
            orElse: () => books.isNotEmpty
                ? books.first
                : Book(id: 0, title: '', author: ''),
          );
          if (match.id != 0) {
            _selectedBookId = match.id;
            _selectedBookTitle = match.title;
          }
        }
      });
    } catch (e) {
      setState(() {
        _loadingBooks = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply route arguments (if any) once to preselect tab/book when navigated from Book Details
    if (!_appliedRouteArgs) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final mode = args['mode'] as String?;
        final bookTitle = args['bookTitle'] as String?;
        if (mode == 'update') {
          // try to select Update Existing tab (index 0) and preselect the book
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _tabController.animateTo(0);
              if (bookTitle != null) _selectedBookTitle = bookTitle;
            });
          });
        }
      }
      _appliedRouteArgs = true;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upload PDF",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Upload or update PDFs for library books",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0A84FF),
                  labelColor: const Color(0xFF0A84FF),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: "Update Existing"),
                    Tab(text: "Add to Request"),
                    Tab(text: "My Uploads"),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpdateExistingTab(),
                _buildAddToRequestTab(),
                _buildMyUploadsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RoleBottomNav(currentIndex: 1),
    );
  }

  Widget _buildUpdateExistingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2D35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Book",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: _loadingBooks
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Loading books...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : DropdownButton<int>(
                            value: _selectedBookId,
                            hint: const Text(
                              "Choose a book to update",
                              style: TextStyle(color: Colors.white54),
                            ),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2C2D35),
                            style: const TextStyle(color: Colors.white),
                            items: _books.map((book) {
                              return DropdownMenuItem<int>(
                                value: book.id,
                                child: Text(
                                  '${book.title} - ${book.isbn ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBookId = value;
                                _selectedBookTitle = _books
                                    .firstWhere((b) => b.id == value)
                                    .title;
                              });
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "PDF Upload",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Paste PDF URL or click to upload",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1B1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.upload_file,
                        color: Color(0xFF0A84FF),
                      ),
                      onPressed: () {
                        _showUploadDialog();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _pdfUrl = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "Notes (Optional)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add any notes about this update...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1B1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  // Removed onChanged callback for _notes
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedBookId != null && _pdfUrl.isNotEmpty
                        ? () {
                            _submitUpload('Update');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Submit for Approval",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(
                26,
              ), // Updated withOpacity to withAlpha
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withAlpha(77),
              ), // Updated withOpacity to withAlpha
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "All PDF uploads require librarian approval before being added to the library.",
                    style: TextStyle(color: Colors.blue.shade200, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2D35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Requested Book",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRequestedBook,
                      hint: const Text(
                        "Choose a requested book",
                        style: TextStyle(color: Colors.white54),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2C2D35),
                      style: const TextStyle(color: Colors.white),
                      items: requestedBooks.map((book) {
                        return DropdownMenuItem<String>(
                          value: book['title'],
                          child: Text(
                            '${book['title']} - ${book['isbn']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRequestedBook = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "PDF Upload",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Paste PDF URL or click to upload",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1B1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.upload_file,
                        color: Color(0xFF0A84FF),
                      ),
                      onPressed: () {
                        _showUploadDialog();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _pdfUrl = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "Notes (Optional)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add any notes about this PDF...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1B1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  // Removed onChanged callback for _notes
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedRequestedBook != null && _pdfUrl.isNotEmpty
                        ? () {
                            _submitUpload('New Request');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Submit for Approval",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(
                26,
              ), // Updated withOpacity to withAlpha
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withAlpha(77),
              ), // Updated withOpacity to withAlpha
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Upload PDFs for books you've requested. Librarian will review before adding to library.",
                    style: TextStyle(
                      color: Colors.orange.shade200,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyUploadsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingUploads.length,
      itemBuilder: (context, index) {
        final upload = pendingUploads[index];
        return _buildUploadCard(upload);
      },
    );
  }

  Widget _buildUploadCard(Map<String, dynamic> upload) {
    Color statusColor;
    IconData statusIcon;

    switch (upload['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

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
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  upload['bookTitle'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(
                    51,
                  ), // Updated withOpacity to withAlpha
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  upload['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Type: ${upload['uploadType']}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Submitted: ${upload['submittedDate']}",
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (upload['notes'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                upload['notes'],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D35),
        title: const Text("Upload PDF", style: TextStyle(color: Colors.white)),
        content: const Text(
          "File upload functionality will be implemented here. For now, please paste the PDF URL in the text field.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpload(String uploadType) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    ApiResponse result;
    if (uploadType == 'Update') {
      if (_selectedBookId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a book to update.')),
        );
        setState(() => _submitting = false);
        return;
      }
      result = await BookService.uploadPdf(
        bookId: _selectedBookId!,
        pdfUrl: _pdfUrl,
      );
    } else {
      result = await BookService.requestAddition(
        title: _selectedRequestedBook ?? 'Requested book',
        pdfPath: _pdfUrl,
      );
    }

    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? Colors.green : Colors.redAccent,
      ),
    );

    if (result.ok) {
      setState(() {
        _selectedBookId = null;
        _selectedBookTitle = null;
        _selectedRequestedBook = null;
        _pdfUrl = '';
      });
      _tabController.animateTo(2);
    }
  }
}
