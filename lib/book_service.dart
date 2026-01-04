import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class BookService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String _absolutePath(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Use serve_image.php to serve uploaded files
    final encoded = Uri.encodeComponent(path);
    return '$_baseUrl/serve_image.php?path=$encoded';
  }

  static Future<List<Book>> fetchBooks({String? search, String? category}) async {
    final uri = Uri.parse('$_baseUrl/books/get_books.php').replace(queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
    });

    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      if (decoded['success'] == true && decoded['books'] is List) {
        return (decoded['books'] as List)
            .map((b) => Book.fromJson(b as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  static Future<ApiResponse> addBook(BookPayload payload, {String? imagePath}) async {
    // If image path provided, use multipart upload
    if (imagePath != null && imagePath.isNotEmpty) {
      return _postWithFile('books/add_book.php', payload.toJson(), imagePath);
    }
    return _post('books/add_book.php', payload.toJson());
  }

  static Future<ApiResponse> updateBook({required String isbn, required BookPayload payload}) async {
    final body = payload.toJson()..['isbn'] = isbn;
    return _post('books/update_book.php', body);
  }

  static Future<ApiResponse> deleteBook({int? id, String? isbn}) async {
    return _post('books/delete_book.php', {
      if (id != null) 'id': id,
      if (isbn != null) 'isbn': isbn,
    });
  }

  static Future<BookStatus?> getBookStatus(String isbn) async {
    final uri = Uri.parse('$_baseUrl/books/get_book_status.php').replace(queryParameters: {
      'isbn': isbn,
    });

    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          return BookStatus.fromJson(decoded);
        }
      }
    } catch (e) {
      // Handle error silently or log
    }
    return null;
  }

  static Future<ApiResponse> borrowBook({required int bookId}) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('borrow/borrow_book.php', {
      'book_id': bookId,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> returnBook({required int borrowId}) async {
    return _post('borrow/return_book.php', {
      'borrow_id': borrowId,
    });
  }

  static Future<ApiResponse> reserveBook({
    required int bookId,
    int expiryDays = 3,
  }) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('books/reserve_book.php', {
      'book_id': bookId,
      'expiry_days': expiryDays,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> cancelReservation(int reservationId) async {
    return _post('books/cancel_reservation.php', {
      'reservation_id': reservationId,
    });
  }

  static Future<ApiResponse> requestAddition({
    required String title,
    String? author,
    String? reason,
  }) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('books/request_book.php', {
      'title': title,
      if (author != null) 'author': author,
      if (reason != null) 'reason': reason,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> uploadPdf({
    required int bookId,
    required String pdfUrl,
  }) async {
    return _post('books/upload_pdf.php', {
      'book_id': bookId,
      'pdf_url': pdfUrl,
    });
  }

  static Future<ApiResponse> _postWithFile(
    String path,
    Map<String, dynamic> body,
    String filePath,
  ) async {
    final uri = Uri.parse('$_baseUrl/$path');
    try {
      final request = http.MultipartRequest('POST', uri);
      
      // Add form fields
      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add file
      final file = await http.MultipartFile.fromPath('image', filePath);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final ok = decoded['success'] == true ||
          (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }

  static Future<ApiResponse> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$path');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final ok = decoded['success'] == true || (resp.statusCode >= 200 && resp.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }
}

class Book {
  final int id;
  final String title;
  final String author;
  final String? isbn;
  final String? category;
  final int quantity;
  final int availableQuantity;
  final String? coverImage;
  final String? pdfUrl;
  final String? description;
  final String? publisher;
  final int? publicationYear;
  final String? edition;
  final int? pages;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.category,
    this.quantity = 0,
    this.availableQuantity = 0,
    this.coverImage,
    this.pdfUrl,
    this.description,
    this.publisher,
    this.publicationYear,
    this.edition,
    this.pages,
  });

  bool get isAvailable => availableQuantity > 0;

  factory Book.fromJson(Map<String, dynamic> json) {
    final picPath = json['pic_path'] as String? ?? json['cover_image'] as String?;
    final resolvedPic = BookService._absolutePath(picPath);
    return Book(
      id: int.tryParse('${json['id'] ?? json['isbn']}') ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      isbn: json['isbn'] as String?,
      category: json['category'] as String?,
      quantity: int.tryParse('${json['copies_total'] ?? json['quantity'] ?? 0}') ?? 0,
      availableQuantity: int.tryParse('${json['copies_available'] ?? json['available_quantity'] ?? 0}') ?? 0,
      coverImage: resolvedPic.isEmpty ? null : resolvedPic,
      pdfUrl: json['pdf_url'] as String?,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publicationYear: int.tryParse('${json['publication_year']}'),
      edition: json['edition'] as String?,
      pages: int.tryParse('${json['pages']}'),
    );
  }
}

class BookPayload {
  final String title;
  final String author;
  final String isbn;
  final String? category;
  final int? quantity;
  final int? availableQuantity;
  final int? shelfId;
  final String? coverImage;
  final String? pdfUrl;
  final String? description;

  BookPayload({
    required this.title,
    required this.author,
    required this.isbn,
    this.category,
    this.quantity,
    this.availableQuantity,
    this.shelfId,
    this.coverImage,
    this.pdfUrl,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (availableQuantity != null) 'available_quantity': availableQuantity,
      if (shelfId != null) 'shelf_id': shelfId,
      if (coverImage != null) 'cover_image': coverImage,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (description != null) 'description': description,
    };
  }
}

class BookStatus {
  final String isbn;
  final int copiesTotal;
  final int copiesAvailable;
  final int borrowedCount;
  final int reservedCount;
  final bool available;

  BookStatus({
    required this.isbn,
    required this.copiesTotal,
    required this.copiesAvailable,
    required this.borrowedCount,
    required this.reservedCount,
    required this.available,
  });

  factory BookStatus.fromJson(Map<String, dynamic> json) {
    return BookStatus(
      isbn: json['isbn'] as String,
      copiesTotal: json['copies_total'] as int? ?? 0,
      copiesAvailable: json['copies_available'] as int? ?? 0,
      borrowedCount: json['borrowed_count'] as int? ?? 0,
      reservedCount: json['reserved_count'] as int? ?? 0,
      available: json['available'] as bool? ?? false,
    );
  }
}

class ApiResponse {
  final bool ok;
  final String message;
  final Map<String, dynamic> data;

  const ApiResponse({required this.ok, required this.message, required this.data});
}
