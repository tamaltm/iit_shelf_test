import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_bottom_nav.dart';

class UploadPdfPage extends StatefulWidget {
  const UploadPdfPage({super.key});

  @override
  State<UploadPdfPage> createState() => _UploadPdfPageState();
}

class _UploadPdfPageState extends State<UploadPdfPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBook;
  String? _selectedRequestedBook;
  String _pdfUrl = '';

  final List<Map<String, String>> existingBooks = [
    {'title': 'Foundations of Data Science', 'isbn': '123512ASED', 'author': 'John Doe'},
    {'title': 'Introduction to AI', 'isbn': '234612AB', 'author': 'Jane Smith'},
    {'title': 'Machine Learning Basics', 'isbn': '345713BC', 'author': 'Sarah Johnson'},
    {'title': 'Database Management', 'isbn': '456814CD', 'author': 'Robert Wilson'},
  ];

  final List<Map<String, String>> requestedBooks = [
    {'title': 'Introduction to Quantum Computing', 'isbn': '123512ASED', 'author': 'Robert Johnson'},
    {'title': 'System Engineering', 'isbn': '234612AB', 'author': 'Emily Davis'},
    {'title': 'Advanced Algorithms', 'isbn': '345713BC', 'author': 'Michael Chen'},
  ];

  final List<Map<String, dynamic>> pendingUploads = [
    {
      'bookTitle': 'Foundations of Data Science',
      'uploadType': 'Update',
      'status': 'Pending',
      'submittedDate': '2024-12-20',
      'notes': 'Updated edition with new chapters',
    },
    {
      'bookTitle': 'Introduction to Quantum Computing',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(),
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
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
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
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
                    child: DropdownButton<String>(
                      value: _selectedBook,
                      hint: const Text(
                        "Choose a book to update",
                        style: TextStyle(color: Colors.white54),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2C2D35),
                      style: const TextStyle(color: Colors.white),
                      items: existingBooks.map((book) {
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
                          _selectedBook = value;
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
                      icon: const Icon(Icons.upload_file, color: Color(0xFF0A84FF)),
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
                    onPressed: _selectedBook != null && _pdfUrl.isNotEmpty
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
              color: Colors.blue.withAlpha(26), // Updated withOpacity to withAlpha
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(77)), // Updated withOpacity to withAlpha
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "All PDF uploads require librarian approval before being added to the library.",
                    style: TextStyle(
                      color: Colors.blue.shade200,
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
                      icon: const Icon(Icons.upload_file, color: Color(0xFF0A84FF)),
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
                    onPressed: _selectedRequestedBook != null && _pdfUrl.isNotEmpty
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
              color: Colors.orange.withAlpha(26), // Updated withOpacity to withAlpha
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(77)), // Updated withOpacity to withAlpha
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(51), // Updated withOpacity to withAlpha
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Submitted: ${upload['submittedDate']}",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
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
        title: const Text(
          "Upload PDF",
          style: TextStyle(color: Colors.white),
        ),
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

  void _submitUpload(String uploadType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D35),
        title: const Text(
          "Upload Submitted",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Your PDF upload for ${uploadType == 'Update' ? _selectedBook : _selectedRequestedBook} has been submitted for librarian approval.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedBook = null;
                _selectedRequestedBook = null;
                _pdfUrl = '';
                // Removed setting _notes to empty string
                _tabController.animateTo(2);
              });
            },
            child: const Text("View My Uploads"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
