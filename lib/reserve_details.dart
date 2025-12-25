import 'package:flutter/material.dart';
import 'book_image.dart';

class ReserveDetailsPage extends StatelessWidget {
  final String image, title, author;
  final String role;
  final String dueDate;
  final String borrowingLimit;
  final String bookId;
  final String isbn;
  final String shelf;

  const ReserveDetailsPage({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    this.role = "Student",
    this.dueDate = "August 15, 2024",
    this.borrowingLimit = "2/2",
    this.bookId = "Not Allotted",
    this.isbn = "123512ASED",
    this.shelf = "110",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BookImage(
                    image,
                    height: 180,
                    width: 130,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Book Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Details List
            _buildDetailRow('Your Role', role),
            const SizedBox(height: 16),
            _buildDetailRow('Due Date', dueDate),
            const SizedBox(height: 16),
            _buildDetailRow('Borrowing limit', borrowingLimit),
            const SizedBox(height: 16),
            _buildDetailRow('Book ID', bookId),
            const SizedBox(height: 16),
            _buildDetailRow('Book ISBN', isbn),
            const SizedBox(height: 16),
            _buildDetailRow('Author', author),
            const SizedBox(height: 16),
            _buildDetailRow('Shelf', shelf),
            const Spacer(),
            // Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
