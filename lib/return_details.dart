import 'package:flutter/material.dart';
import 'return_completed.dart';

class ReturnDetailsPage extends StatelessWidget {
  final String title;
  final String image;
  final String role;
  final String dueDate;
  final String borrowingLimit;
  final String bookId;
  final String isbn;
  final String author;
  final String shelf;
  final String returnDueDate;
  final String fines;

  const ReturnDetailsPage({
    super.key,
    required this.title,
    required this.image,
    this.role = "Student",
    this.dueDate = "August 15, 2024",
    this.borrowingLimit = "2/2",
    this.bookId = "823(A)",
    this.isbn = "123512ASED",
    this.author = "Robert Johnson",
    this.shelf = "110",
    this.returnDueDate = "28/11/2025",
    this.fines = "TK 0.00",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF34495E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Role and Due Date
              _buildInfoRow('Your Role', role),
              const SizedBox(height: 16),
              _buildInfoRow('Due Date', dueDate),
              const SizedBox(height: 24),
              
              // Additional details
              _buildDetailText('Borrowing limit: $borrowingLimit'),
              const SizedBox(height: 12),
              _buildDetailText('Book ID: $bookId'),
              const SizedBox(height: 12),
              _buildDetailText('Book ISBN: $isbn'),
              const SizedBox(height: 12),
              _buildDetailText('Author: $author'),
              const SizedBox(height: 12),
              _buildDetailText('Shelf: $shelf'),
              const SizedBox(height: 12),
              _buildDetailText('Due Date: $returnDueDate'),
              const SizedBox(height: 12),
              _buildDetailText('Fines: $fines'),
              const SizedBox(height: 40),
              
              // Return button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReturnCompletedPage(
                          title: title,
                          image: image,
                          role: role,
                          dueDate: dueDate,
                          borrowingLimit: borrowingLimit,
                          bookId: bookId,
                          isbn: isbn,
                          author: author,
                          shelf: shelf,
                          returnDueDate: returnDueDate,
                          fines: fines,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Return',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }
}
