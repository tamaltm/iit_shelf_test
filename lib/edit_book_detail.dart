import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'book_service.dart';
import 'course_service.dart';
import 'shelf_service.dart';

class EditBookDetailPage extends StatefulWidget {
  final Book book;

  const EditBookDetailPage({super.key, required this.book});

  @override
  State<EditBookDetailPage> createState() => _EditBookDetailPageState();
}

class _EditBookDetailPageState extends State<EditBookDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _isbnController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _publisherController;
  late final TextEditingController _publicationYearController;
  late final TextEditingController _editionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _copiesTotalController;
  final List<TextEditingController> _copyIdControllers = [];
  late final TextEditingController _shelfIdController;
  late final TextEditingController _compartmentNoController;
  late final TextEditingController _subcompartmentNoController;
  late final TextEditingController _pdfUrlController;
  late final TextEditingController _conditionNoteController;

  bool _isSubmitting = false;
  String? _selectedImagePath;
  String? _selectedCourse;
  List<Course> _courses = [];
  bool _coursesLoading = true;
  String? _coursesError;
  final ImagePicker _imagePicker = ImagePicker();
  List<ShelfLocation> _shelfLocations = [];
  bool _shelfLocationsLoading = true;
  final List<ShelfLocation?> _copyLocations = [];
  int _currentCopyCount = 0;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleController = TextEditingController(text: b.title);
    _isbnController = TextEditingController(text: b.isbn ?? '');
    _authorController = TextEditingController(text: b.author);
    _categoryController = TextEditingController(text: b.category ?? '');
    _publisherController = TextEditingController(text: b.publisher ?? '');
    _publicationYearController = TextEditingController(
      text: b.publicationYear?.toString() ?? '',
    );
    _editionController = TextEditingController(text: b.edition ?? '');
    _descriptionController = TextEditingController(text: b.description ?? '');
    _copiesTotalController = TextEditingController();
    _shelfIdController = TextEditingController();
    _compartmentNoController = TextEditingController();
    _subcompartmentNoController = TextEditingController();
    _pdfUrlController = TextEditingController();
    _conditionNoteController = TextEditingController();
    _copiesTotalController.addListener(_handleCopiesTotalChange);
    _loadCourses();
    _loadShelfLocations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _publisherController.dispose();
    _publicationYearController.dispose();
    _editionController.dispose();
    _descriptionController.dispose();
    _copiesTotalController.removeListener(_handleCopiesTotalChange);
    _copiesTotalController.dispose();
    _shelfIdController.dispose();
    _compartmentNoController.dispose();
    _subcompartmentNoController.dispose();
    _pdfUrlController.dispose();
    _conditionNoteController.dispose();
    for (final c in _copyIdControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleCopiesTotalChange() {
    final parsed = int.tryParse(_copiesTotalController.text.trim()) ?? 0;
    final desiredCount = parsed < 0 ? 0 : parsed;
    if (desiredCount == _currentCopyCount) return;
    setState(() {
      _currentCopyCount = desiredCount;
      _syncCopyControllers(desiredCount);
    });
  }

  void _syncCopyControllers(int desiredCount) {
    while (_copyIdControllers.length > desiredCount) {
      _copyIdControllers.removeLast().dispose();
    }
    while (_copyLocations.length > desiredCount) {
      _copyLocations.removeLast();
    }
    while (_copyIdControllers.length < desiredCount) {
      _copyIdControllers.add(TextEditingController());
    }
    while (_copyLocations.length < desiredCount) {
      _copyLocations.add(null);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty ||
        _isbnController.text.isEmpty ||
        _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, ISBN, and Author are required.')),
      );
      return;
    }

    if (_coursesLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, courses are loading...')),
      );
      return;
    }

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a course.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = BookPayload(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      isbn: _isbnController.text.trim(),
      courseId: _selectedCourse,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      publisher: _publisherController.text.trim().isEmpty
          ? null
          : _publisherController.text.trim(),
      publicationYear: _publicationYearController.text.trim().isEmpty
          ? null
          : _publicationYearController.text.trim(),
      edition: _editionController.text.trim().isEmpty
          ? null
          : _editionController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final result = await BookService.updateBook(
      isbn: _isbnController.text.trim(),
      payload: payload,
    );

    // If a new image was selected, upload it
    if (result.ok &&
        _selectedImagePath != null &&
        _selectedImagePath!.isNotEmpty) {
      final imageResult = await BookService.updateBookImage(
        isbn: _isbnController.text.trim(),
        imagePath: _selectedImagePath!,
      );
      if (!imageResult.ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Book updated but image upload failed: ${imageResult.message}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? Colors.green : Colors.redAccent,
      ),
    );

    if (result.ok && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pdfUrlController.text = result.files.first.path ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File picker unavailable on this platform. Please paste the PDF path directly in the field.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _coursesLoading = true;
      _coursesError = null;
    });

    final fetched = await CourseService.fetchCourses();

    if (!mounted) return;

    if (fetched.isEmpty) {
      setState(() {
        _coursesLoading = false;
        _coursesError = 'Could not load courses. Tap to retry.';
        _selectedCourse = null;
      });
      return;
    }

    setState(() {
      _courses = fetched;
      _coursesLoading = false;
      _selectedCourse = widget.book.courseId ?? fetched.first.id;
    });
  }

  Future<void> _loadShelfLocations() async {
    setState(() {
      _shelfLocationsLoading = true;
    });
    final fetched = await ShelfService.getShelfLocations();
    if (!mounted) return;
    setState(() {
      _shelfLocations = fetched;
      _shelfLocationsLoading = false;
    });
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImagePath != null
                        ? Colors.green
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedImagePath != null
                          ? Icons.check_circle
                          : Icons.upload,
                      color: _selectedImagePath != null
                          ? Colors.green
                          : Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImagePath != null
                          ? "Image Selected"
                          : "Upload img",
                      style: TextStyle(
                        color: _selectedImagePath != null
                            ? Colors.green
                            : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Book Title",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Course selector
            _buildCourseDropdown(),
            const SizedBox(height: 16),

            _buildInfoField("Book ISBN:", _isbnController),
            const SizedBox(height: 16),
            _buildInfoField("Author:", _authorController),
            const SizedBox(height: 16),
            _buildInfoField("Category (optional):", _categoryController),
            const SizedBox(height: 16),
            _buildInfoField("Publisher (optional):", _publisherController),
            const SizedBox(height: 16),
            _buildInfoField(
              "Publication Year (optional):",
              _publicationYearController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInfoField("Edition (optional):", _editionController),
            const SizedBox(height: 16),
            _buildInfoField(
              "Number of Physical Copies:",
              _copiesTotalController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (_currentCopyCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Copy IDs and Shelf Locations',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...List.generate(_currentCopyCount, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _currentCopyCount - 1 ? 0 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Copy ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoField(
                              'Copy ID',
                              _copyIdControllers[index],
                            ),
                            const SizedBox(height: 8),
                            _buildShelfLocationDropdown(index),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // PDF Upload Section
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
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
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.upload, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _conditionNoteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText:
                      "Condition Note (optional, e.g., 'Good', 'Minor wear')",
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Short description (optional)",
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
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

  Widget _buildCourseDropdown() {
    Widget child;

    if (_coursesLoading) {
      child = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading courses...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    } else if (_coursesError != null) {
      child = InkWell(
        onTap: _loadCourses,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _coursesError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      child = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse,
          dropdownColor: const Color(0xFF2C2D35),
          isExpanded: true,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem(value: 'NONE', child: Text('None')),
            ..._courses
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.id.isNotEmpty ? '${c.id} — ${c.name}' : c.name,
                    ),
                  ),
                )
                .toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCourse = value;
            });
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              "Course (optional)",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
              keyboardType: keyboardType,
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

  Widget _buildShelfLocationDropdown(int copyIndex) {
    Widget child;
    if (_shelfLocationsLoading) {
      child = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading shelf locations...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    } else if (_shelfLocations.isEmpty) {
      child = InkWell(
        onTap: _loadShelfLocations,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.refresh, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No shelf locations available. Tap to reload.',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      child = DropdownButtonHideUnderline(
        child: DropdownButton<ShelfLocation>(
          value: _copyLocations[copyIndex],
          dropdownColor: const Color(0xFF2C2D35),
          isExpanded: true,
          iconEnabledColor: Colors.white,
          hint: const Text(
            'Select Shelf Location',
            style: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          items: _shelfLocations
              .map(
                (loc) =>
                    DropdownMenuItem(value: loc, child: Text(loc.displayName)),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _copyLocations[copyIndex] = value;
            });
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
