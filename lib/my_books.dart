import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'auth_service.dart';
import 'role_bottom_nav.dart';
import 'book_resources.dart';
import 'book_image.dart';

// Define a single Book model to represent all states
class Book {
  final String image, title, author, dueLabel, id;
  final Color dueColor;

  Book({
    required this.image,
    required this.title,
    required this.author,
    required this.dueLabel,
    required this.dueColor,
    required this.id,
  });
}

// Example mock lists; replace or populate from backend/API
final borrowedBooks = [
  Book(
    image: bookResources[2]['image']!,
    title: bookResources[2]['title']!,
    author: bookResources[2]['author']!,
    dueLabel: "Due in 2 days",
    dueColor: Colors.teal,
    id: "824(B)",
  ),
];

final returnedBooks = [
  Book(
    image: bookResources[3]['image']!,
    title: bookResources[3]['title']!,
    author: bookResources[3]['author']!,
    dueLabel: "Returned 3 days ago",
    dueColor: Colors.grey,
    id: "823(A)",
  ),
];

final reservedBooks = [
  Book(
    image: bookResources[0]['image']!,
    title: bookResources[0]['title']!,
    author: bookResources[0]['author']!,
    dueLabel: "Expected: 9/11/2025",
    dueColor: Colors.orange,
    id: "901(Q)",
  ),
];

class BookHistoryPage extends StatelessWidget {
  const BookHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);
    return Scaffold(
      backgroundColor: Colors.black,
  appBar: CustomAppBar(userRole: AuthService.getCurrentUserRole()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  hintText: "Search books...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _TabButton(label: "History", active: true, onTap: null),
                _TabButton(
                  label: "Borrowed",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/borrowed');
                  },
                ),
                _TabButton(
                  label: "Returned",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/returned');
                  },
                ),
                _TabButton(
                  label: "Reserved",
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/reserved');
                  },
                ),
              ],
            ),
          ),
          const Expanded(
            child: BookHistoryList(),
          ),
        ],
      ),
  bottomNavigationBar: const RoleBottomNav(currentIndex: 1),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _TabButton({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class BookHistoryList extends StatelessWidget {
  const BookHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    // Merge all book lists
    final allBooks = <Book>[];
    allBooks.addAll(borrowedBooks);
    allBooks.addAll(returnedBooks);
    allBooks.addAll(reservedBooks);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: allBooks.length,
      itemBuilder: (context, index) {
        final book = allBooks[index];
        return BookHistoryCard(
          image: book.image,
          title: book.title,
          author: book.author,
          dueLabel: book.dueLabel,
          dueColor: book.dueColor,
          id: book.id,
        );
      },
    );
  }
}

class BookHistoryCard extends StatelessWidget {
  final String image, title, author, dueLabel, id;
  final Color dueColor;

  const BookHistoryCard({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.dueLabel,
    required this.dueColor,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookImage(image, width: 54, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(author, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(dueLabel, style: TextStyle(color: dueColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Icon(Icons.cloud_download, color: Colors.white, size: 22),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/return-details',
                        arguments: {
                          'title': title,
                          'image': image,
                          'author': author,
                          'bookId': id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text("Return", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/book-detail',
                        arguments: {
                          'title': title,
                          'author': author,
                          'image': image,
                          'description': 'Book details for $title',
                          'available': false,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    child: const Text("Details", style: TextStyle(color: Colors.white)),
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
