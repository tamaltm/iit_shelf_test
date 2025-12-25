import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  final List<String> availableCategories;
  final List<String> availableAuthors;

  const FilterPage({super.key, required this.availableCategories, required this.availableAuthors});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? selectedSemester;
  String? selectedCategory;
  String? selectedAuthor;
  final List<String> semesters = ['11', '12', '21', '22', '31', '32', '41', '42'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session filter removed per request

            const Text('Semester', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedSemester,
              dropdownColor: const Color(0xFF22232A),
              decoration: InputDecoration(fillColor: const Color(0xFF22232A), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => selectedSemester = v),
            ),
            const SizedBox(height: 16),

            const Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              dropdownColor: const Color(0xFF22232A),
              decoration: InputDecoration(fillColor: const Color(0xFF22232A), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: widget.availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
            ),
            const SizedBox(height: 16),

            const Text('Author', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedAuthor,
              dropdownColor: const Color(0xFF22232A),
              decoration: InputDecoration(fillColor: const Color(0xFF22232A), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: widget.availableAuthors.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => selectedAuthor = v),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final filters = {
                        'semester': selectedSemester,
                        'category': selectedCategory,
                        'author': selectedAuthor,
                      };
                      Navigator.pop(context, filters);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
