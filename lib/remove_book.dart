import 'package:flutter/material.dart';

import 'book_service.dart';

class RemoveBookPage extends StatefulWidget {
  const RemoveBookPage({super.key});

  @override
  State<RemoveBookPage> createState() => _RemoveBookPageState();
}

class _RemoveBookPageState extends State<RemoveBookPage> {
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<Book> _books = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await BookService.fetchBooks(search: query);
      setState(() => _books = res);
    } catch (e) {
      setState(() => _error = 'Failed to load books');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete "${book.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteBook(book);
    }
  }

  Future<void> _deleteBook(Book book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await BookService.deleteBook(isbn: book.isbn);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.ok ? Colors.green : Colors.redAccent,
        ),
      );
      if (res.ok) {
        _fetchBooks(query: _searchController.text.trim());
      }
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
          'Delete Book',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSearchField(
                    'Search by title/author/ISBN',
                    _searchController,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _fetchBooks(query: _searchController.text.trim()),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final b = _books[index];
                  return ListTile(
                    tileColor: const Color(0xFF2C2D35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(
                      b.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${b.author} • ${b.isbn ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.delete, color: Colors.redAccent),
                    onTap: () => _confirmDelete(b),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(
    String hint,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onSubmitted: (val) => _fetchBooks(query: val.trim()),
      ),
    );
  }
}
