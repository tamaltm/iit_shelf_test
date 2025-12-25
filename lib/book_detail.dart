import 'package:flutter/material.dart';
import 'return_confirmation.dart';
import 'reserve_confirm.dart';

class BookDetailPage extends StatelessWidget {
  final String image, title, author, description;
  final bool available;
  final bool pdfAvailable;
  // new: role and current borrowed count (frontend demo state)
  final String role;
  final int currentBorrowed;

  const BookDetailPage({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.description,
    required this.available,
    this.pdfAvailable = true,
    this.role = 'Student',
    this.currentBorrowed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text('Book Details', style: Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(builder: (ctx) {
                    // Use the passed `image` if provided. Support both network URLs and local assets.
                    final img = (image.trim().isEmpty) ? 'lib/assets/data_science.png' : image;
                    if (img.startsWith('http')) {
                      return Image.network(
                        img,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset('lib/assets/data_science.png', height: 300, fit: BoxFit.cover),
                      );
                    }
                    return Image.asset(
                      img,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 96, color: Colors.white70),
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Availability pill (keep appearance like before but in a pill)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: available ? const Color(0xFF2E7D32) : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          available ? "Available Now" : "Currently Borrowed",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Download PDF pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: pdfAvailable ? Colors.lightBlue : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pdfAvailable ? "Download PDF" : "pdf unavailable",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Update PDF pill-shaped button (yellow)
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/upload-pdf',
                            arguments: {'mode': 'update', 'bookTitle': title},
                          );
                        },
                        child: const Text('Update PDF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Description",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ISBN", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text("978-3-16-148410-0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pages", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text("450", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Year", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text("2023", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: available
                          ? () {
                              // Role-based limits
                              final roleLower = role.toLowerCase();
                              final int maxDays = roleLower == 'student' ? 7 : (roleLower == 'teacher' || roleLower == 'director' ? 15 : 7);
                              final int maxBooks = roleLower == 'student' ? 2 : (roleLower == 'teacher' || roleLower == 'director' ? 5 : 2);

                              showDialog(
                                context: context,
                                builder: (context) {
            int selectedDays = maxDays;
          String errorMessage = '';
                                  final bool atLimit = currentBorrowed >= maxBooks;

                                  return StatefulBuilder(builder: (context, setState) {
                                    return AlertDialog(
                                      backgroundColor: cardColor,
                                      title: const Text("Confirm Borrow", style: TextStyle(color: Colors.white)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Do you want to borrow '$title'?",
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Select duration (days):',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButton<int>(
                                            value: selectedDays,
                                            dropdownColor: cardColor,
                                            items: List.generate(maxDays, (i) => i + 1)
                                                .map((d) => DropdownMenuItem(value: d, child: Text('$d day${d>1?"s":""}', style: TextStyle(color: Colors.white))))
                                                .toList(),
                                            onChanged: (v) => setState(() {
                                              selectedDays = v ?? selectedDays;
                                            }),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Role: $role — max $maxBooks book(s), max $maxDays days each',
                                            style: TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          if (atLimit)
                                            Text('Borrowing limit reached: $currentBorrowed / $maxBooks', style: TextStyle(color: Colors.redAccent)),
                                          if (errorMessage.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(errorMessage, style: TextStyle(color: Colors.redAccent)),
                                          ]
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: atLimit
                                              ? null
                                              : () {
                                                  // Basic frontend confirmation — in a real app you'd call an API and pass selectedDays
                                                  Navigator.pop(context);
                                                  Navigator.pushNamed(context, '/my-books');
                                                },
                                          style: ElevatedButton.styleFrom(backgroundColor: atLimit ? Colors.grey : Colors.blue),
                                          child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    );
                                  });
                                },
                              );
                            }
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReturnConfirmationPage(bookTitle: title),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: available ? Colors.blue : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        available ? "Borrow Book" : "Return Book",
                        style: TextStyle(color: available ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReserveConfirmPage(
                              image: image,
                              title: title,
                              author: author,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Reserve Book",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Add to Shelf", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
