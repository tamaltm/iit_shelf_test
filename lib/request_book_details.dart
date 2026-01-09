import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'course_service.dart';
import 'dart:io';

import 'book_service.dart';

class RequestBookDetailsPage extends StatefulWidget {
  final String? requestId;
  final String? status;

  const RequestBookDetailsPage({super.key, this.requestId, this.status});

  @override
  State<RequestBookDetailsPage> createState() => _RequestBookDetailsPageState();
}

class _RequestBookDetailsPageState extends State<RequestBookDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _authorController = TextEditingController();
  final _pdfUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publicationYearController = TextEditingController();
  final _editionController = TextEditingController();
  String? _selectedCourse;
  List<Course> _courses = [];
  bool _coursesLoading = true;
  String? _coursesError;

  bool _imageUploaded = false;
  // Role removed to match add book page design
  bool _isSubmitting = false;
  File? _selectedPdfFile;
  String? _selectedPdfFileName;
  File? _selectedCoverImage;

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _pdfUrlController.dispose();
    _categoryController.dispose();
    _publisherController.dispose();
    _publicationYearController.dispose();
    _editionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedCoverImage = File(result.files.single.path!);
          _imageUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover image selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
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
      _selectedCourse = 'NONE';
    });
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking PDF: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      // Check if PDF is provided (either file or URL)
      if (_selectedPdfFile == null && _pdfUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF is required. Please upload a PDF file or provide a URL.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _sendRequest();
    }
  }

  Future<void> _sendRequest() async {
    setState(() => _isSubmitting = true);

    // Upload cover image if selected
    String? coverImagePath;
    if (_selectedCoverImage != null) {
      final uploadRes = await BookService.uploadCoverImage(
        _selectedCoverImage!,
      );
      if (uploadRes.ok && uploadRes.data['path'] != null) {
        coverImagePath = uploadRes.data['path'];
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload cover image: ${uploadRes.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // If a PDF file is selected, upload it first
    String? pdfPath;
    if (_selectedPdfFile != null) {
      final uploadRes = await BookService.uploadRequestPdf(_selectedPdfFile!);
      if (uploadRes.ok && uploadRes.data['path'] != null) {
        pdfPath = uploadRes.data['path'];
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload PDF: ${uploadRes.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else if (_pdfUrlController.text.trim().isNotEmpty) {
      // Use URL if provided and no file selected
      pdfPath = _pdfUrlController.text.trim();
    }

    final res = await BookService.requestAddition(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled request'
          : _titleController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      isbn: _isbnController.text.trim().isEmpty
          ? null
          : _isbnController.text.trim(),
      pdfPath: pdfPath,
      picPath: coverImagePath,
    );

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.ok ? Colors.green : Colors.redAccent,
      ),
    );

    if (res.ok && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requestId != null) {
      return _buildStatusView();
    }

    return _buildRequestForm();
  }

  Widget _buildRequestForm() {
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
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2D35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _imageUploaded
                                  ? Icons.check_circle
                                  : Icons.upload,
                              color: _imageUploaded
                                  ? Colors.green
                                  : const Color(0xFF0A84FF),
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _imageUploaded ? "Uploaded" : "Upload img",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _titleController.text.isEmpty
                          ? "Introduction to\nQuantum Computing"
                          : _titleController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Course selector
              _buildCourseDropdown(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Book Title: ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Enter title",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter book title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Book ISBN: ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _isbnController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "123512ASED",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ISBN';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Author: ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _authorController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Robert Johnson",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter author name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Category (optional): ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "e.g., Science, Fiction",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Publisher (optional): ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _publisherController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "e.g., Oxford Press",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Publication Year (optional): ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _publicationYearController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "e.g., 2023",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Edition (optional): ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _editionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "e.g., 3rd Edition",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        (_selectedPdfFile != null ||
                            _pdfUrlController.text.isNotEmpty)
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
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                "PDF: Upload .pdf file or paste URL below ",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                "*",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                        'Selected: $_selectedPdfFileName',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pdfUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Or paste PDF URL here",
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
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
                          "Request to add",
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

  Widget _buildStatusView() {
    final status = widget.status ?? 'Pending';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2D35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(height: 4),
                        Text(
                          "Upload img",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Introduction to\nQuantum Computing",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Role removed; course optional matches add book
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Book ISBN: 123512ASED",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Author: Robert Johnson",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "PDF: Paste the URL or Upload .pdf",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1B1E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.upload,
                      color: Color(0xFF0A84FF),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildStatusProgress(status),

            const SizedBox(height: 16),

            Text(
              "Status: $status",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgress(String currentStatus) {
    final statuses = ['Requested', 'Pending', 'Added'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Row(
      children: [
        for (int i = 0; i < statuses.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: i <= currentIndex
                    ? (i == 0
                          ? const Color(0xFF4CAF50)
                          : i == 1
                          ? const Color(0xFFFFA726)
                          : const Color(0xFFFF9800))
                    : const Color(0xFF2C2D35),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(8) : Radius.zero,
                  right: i == statuses.length - 1
                      ? const Radius.circular(8)
                      : Radius.zero,
                ),
              ),
              child: Text(
                statuses[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i <= currentIndex ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: i == currentIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (i < statuses.length - 1)
            Container(width: 2, height: 40, color: const Color(0xFF1A1B1E)),
        ],
      ],
    );
  }
}
