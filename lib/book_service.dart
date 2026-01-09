import 'dart:convert';
import 'dart:io' show Platform, File;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class BookService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  static String _absolutePath(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Use serve_image.php to serve uploaded files
    final encoded = Uri.encodeComponent(path);
    return '$_baseUrl/serve_image.php?path=$encoded';
  }

  static String resolveFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl/$path';
  }

  static Future<List<Book>> fetchBooks({
    String? search,
    String? category,
    String? courseId,
    String? semester,
    String? availability,
    String? bookType,
  }) async {
    final uri = Uri.parse('$_baseUrl/books/get_books.php').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (courseId != null && courseId.isNotEmpty) 'course_id': courseId,
        if (semester != null && semester.isNotEmpty) 'semester': semester,
        if (availability != null && availability.isNotEmpty)
          'availability': availability,
        if (bookType != null && bookType.isNotEmpty) 'book_type': bookType,
      },
    );

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

  static Future<List<String>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/books/get_categories.php');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['categories'] is List) {
          return (decoded['categories'] as List)
              .map((c) => c.toString())
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    return [];
  }

  static Future<Book?> fetchBookByIsbn(String isbn) async {
    final uri = Uri.parse(
      '$_baseUrl/books/get_books.php',
    ).replace(queryParameters: {'search': isbn});
    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true &&
            decoded['books'] is List &&
            (decoded['books'] as List).isNotEmpty) {
          final first = decoded['books'][0] as Map<String, dynamic>;
          return Book.fromJson(first);
        }
      }
    } catch (_) {
      // swallow; caller will handle null
    }
    return null;
  }

  static Future<ApiResponse> addBook(
    BookPayload payload, {
    String? imagePath,
  }) async {
    // If image path provided, use multipart upload
    if (imagePath != null && imagePath.isNotEmpty) {
      return _postWithFile('books/add_book.php', payload.toJson(), imagePath);
    }
    return _post('books/add_book.php', payload.toJson());
  }

  static Future<ApiResponse> updateBook({
    required String isbn,
    required BookPayload payload,
  }) async {
    final body = payload.toJson()..['isbn'] = isbn;
    return _post('books/update_book.php', body);
  }

  static Future<ApiResponse> updateBookImage({
    required String isbn,
    required String imagePath,
  }) async {
    final uri = Uri.parse('$_baseUrl/books/update_book_image.php');
    try {
      final request = http.MultipartRequest('POST', uri);

      // Add ISBN field
      request.fields['isbn'] = isbn;

      // Add file
      final file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final ok =
          decoded['success'] == true ||
          (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }

  static Future<ApiResponse> uploadRequestPdf(File pdfFile) async {
    final uri = Uri.parse('$_baseUrl/books/upload_request_pdf.php');
    try {
      final request = http.MultipartRequest('POST', uri);

      // Add file
      final file = await http.MultipartFile.fromPath('pdf', pdfFile.path);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final ok =
          decoded['success'] == true ||
          (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }

  static Future<ApiResponse> uploadCoverImage(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/books/upload_cover_image.php');
    try {
      final request = http.MultipartRequest('POST', uri);

      // Add file
      final file = await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final ok =
          decoded['success'] == true ||
          (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }

  static Future<ApiResponse> deleteBook({int? id, String? isbn}) async {
    return _post('books/delete_book.php', {
      if (id != null) 'id': id,
      if (isbn != null) 'isbn': isbn,
    });
  }

  static Future<BookStatus?> getBookStatus(String isbn) async {
    final uri = Uri.parse(
      '$_baseUrl/books/get_book_status.php',
    ).replace(queryParameters: {'isbn': isbn});

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

  static Future<ApiResponse> borrowBook({required String isbn}) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('borrow/request_borrow.php', {
      'isbn': isbn,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> returnBook({required int transactionId}) async {
    return _post('borrow/return_book.php', {'transaction_id': transactionId});
  }

  static Future<ApiResponse> requestReturn({required int transactionId}) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('borrow/request_return.php', {
      'transaction_id': transactionId,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> reserveBook({required String isbn}) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('books/reserve_book.php', {
      'isbn': isbn,
      if (email != null) 'user_email': email,
    });
  }

  static Future<ApiResponse> cancelReservation({
    required int reservationId,
    required String userEmail,
  }) async {
    return _post('books/cancel_reservation.php', {
      'reservation_id': reservationId,
      'user_email': userEmail,
    });
  }

  static Future<ApiResponse> requestAddition({
    required String title,
    String? author,
    String? isbn,
    String? description,
    String? pdfPath,
    String? category,
    String? publisher,
    int? publicationYear,
    String? edition,
    String? picPath,
    String? priority,
  }) async {
    final email = AuthService.getCurrentUserEmail();
    return _post('books/request_book.php', {
      'title': title,
      if (author != null) 'author': author,
      if (isbn != null) 'isbn': isbn,
      if (description != null) 'description': description,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (category != null) 'category': category,
      if (publisher != null) 'publisher': publisher,
      if (publicationYear != null) 'publication_year': publicationYear,
      if (edition != null) 'edition': edition,
      if (picPath != null) 'pic_path': picPath,
      if (priority != null) 'priority': priority,
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

  static Future<List<Map<String, dynamic>>> getUserTransactions(
    String email, {
    String? status,
  }) async {
    final uri = Uri.parse('$_baseUrl/borrow/get_user_transactions.php');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          if (status != null) 'status': status,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['transactions'] is List) {
          // Transform pic_path to full URLs
          return (decoded['transactions'] as List).map((t) {
            final transaction = Map<String, dynamic>.from(
              t as Map<String, dynamic>,
            );
            if (transaction['pic_path'] != null) {
              transaction['pic_path'] = _absolutePath(
                transaction['pic_path'] as String?,
              );
            }
            return transaction;
          }).toList();
        }
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }

  static Future<List<dynamic>> getNotifications(
    String email, {
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/auth/get_notifications.php?email=$email&limit=$limit',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<dynamic>.from(data['notifications'] ?? []);
        }
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }

  static Future<List<dynamic>?> getAdditionRequestDetails(int requestId) async {
    try {
      final resp = await http.get(
        Uri.parse(
          '$_baseUrl/books/get_request_details.php?request_id=$requestId',
        ),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true) {
          return [data['item']];
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<ApiResponse> approveAdditionRequest(
    int requestId,
    String librarianEmail,
  ) async {
    return await _post('books/approve_request.php', {
      'request_id': requestId,
      'approved_by': librarianEmail,
    });
  }

  static Future<ApiResponse> declineAdditionRequest(
    int requestId,
    String librarianEmail, {
    String? reason,
  }) async {
    return await _post('books/decline_request.php', {
      'request_id': requestId,
      'declined_by': librarianEmail,
      if (reason != null) 'reason': reason,
    });
  }

  static Future<ApiResponse> updateAdditionRequest({
    required int requestId,
    required String title,
    required String author,
    required String isbn,
    String? category,
    String? publisher,
    String? publicationYear,
    String? edition,
    String? courseId,
    String? pdfPath,
    String? picPath,
  }) async {
    return await _post('books/update_addition_request.php', {
      'request_id': requestId,
      'title': title,
      'author': author,
      'isbn': isbn,
      if (category != null && category.isNotEmpty) 'category': category,
      if (publisher != null && publisher.isNotEmpty) 'publisher': publisher,
      if (publicationYear != null && publicationYear.isNotEmpty)
        'publication_year': publicationYear,
      if (edition != null && edition.isNotEmpty) 'edition': edition,
      if (courseId != null && courseId.isNotEmpty) 'course_id': courseId,
      if (pdfPath != null && pdfPath.isNotEmpty) 'pdf_path': pdfPath,
      if (picPath != null && picPath.isNotEmpty) 'pic_path': picPath,
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
          if (value is List) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
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
      final ok =
          decoded['success'] == true ||
          (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }

  static Future<ApiResponse> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
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
      final ok =
          decoded['success'] == true ||
          (resp.statusCode >= 200 && resp.statusCode < 300);
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
  final String? courseId;

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
    this.courseId,
  });

  bool get isAvailable => availableQuantity > 0;

  factory Book.fromJson(Map<String, dynamic> json) {
    final picPath =
        json['pic_path'] as String? ?? json['cover_image'] as String?;
    final resolvedPic = BookService._absolutePath(picPath);
    return Book(
      id: int.tryParse('${json['id'] ?? json['isbn']}') ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      isbn: json['isbn'] as String?,
      category: json['category'] as String?,
      quantity:
          int.tryParse('${json['copies_total'] ?? json['quantity'] ?? 0}') ?? 0,
      availableQuantity:
          int.tryParse(
            '${json['copies_available'] ?? json['available_quantity'] ?? 0}',
          ) ??
          0,
      coverImage: resolvedPic.isEmpty ? null : resolvedPic,
      pdfUrl: json['pdf_url'] as String?,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publicationYear: int.tryParse('${json['publication_year']}'),
      edition: json['edition'] as String?,
      pages: int.tryParse('${json['pages']}'),
      courseId: json['course_id'] as String?,
    );
  }
}

class BookPayload {
  final String title;
  final String author;
  final String isbn;
  final String? category;
  final String? courseId;
  final String? publisher;
  final String? publicationYear;
  final String? edition;
  final int? copiesTotal;
  final int? shelfId;
  final int? compartmentNo;
  final int? subcompartmentNo;
  final String? coverImage;
  final String? pdfUrl;
  final String? description;
  final String? conditionNote;
  final List<String>? copyIds;
  final List<Map<String, int>>? copyLocations;

  BookPayload({
    required this.title,
    required this.author,
    required this.isbn,
    this.category,
    this.courseId,
    this.publisher,
    this.publicationYear,
    this.edition,
    this.copiesTotal,
    this.shelfId,
    this.compartmentNo,
    this.subcompartmentNo,
    this.coverImage,
    this.pdfUrl,
    this.description,
    this.conditionNote,
    this.copyIds,
    this.copyLocations,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      if (category != null) 'category': category,
      if (courseId != null) 'course_id': courseId,
      if (publisher != null) 'publisher': publisher,
      if (publicationYear != null) 'publication_year': publicationYear,
      if (edition != null) 'edition': edition,
      if (copiesTotal != null) 'copies_total': copiesTotal,
      if (shelfId != null) 'shelf_id': shelfId,
      if (compartmentNo != null) 'compartment_no': compartmentNo,
      if (subcompartmentNo != null) 'subcompartment_no': subcompartmentNo,
      if (coverImage != null) 'cover_image': coverImage,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (description != null) 'description': description,
      if (conditionNote != null) 'condition_note': conditionNote,
      if (copyIds != null && copyIds!.isNotEmpty) 'copy_ids': copyIds,
      if (copyLocations != null && copyLocations!.isNotEmpty)
        'copy_locations': copyLocations,
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

  const ApiResponse({
    required this.ok,
    required this.message,
    required this.data,
  });
}
