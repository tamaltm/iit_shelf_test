import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LibrarySettingsService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  /// Fetch library contact information and settings
  static Future<LibrarySettings?> fetchLibrarySettings() async {
    final uri = Uri.parse('$_baseUrl/api/settings/get_library_settings.php');

    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          return LibrarySettings.fromJson(
            decoded['settings'] as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      // Handle error silently or log
      print('Error fetching library settings: $e');
    }
    return null;
  }
}

class LibrarySettings {
  final String email;
  final String phone;
  final String hours;
  final String location;

  LibrarySettings({
    required this.email,
    required this.phone,
    required this.hours,
    required this.location,
  });

  factory LibrarySettings.fromJson(Map<String, dynamic> json) {
    return LibrarySettings(
      email: json['library_email'] as String? ?? 'library@nstu.edu.bd',
      phone: json['library_phone'] as String? ?? '+880 1234-567890',
      hours: json['library_hours'] as String? ?? 'Mon-Fri: 9:00 AM - 5:00 PM',
      location:
          json['library_location'] as String? ?? 'Central Library, NSTU Campus',
    );
  }
}
