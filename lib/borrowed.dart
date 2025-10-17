import 'package:flutter/material.dart';
import 'return_details.dart';

class BorrowedBooksPage extends StatelessWidget {
  const BorrowedBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF22232A);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('IITShelf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: const [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/44.jpg"),
          ),
          SizedBox(width: 12)
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                _TabButton(label: "History", active: false, onTap: () => Navigator.pushNamed(context, '/my-books')),
                _TabButton(label: "Borrowed", active: true, onTap: null),
                _TabButton(label: "Returned", active: false, onTap: () => Navigator.pushNamed(context, '/returned')),
                _TabButton(label: "Reserved", active: false, onTap: () => Navigator.pushNamed(context, '/reserved')),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text("Book History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: const [
                BorrowedBookCard(
                  image: "https://images.unsplash.com/photo-1512820790803-83ca734da794",
                  title: "Foundations of Data Science",
                  author: "John Doe",
                  id: "824(B)",
                  due: "Due in 2 days",
                ),
                BorrowedBookCard(
                  image: "https://images.unsplash.com/photo-1507842217343-583bb7270b66",
                  title: "Introduction to Quantum Computing",
                  author: "Robert Johnson",
                  id: "321(A)",
                  due: "Due in 5 days",
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        currentIndex: 2,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/library');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/my-books');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/payment');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "My Books"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class BorrowedBookCard extends StatelessWidget {
  final String image, title, author, id, due;

  const BorrowedBookCard({
    required this.image,
    required this.title,
    required this.author,
    required this.id,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF23232A);

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
                  child: Image.network(image, width: 54, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(author, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(due, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnDetailsPage(
                            title: title,
                            image: image,
                            author: author,
                            bookId: id,
                          ),
                        ),
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
