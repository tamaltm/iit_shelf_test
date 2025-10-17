import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'dashboard.dart';
import 'my_books.dart';
import 'borrowed.dart';
import 'returned.dart';
import 'reserved.dart';
import 'library.dart';
import 'book_detail.dart';
import 'payment.dart';
import 'profile.dart';
import 'notifications.dart';
import 'librarian_dashboard.dart';
import 'librarian_profile.dart';
import 'librarian_reports.dart';
import 'librarian_inventory.dart';
import 'librarian_requests.dart';
import 'general_notices.dart';
import 'auth_service.dart'; // Added auth service import
import 'director_dashboard.dart'; // Added director dashboard import
import 'add_shelf.dart';
import 'remove_shelf.dart';
import 'add_book.dart';
import 'remove_book.dart';
import 'generate_reports.dart'; // Added generate reports import
import 'transaction_history.dart'; // Added transaction history import
import 'return_details.dart'; // Added return details import
import 'contact_librarian.dart'; // Added contact librarian import
import 'request_book_details.dart'; // Added request book details import
import 'upload_pdf.dart'; // Added upload_pdf import

void main() => runApp(IITShelfApp());

class IITShelfApp extends StatelessWidget {
  const IITShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IITShelf — Digital Library',
      theme: ThemeData.dark(),
      home: IITShelfHome(), // Now shows login form directly
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const ProfessorDashboardPage(),
        '/librarian-dashboard': (context) => const LibrarianDashboardPage(),
        '/librarian-profile': (context) => const LibrarianProfilePage(),
        '/librarian-reports': (context) => const LibrarianReportsPage(),
        '/librarian-inventory': (context) => const LibrarianInventoryPage(),
        '/librarian-requests': (context) => const LibrarianRequestsPage(),
        '/director-dashboard': (context) => const DirectorDashboardPage(), // Added director dashboard route
        '/add-shelf': (context) => const AddShelfPage(),
        '/remove-shelf': (context) => const RemoveShelfPage(),
        '/add-book': (context) => const AddBookPage(),
        '/remove-book': (context) => const RemoveBookPage(),
        '/generate-reports': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final userRole = args?['userRole'] ?? 'librarian';
          return GenerateReportsPage(userRole: userRole);
        }, // Added generate reports route
        '/transaction-history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final userRole = args?['userRole'] ?? 'librarian';
          return TransactionHistoryPage(userRole: userRole);
        }, // Added transaction history route with user role parameter
        '/my-books': (context) => const BookHistoryPage(),
        '/borrowed': (context) => const BorrowedBooksPage(),
        '/returned': (context) => const ReturnedBooksPage(),
        '/reserved': (context) => const ReservedBooksPage(),
        '/library': (context) => const LibraryPage(),
        '/payment': (context) => const PaymentPage(),
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
        '/general-notices': (context) => const GeneralNoticesPage(),
        '/contact-librarian': (context) => const ContactLibrarianPage(), // Added contact librarian route
        '/request-book-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return RequestBookDetailsPage(
            requestId: args?['requestId'],
            status: args?['status'],
          );
        }, // Added request book details route
        '/upload-pdf': (context) => const UploadPdfPage(), // Added upload PDF route
        '/book-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return BookDetailPage(
            title: args?['title'] ?? 'Unknown Title',
            author: args?['author'] ?? 'Unknown Author',
            image: args?['image'] ?? 'https://via.placeholder.com/150',
            description: args?['description'] ?? 'No description available.',
            available: args?['available'] ?? true,
            pdf_available: args?['pdf_available'] ?? true,
          );
        },
        '/return-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ReturnDetailsPage(
            title: args?['title'] ?? 'Unknown Title',
            author: args?['author'] ?? 'Unknown Author',
            image: args?['image'] ?? 'https://via.placeholder.com/150',
            bookId: args?['bookId'] ?? 'Unknown ID',
          );
        },
      },
    );
  }
}

class IITShelfHome extends StatefulWidget {
  const IITShelfHome({super.key});

  @override
  State<IITShelfHome> createState() => _IITShelfHomeState();
}

class _IITShelfHomeState extends State<IITShelfHome> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both email and password";
      });
      return;
    }

    if (AuthService.validateLogin(email, password)) {
      final role = AuthService.getUserRole(email);
      final route = AuthService.getDefaultRouteForRole(role!);
      
      // Check if widget is still mounted before using context
      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      setState(() {
        _errorMessage = "Invalid email or password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "IITShelf",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/general-notices');
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF22232A),
              borderRadius: BorderRadius.circular(14),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Welcome to IITShelf",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to access your digital library",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 26),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(51), // Updated withOpacity to withAlpha for Flutter 3.19+
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Institution Email",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Enter your institution email',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) {},
                      activeColor: Colors.blueAccent,
                    ),
                    const Text(
                      "Remember me",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Login"),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text("Register", style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/library');
                  },
                  icon: const Icon(Icons.person_outline, color: Colors.grey),
                  label: Text(
                    "Browse as Guest",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(26), // Updated withOpacity to withAlpha for Flutter 3.19+
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withAlpha(77)), // Updated withOpacity to withAlpha for Flutter 3.19+
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Demo Credentials:",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDemoCredential("Student", "student@nstu.edu.bd"),
                      _buildDemoCredential("Teacher", "teacher@nstu.edu.bd"),
                      _buildDemoCredential("Librarian", "librarian@nstu.edu.bd"),
                      _buildDemoCredential("Director", "director@nstu.edu.bd"),
                      const SizedBox(height: 4),
                      Text(
                        "Password: password123",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredential(String role, String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$role: $email",
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 11,
        ),
      ),
    );
  }
}
