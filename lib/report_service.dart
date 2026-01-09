import 'dart:convert';
import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  static Future<ReportResponse> generateReport({
    required String reportType,
    String? startDate,
    String? endDate,
    String format = 'json',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/reports/generate_report.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'report_type': reportType,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          'format': format,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (decoded['success'] == true) {
          return ReportResponse(
            success: true,
            data: decoded['data'],
            message: 'Report generated successfully',
          );
        }

        return ReportResponse(
          success: false,
          message: decoded['message'] ?? 'Failed to generate report',
        );
      }

      return ReportResponse(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return ReportResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<List<RecentReport>> getRecentReports() async {
    // This would typically fetch from backend, for now return mock data limited to supported types
    return [
      RecentReport(
        title: 'Most Borrowed Books - ${_formatMonthYear(DateTime.now())}',
        date: DateTime.now(),
        reportType: 'most_borrowed',
      ),
      RecentReport(
        title: 'Most Requested Books - ${_formatMonthYear(DateTime.now().subtract(const Duration(days: 7)))}',
        date: DateTime.now().subtract(const Duration(days: 7)),
        reportType: 'most_requested',
      ),
      RecentReport(
        title:
            'Semester Wise Borrowing - ${_formatMonthYear(DateTime.now().subtract(const Duration(days: 30)))}',
        date: DateTime.now().subtract(const Duration(days: 30)),
        reportType: 'semester_wise',
      ),
    ];
  }

  static String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static Future<FileDownloadResponse> downloadReport({
    required String reportType,
    String? startDate,
    String? endDate,
    required String format, // 'csv' or 'pdf'
  }) async {
    try {
      // Request storage permission for Android
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return FileDownloadResponse(
              success: false,
              message: 'Storage permission denied',
            );
          }
        }
      }

      final uri = Uri.parse('$_baseUrl/api/reports/generate_report.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'report_type': reportType,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          'format': format,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Get Downloads directory
        Directory? directory;

        if (kIsWeb) {
          return FileDownloadResponse(
            success: false,
            message: 'File download not supported on web yet',
          );
        }

        if (Platform.isAndroid) {
          // Prefer public Downloads; if not accessible, fall back to app storage
          try {
            final downloadsDir = Directory('/storage/emulated/0/Download');
            if (await downloadsDir.exists()) {
              directory = downloadsDir;
            } else {
              directory = await getExternalStorageDirectory();
            }
          } catch (_) {
            directory = null;
          }
        } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          try {
            directory = await getDownloadsDirectory();
          } catch (_) {
            directory = null;
          }
        }

        // Final fallbacks
        if (directory == null) {
          try {
            directory = await getApplicationDocumentsDirectory();
          } catch (_) {
            directory = null;
          }
        }

        // Last-resort temp directory
        directory ??= Directory.systemTemp;

        // Ensure directory exists
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Create filename
        final timestamp = DateTime.now().toIso8601String().split('T')[0];
        final filename = '${reportType}_$timestamp.$format';
        final filePath = '${directory.path}/$filename';

        // Write file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return FileDownloadResponse(
          success: true,
          message: 'Report saved successfully',
          filePath: filePath,
        );
      }

      return FileDownloadResponse(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return FileDownloadResponse(
        success: false,
        message: 'Download error: $e',
      );
    }
  }
}

class ReportResponse {
  final bool success;
  final dynamic data;
  final String message;

  ReportResponse({required this.success, this.data, required this.message});
}

class FileDownloadResponse {
  final bool success;
  final String message;
  final String? filePath;

  FileDownloadResponse({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class RecentReport {
  final String title;
  final DateTime date;
  final String reportType;

  RecentReport({
    required this.title,
    required this.date,
    required this.reportType,
  });
}
