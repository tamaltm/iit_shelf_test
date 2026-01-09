import 'package:flutter/material.dart';
import 'course_service.dart';
import 'book_service.dart';

class FilterPage extends StatefulWidget {
  final List<String> availableCategories;
  final List<String> availableAuthors;

  const FilterPage({
    super.key,
    required this.availableCategories,
    required this.availableAuthors,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? selectedSemester;
  String? selectedCategory;
  String? selectedAuthor;
  String? selectedAvailability;
  String? selectedBookType;
  String? courseCode;
  List<Course> availableCourses = [];
  List<String> dbCategories = [];
  bool coursesLoading = true;
  bool categoriesLoading = true;
  bool categoryExpanded = false;
  bool availabilityExpanded = false;
  bool semesterExpanded = false;
  bool bookTypeExpanded = false;

  final List<String> semesters = [
    '11',
    '12',
    '21',
    '22',
    '31',
    '32',
    '41',
    '42',
  ];
  final List<String> availabilityOptions = ['Available', 'Not Available'];
  final List<String> bookTypeOptions = ['Physical', 'Digital'];
  final TextEditingController _courseCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCategories();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await CourseService.fetchCourses();
      setState(() {
        availableCourses = courses;
        coursesLoading = false;
      });
    } catch (e) {
      setState(() {
        coursesLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await BookService.fetchCategories();
      setState(() {
        dbCategories = categories;
        categoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        categoriesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        backgroundColor: const Color(0xFF1A1B1E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1B1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reset button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                    selectedAvailability = null;
                    selectedSemester = null;
                    selectedBookType = null;
                    selectedAuthor = null;
                    courseCode = null;
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Category Filter (Expandable)
            _buildExpandableFilter(
              title: 'Category',
              isExpanded: categoryExpanded,
              onTap: () => setState(() => categoryExpanded = !categoryExpanded),
              child: categoriesLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: dbCategories
                          .map(
                            (category) => RadioListTile<String>(
                              title: Text(
                                category,
                                style: const TextStyle(color: Colors.white),
                              ),
                              value: category,
                              groupValue: selectedCategory,
                              onChanged: (value) {
                                setState(() => selectedCategory = value);
                              },
                              activeColor: Colors.green,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),

            // Availability Filter (Expandable)
            _buildExpandableFilter(
              title: 'Availability',
              isExpanded: availabilityExpanded,
              onTap: () =>
                  setState(() => availabilityExpanded = !availabilityExpanded),
              child: Column(
                children: availabilityOptions
                    .map(
                      (option) => RadioListTile<String>(
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: option,
                        groupValue: selectedAvailability,
                        onChanged: (value) {
                          setState(() => selectedAvailability = value);
                        },
                        activeColor: Colors.green,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Semester Filter (Expandable)
            _buildExpandableFilter(
              title: 'Semester',
              isExpanded: semesterExpanded,
              onTap: () => setState(() => semesterExpanded = !semesterExpanded),
              child: Column(
                children: semesters
                    .map(
                      (semester) => RadioListTile<String>(
                        title: Text(
                          semester,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: semester,
                        groupValue: selectedSemester,
                        onChanged: (value) {
                          setState(() => selectedSemester = value);
                        },
                        activeColor: Colors.green,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Book Type Filter (Expandable)
            _buildExpandableFilter(
              title: 'Book Type',
              isExpanded: bookTypeExpanded,
              onTap: () => setState(() => bookTypeExpanded = !bookTypeExpanded),
              child: Column(
                children: bookTypeOptions
                    .map(
                      (type) => RadioListTile<String>(
                        title: Text(
                          type,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: type,
                        groupValue: selectedBookType,
                        onChanged: (value) {
                          setState(() => selectedBookType = value);
                        },
                        activeColor: Colors.green,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final filters = {
                    'category': selectedCategory,
                    'availability': selectedAvailability,
                    'semester': selectedSemester,
                    'book_type': selectedBookType,
                    'author': selectedAuthor,
                    'course_code': courseCode,
                  };
                  Navigator.pop(context, filters);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFilter({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
