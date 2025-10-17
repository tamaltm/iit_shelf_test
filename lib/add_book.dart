import 'package:flutter/material.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _authorController = TextEditingController();
  final _bookIdController = TextEditingController();
  final _pdfUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _bookIdController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
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
          "Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Image Section
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload, color: Colors.blue, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    "Upload img",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Book Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Book Title",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Your Role", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text("Student", style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildInfoField("Book ISBN:", _isbnController),
            const SizedBox(height: 16),
            _buildInfoField("Author:", _authorController),
            const SizedBox(height: 16),
            _buildInfoField("Book ID:", _bookIdController),
            const SizedBox(height: 24),
            
            // PDF Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pdfUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "PDF: Paste the URL or Upload .pdf",
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.upload, color: Colors.white70),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () {
                // Handle add book logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Book added successfully!")),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
