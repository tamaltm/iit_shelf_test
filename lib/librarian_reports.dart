import 'package:flutter/material.dart';
import 'generate_reports.dart';

class LibrarianReportsPage extends StatelessWidget {
  const LibrarianReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the director-style generate reports experience for librarians.
    return const GenerateReportsPage(userRole: 'librarian');
  }
}
