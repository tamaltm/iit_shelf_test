import 'package:flutter/material.dart';

class RemoveBookPage extends StatefulWidget {
  const RemoveBookPage({super.key});

  @override
  State<RemoveBookPage> createState() => _RemoveBookPageState();
}

class _RemoveBookPageState extends State<RemoveBookPage> {
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _authorController = TextEditingController();
  final _bookIdController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _bookIdController.dispose();
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
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () {
                // Handle remove book logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Book removed successfully!")),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Remove",
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
