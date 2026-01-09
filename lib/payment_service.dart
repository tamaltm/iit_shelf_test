import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PaymentService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  /// Fetch outstanding fines for the current user
  static Future<Fine?> fetchOutstandingFines() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return null;

    final uri = Uri.parse(
      '$_baseUrl/payments/get_user_fines.php',
    ).replace(queryParameters: {'user_email': email});

    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          return Fine.fromJson(decoded);
        }
      }
    } catch (_) {
      // Handle error silently
    }
    return null;
  }

  /// Fetch payment history for the current user
  static Future<List<PaymentRecord>> fetchPaymentHistory() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return [];

    final uri = Uri.parse(
      '$_baseUrl/payments/get_payment_history.php',
    ).replace(queryParameters: {'user_email': email});

    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['payment_history'] is List) {
          return (decoded['payment_history'] as List)
              .map((p) => PaymentRecord.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Handle error silently
    }
    return [];
  }

  /// Process payment for selected fines
  static Future<ApiResponse> processPayment(
    List<int> fineIds, {
    List<int>? transactionIds,
    String? paymentMethod,
  }) async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) {
      return ApiResponse(
        ok: false,
        message: 'User not authenticated',
        data: {},
      );
    }

    final uri = Uri.parse('$_baseUrl/payments/process_payment.php');
    final body = jsonEncode({
      'user_email': email,
      'fine_ids': fineIds,
      'transaction_ids': transactionIds ?? [],
      'payment_method': paymentMethod ?? 'cash',
    });

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final ok = decoded['success'] == true;
      final message = decoded['message'] as String? ?? 'Request failed';

      return ApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return ApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }
}

class Fine {
  final double totalOutstanding;
  final int finesCount;
  final List<FineDetail> fines;
  final int pendingFinesCount;
  final List<PendingFineDetail> pendingFines;

  Fine({
    required this.totalOutstanding,
    required this.finesCount,
    required this.fines,
    this.pendingFinesCount = 0,
    this.pendingFines = const [],
  });

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0.0,
      finesCount: json['fines_count'] as int? ?? 0,
      fines: json['fines'] is List
          ? (json['fines'] as List)
                .map((f) => FineDetail.fromJson(f as Map<String, dynamic>))
                .toList()
          : [],
      pendingFinesCount: json['pending_fines_count'] as int? ?? 0,
      pendingFines: json['pending_fines'] is List
          ? (json['pending_fines'] as List)
                .map(
                  (f) => PendingFineDetail.fromJson(f as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class FineDetail {
  final int fineId;
  final double amount;
  final String? description;
  final bool paid;
  final String? paymentDate;

  FineDetail({
    required this.fineId,
    required this.amount,
    this.description,
    required this.paid,
    this.paymentDate,
  });

  factory FineDetail.fromJson(Map<String, dynamic> json) {
    return FineDetail(
      fineId: json['fine_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      paid: json['paid'] as bool? ?? false,
      paymentDate: json['payment_date'] as String?,
    );
  }
}

class PendingFineDetail {
  final int transactionId;
  final String bookTitle;
  final int daysOverdue;
  final double amount;
  final String? description;

  PendingFineDetail({
    required this.transactionId,
    required this.bookTitle,
    required this.daysOverdue,
    required this.amount,
    this.description,
  });

  factory PendingFineDetail.fromJson(Map<String, dynamic> json) {
    return PendingFineDetail(
      transactionId: json['transaction_id'] as int,
      bookTitle: json['book_title'] as String,
      daysOverdue: json['days_overdue'] as int,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}

class PaymentRecord {
  final int fineId;
  final double amount;
  final String? description;
  final String? paymentDate;
  final String paymentStatus;

  PaymentRecord({
    required this.fineId,
    required this.amount,
    this.description,
    this.paymentDate,
    required this.paymentStatus,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      fineId: json['fine_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      paymentDate: json['payment_date'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'Completed',
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
