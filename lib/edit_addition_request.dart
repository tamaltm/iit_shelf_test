import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'book_service.dart';
import 'course_service.dart';

class EditAdditionRequestPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const EditAdditionRequestPage({super.key, required this.request});

  @override
  State<EditAdditionRequestPage> createState() =>
      _EditAdditionRequestPageState();
}

class _EditAdditionRequestPageState extends State<EditAdditionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _isbnController;
  late TextEditingController _authorController;
  late TextEditingController _categoryController;
  late TextEditingController _publisherController;
  late TextEditingController _publicationYearController;
  late TextEditingController _editionController;
  late TextEditingController _pdfUrlController;

  String? _selectedCourse;
  List<Course> _courses = [];
  bool _coursesLoading = true;
  String? _coursesError;
  bool _isSubmitting = false;

  File? _selectedCoverImage;
  String? _existingCoverPath;
  File? _selectedPdfFile;
  String? _selectedPdfFileName;
  String? _existingPdfPath;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCourses();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.request['title'] ?? '',
    );
    _isbnController = TextEditingController(text: widget.request['isbn'] ?? '');
    _authorController = TextEditingController(
      text: widget.request['author'] ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.request['category'] ?? '',
    );
    _publisherController = TextEditingController(
      text: widget.request['publisher'] ?? '',
    );
    _publicationYearController = TextEditingController(
      text: widget.request['publication_year']?.toString() ?? '',
    );
    _editionController = TextEditingController(
      text: widget.request['edition'] ?? '',
    );
    _pdfUrlController = TextEditingController();

    _selectedCourse = widget.request['course_id'] ?? 'NONE';
    _existingCoverPath = widget.request['pic_path'];
    _existingPdfPath = widget.request['pdf_path'];
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
    _pdfUrlController.dispose();
    super.dispose();
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
      });
      return;
    }

    setState(() {
      _courses = fetched;
      _coursesLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedCoverImage = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover image selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdfFile = File(result.files.single.path!);
          _selectedPdfFileName = result.files.single.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload cover image if new one selected
      String? coverImagePath = _existingCoverPath;
      if (_selectedCoverImage != null) {
        final uploadRes = await BookService.uploadCoverImage(
          _selectedCoverImage!,
        );
        if (uploadRes.ok && uploadRes.data['path'] != null) {
          coverImagePath = uploadRes.data['path'];
        } else {
          throw Exception('Failed to upload cover image: ${uploadRes.message}');
        }
      }

      // Upload PDF if new one selected
      String? pdfPath = _existingPdfPath;
      if (_selectedPdfFile != null) {
        final uploadRes = await BookService.uploadRequestPdf(_selectedPdfFile!);
        if (uploadRes.ok && uploadRes.data['path'] != null) {
          pdfPath = uploadRes.data['path'];
        } else {
          throw Exception('Failed to upload PDF: ${uploadRes.message}');
        }
      } else if (_pdfUrlController.text.trim().isNotEmpty) {
        pdfPath = _pdfUrlController.text.trim();
      }

      // Update the addition request
      final res = await BookService.updateAdditionRequest(
        requestId: widget.request['request_id'],
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        isbn: _isbnController.text.trim(),
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
        courseId: _selectedCourse == 'NONE' || _selectedCourse == null
            ? null
            : _selectedCourse,
        pdfPath: pdfPath,
        picPath: coverImagePath,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.ok ? Colors.green : Colors.redAccent,
          ),
        );

        if (res.ok) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
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
          "Edit Request",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2D35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedCoverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedCoverImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _existingCoverPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'http://localhost:8000/serve_image.php?path=$_existingCoverPath',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildUploadIcon();
                                  },
                                ),
                              )
                            : _buildUploadIcon(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to change cover",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Course Dropdown
              _buildCourseDropdown(),
              const SizedBox(height: 16),

              // Title Field
              _buildTextField(
                label: "Book Title *",
                controller: _titleController,
                hintText: "Enter title",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter book title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ISBN Field
              _buildTextField(
                label: "Book ISBN *",
                controller: _isbnController,
                hintText: "123512ASED",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ISBN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Author Field
              _buildTextField(
                label: "Author *",
                controller: _authorController,
                hintText: "Robert Johnson",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Field
              _buildTextField(
                label: "Category (optional)",
                controller: _categoryController,
                hintText: "e.g., Science, Fiction",
              ),
              const SizedBox(height: 12),

              // Publisher Field
              _buildTextField(
                label: "Publisher (optional)",
                controller: _publisherController,
                hintText: "e.g., Oxford Press",
              ),
              const SizedBox(height: 12),

              // Publication Year Field
              _buildTextField(
                label: "Publication Year (optional)",
                controller: _publicationYearController,
                hintText: "e.g., 2023",
              ),
              const SizedBox(height: 12),

              // Edition Field
              _buildTextField(
                label: "Edition (optional)",
                controller: _editionController,
                hintText: "e.g., 3rd Edition",
              ),
              const SizedBox(height: 12),

              // PDF Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        (_selectedPdfFile != null || _existingPdfPath != null)
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "PDF: Upload new or keep existing",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickPdf,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1B1E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _selectedPdfFile != null
                                  ? Icons.check_circle
                                  : Icons.upload,
                              color: _selectedPdfFile != null
                                  ? Colors.green
                                  : const Color(0xFF0A84FF),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPdfFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'New PDF: $_selectedPdfFileName',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ] else if (_existingPdfPath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Current PDF: ${_existingPdfPath!.split('/').last}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
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
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload, color: const Color(0xFF0A84FF), size: 32),
        const SizedBox(height: 4),
        const Text(
          "Upload img",
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
