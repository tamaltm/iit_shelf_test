import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CourseService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://32.0.2.182:8000';
    return 'http://localhost:8000';
  }

  static Future<List<Course>> fetchCourses() async {
    final uri = Uri.parse('$_baseUrl/courses/list_courses.php');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['courses'] is List) {
          return (decoded['courses'] as List)
              .map((c) => Course.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // return empty on network error; caller can show retry
    }
    return [];
  }

  static Future<CourseApiResponse> addCourse({
    required String courseId,
    required String courseName,
    String? semester,
  }) async {
    final uri = Uri.parse('$_baseUrl/courses/add_course.php');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'course_id': courseId,
          'course_name': courseName,
          if (semester != null && semester.isNotEmpty) 'semester': semester,
        }),
      );

      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};

      final ok = decoded['success'] == true ||
          (resp.statusCode >= 200 && resp.statusCode < 300);
      final message = decoded['message'] as String? ?? 'Request failed';
      return CourseApiResponse(ok: ok, message: message, data: decoded);
    } catch (e) {
      return CourseApiResponse(ok: false, message: 'Network error: $e', data: {});
    }
  }
}

class Course {
  final String id;
  final String name;
  final String? semester;

  Course({required this.id, required this.name, this.semester});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['course_id'] as String? ?? '',
      name: json['course_name'] as String? ?? '',
      semester: json['semester'] as String?,
    );
  }
}

class CourseApiResponse {
  final bool ok;
  final String message;
  final Map<String, dynamic> data;

  CourseApiResponse({required this.ok, required this.message, required this.data});
}
