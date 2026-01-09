import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import 'book_service.dart';
import 'edit_addition_request.dart';

class LibrarianAdditionRequestDetailsPage extends StatefulWidget {
  final int requestId;
  const LibrarianAdditionRequestDetailsPage({Key? key, required this.requestId})
    : super(key: key);

  @override
  State<LibrarianAdditionRequestDetailsPage> createState() =>
      _LibrarianAdditionRequestDetailsPageState();
}

class _LibrarianAdditionRequestDetailsPageState
    extends State<LibrarianAdditionRequestDetailsPage> {
  Map<String, dynamic>? request;
  bool loading = true;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
    });
    final data = await BookService.getAdditionRequestDetails(widget.requestId);
    setState(() {
      request = (data != null && data.isNotEmpty) ? data.first : null;
      loading = false;
    });
  }

  Future<void> _downloadPdf(String pdfPath) async {
    // Build full URL using serve_image.php
    String fullUrl = pdfPath;
    if (!pdfPath.startsWith('http')) {
      // Use serve_image.php to serve the PDF
      fullUrl = 'http://localhost:8000/serve_image.php?path=$pdfPath';
    }

    final uri = Uri.parse(fullUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open PDF')));
    }
  }

  Future<void> _approve() async {
    final email = AuthService.getCurrentUserEmail() ?? 'librarian@local';
    setState(() {
      processing = true;
    });
    final res = await BookService.approveAdditionRequest(
      widget.requestId,
      email,
    );
    setState(() {
      processing = false;
    });
    if (res.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request approved')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  Future<void> _decline() async {
    final email = AuthService.getCurrentUserEmail() ?? 'librarian@local';
    final reasonController = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Decline Request'),
              content: TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Decline'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok) return;

    setState(() {
      processing = true;
    });
    final res = await BookService.declineAdditionRequest(
      widget.requestId,
      email,
      reason: reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim(),
    );
    setState(() {
      processing = false;
    });
    if (res.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request declined')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2D35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Addition Request Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (request != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditAdditionRequestPage(request: request!),
                  ),
                );
                if (updated == true) {
                  _load(); // Reload the request details
                }
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : request == null
          ? const Center(
              child: Text(
                'Request not found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image and Title Section
                  Center(
                    child: Column(
                      children: [
                        if ((request!['pic_path'] ?? '').toString().isNotEmpty)
                          Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF2C2D35),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'http://localhost:8000/serve_image.php?path=${request!['pic_path']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.book,
                                      size: 48,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF2C2D35),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          request!['title'] ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Book Information Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2D35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('ISBN', request!['isbn'] ?? '-'),
                        _infoRow('Author', request!['author'] ?? '-'),
                        _infoRow('Category', request!['category'] ?? '-'),
                        _infoRow('Publisher', request!['publisher'] ?? '-'),
                        _infoRow(
                          'Year',
                          request!['publication_year']?.toString() ?? '-',
                        ),
                        _infoRow('Edition', request!['edition'] ?? '-'),
                        _infoRow('Course', request!['course_id'] ?? '-'),
                        const Divider(color: Colors.white24, height: 24),
                        _infoRow('Requested By', request!['email'] ?? '-'),
                        _infoRow(
                          'Request Date',
                          request!['created_at']?.toString().substring(0, 10) ??
                              '-',
                        ),
                        if ((request!['description'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Notes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request!['description'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      if ((request!['pdf_path'] ?? '').toString().isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: processing
                                ? null
                                : () => _downloadPdf(request!['pdf_path']),
                            icon: const Icon(Icons.picture_as_pdf),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2D35),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            label: const Text('View PDF'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: processing ? null : _approve,
                          icon: const Icon(Icons.check),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          label: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: processing ? null : _decline,
                          icon: const Icon(Icons.close),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          label: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
