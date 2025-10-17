import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_bottom_nav.dart';

class Book {
  final String image;
  final String title;
  final String author;
  final String dueLabel;
  final Color dueColor;
  final String id;

  Book({
    required this.image,
    required this.title,
    required this.author,
    required this.dueLabel,
    required this.dueColor,
    required this.id,
  });
}

class DirectorDashboardPage extends StatefulWidget {
  const DirectorDashboardPage({super.key});
  @override
  State<DirectorDashboardPage> createState() => _DirectorDashboardPageState();
}

class _DirectorDashboardPageState extends State<DirectorDashboardPage> {
  final List<Book> borrowedBooks = [
    Book(
      image: 'https://via.placeholder.com/80x120/4A90E2/FFFFFF?text=Data+Science',
      title: 'Foundations of Data Science',
      author: 'John Doe',
      dueLabel: 'Due: 2024-12-30',
      dueColor: Colors.orange,
      id: 'ID: 12345',
    ),
    Book(
      image: 'https://via.placeholder.com/80x120/9B59B6/FFFFFF?text=AI',
      title: 'Introduction to AI',
      author: 'Jane Smith',
      dueLabel: 'Due: 2024-12-25',
      dueColor: Colors.red,
      id: 'ID: 12346',
    ),
  ];

  final List<Book> recommendedBooks = [
    Book(
      image: 'https://via.placeholder.com/120x180/E74C3C/FFFFFF?text=Machine+Learning',
      title: 'Machine Learning Basics',
      author: 'Sarah Johnson',
      dueLabel: 'Available',
      dueColor: Colors.green,
      id: 'ID: 20001',
    ),
    Book(
      image: 'https://via.placeholder.com/120x180/3498DB/FFFFFF?text=Python',
      title: 'Python for Data Analysis',
      author: 'Michael Chen',
      dueLabel: 'Available',
      dueColor: Colors.green,
      id: 'ID: 20002',
    ),
    Book(
      image: 'https://via.placeholder.com/120x180/2ECC71/FFFFFF?text=Deep+Learning',
      title: 'Deep Learning Fundamentals',
      author: 'Emily Davis',
      dueLabel: 'Available',
      dueColor: Colors.green,
      id: 'ID: 20003',
    ),
    Book(
      image: 'https://via.placeholder.com/120x180/F39C12/FFFFFF?text=Statistics',
      title: 'Statistical Methods',
      author: 'Robert Wilson',
      dueLabel: 'Available',
      dueColor: Colors.green,
      id: 'ID: 20004',
    ),
    Book(
      image: 'https://via.placeholder.com/120x180/9B59B6/FFFFFF?text=Neural+Networks',
      title: 'Neural Networks Guide',
      author: 'Lisa Anderson',
      dueLabel: 'Available',
      dueColor: Colors.green,
      id: 'ID: 20005',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        userName: "John",
        userRole: "Director",
        profileImageUrl: "https://randomuser.me/api/portraits/men/44.jpg",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Books Borrowed",
                    "2/5",
                    Icons.menu_book,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Overdue",
                    "0",
                    Icons.warning_amber_rounded,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.red,
                          size: isSmallScreen ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Outstanding Fines",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BDT 150.00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isSmallScreen) const SizedBox(height: 12),
                  if (isSmallScreen)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Pay Now",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (!isSmallScreen)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 400 ? 16 : 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Pay Now",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth < 400 ? 13 : 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recommended for You",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/library');
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xFF0A84FF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedBooks.length,
                itemBuilder: (context, index) {
                  return _buildCarouselBookCard(recommendedBooks[index]);
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Currently Borrowed",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/borrowed');
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xFF0A84FF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...borrowedBooks.map((book) => _buildBookCard(book)).toList(),
            
            const SizedBox(height: 24),
            
            const Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: isSmallScreen ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isSmallScreen ? 3.5 : (screenWidth < 400 ? 1.3 : 1.5),
              children: [
                _QuickButton(
                  icon: Icons.bookmark_rounded,
                  label: "Reservations",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/reserved');
                  },
                ),
                _QuickButton(
                  icon: Icons.upload_file_outlined,
                  label: "Upload PDF",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/upload-pdf');
                  },
                ),
                _QuickButton(
                  icon: Icons.assessment,
                  label: "Generate Reports",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/generate-reports',
                      arguments: {'userRole': 'director'},
                    );
                  },
                ),
                _QuickButton(
                  icon: Icons.history,
                  label: "Transaction History",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/transaction-history',
                      arguments: {'userRole': 'director'},
                    );
                  },
                ),
                _QuickButton(
                  icon: Icons.book,
                  label: "Request New Book",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/request-book-details');
                  },
                ),
                _QuickButton(
                  icon: Icons.call,
                  label: "Contact Librarian",
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.pushNamed(context, '/contact-librarian');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildCarouselBookCard(Book book) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/book-detail');
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                book.image,
                width: 140,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 140,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: Colors.white54,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book.image,
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 75 : 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 75 : 90,
                  color: Colors.grey[800],
                  child: const Icon(Icons.book, color: Colors.white54),
                );
              },
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: book.dueColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    book.dueLabel,
                    style: TextStyle(
                      color: book.dueColor,
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/return-details',
                            arguments: {
                              'title': book.title,
                              'author': book.author,
                              'image': book.image,
                              'bookId': book.id,
                              'dueDate': book.dueLabel,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Return",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/book-detail',
                            arguments: {
                              'title': book.title,
                              'author': book.author,
                              'image': book.image,
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Details",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSmallScreen;

  const _QuickButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2D35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isSmallScreen
            ? Row(
                children: [
                  Icon(icon, color: const Color(0xFF0A84FF), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFF0A84FF), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
