import 'package:flutter/material.dart';

import 'book_service.dart';

class EditBookDetailPage extends StatefulWidget {
  final Book book;
  const EditBookDetailPage({super.key, required this.book});

  @override
  State<EditBookDetailPage> createState() => _EditBookDetailPageState();
}

class _EditBookDetailPageState extends State<EditBookDetailPage> {
  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _publisherController;
  late final TextEditingController _yearController;
  late final TextEditingController _editionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _copiesTotalController;
  late final TextEditingController _copiesAvailableController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _isbnController = TextEditingController(text: b.isbn ?? '');
    _titleController = TextEditingController(text: b.title);
    _authorController = TextEditingController(text: b.author);
    _categoryController = TextEditingController(text: b.category ?? '');
    _publisherController = TextEditingController(text: b.publisher ?? '');
    _yearController = TextEditingController(text: b.publicationYear?.toString() ?? '');
    _editionController = TextEditingController(text: b.edition ?? '');
    _descriptionController = TextEditingController(text: b.description ?? '');
    _copiesTotalController = TextEditingController(text: b.quantity.toString());
    _copiesAvailableController = TextEditingController(text: b.availableQuantity.toString());
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _editionController.dispose();
    _descriptionController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isbnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ISBN is required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = BookPayload(
      title: _titleController.text.trim().isEmpty
          ? widget.book.title
          : _titleController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? widget.book.author
          : _authorController.text.trim(),
      isbn: _isbnController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      quantity: int.tryParse(_copiesTotalController.text.trim()),
      availableQuantity: int.tryParse(_copiesAvailableController.text.trim()),
      shelfId: null,
      pdfUrl: null,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final res = await BookService.updateBook(
      isbn: _isbnController.text.trim(),
      payload: payload,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.ok ? Colors.green : Colors.redAccent,
      ),
    );
    if (res.ok) Navigator.pop(context);
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
          'Edit Book Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField('ISBN (required)', _isbnController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Title', _titleController),
            const SizedBox(height: 16),
            _buildField('Author', _authorController),
            const SizedBox(height: 16),
            _buildField('Category', _categoryController),
            const SizedBox(height: 16),
            _buildField('Publisher', _publisherController),
            const SizedBox(height: 16),
            _buildField('Publication Year', _yearController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Edition', _editionController),
            const SizedBox(height: 16),
            _buildField('Description', _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            _buildField('Copies Total', _copiesTotalController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Copies Available', _copiesAvailableController, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Changes',
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

  Widget _buildField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
