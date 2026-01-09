import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ShelfService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static Future<List<ShelfLocation>> getShelfLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/librarian/manage_shelves.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['shelves'] != null) {
          final shelves = data['shelves'] as List;
          List<ShelfLocation> locations = [];

          for (var shelf in shelves) {
            final shelfId = shelf['shelf_id'] as int;
            final compartment = shelf['compartment'] as int;
            final subcompartment = shelf['subcompartment'] as int;

            // Each entry is a unique shelf location
            locations.add(
              ShelfLocation(
                shelfId: shelfId,
                compartmentNo: compartment,
                subcompartmentNo: subcompartment,
              ),
            );
          }

          return locations;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching shelf locations: $e');
      return [];
    }
  }

  static Future<void> removeShelfLocation(
    int shelfId,
    int compartment,
    int subcompartment,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/librarian/manage_shelves.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shelf_id': shelfId,
          'compartment': compartment,
          'subcompartment': subcompartment,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove shelf: ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to remove shelf');
      }
    } catch (e) {
      throw Exception('Error removing shelf location: $e');
    }
  }
}

class ShelfLocation {
  final int shelfId;
  final int compartmentNo;
  final int subcompartmentNo;

  ShelfLocation({
    required this.shelfId,
    required this.compartmentNo,
    required this.subcompartmentNo,
  });

  String get displayName => '$shelfId$compartmentNo$subcompartmentNo';

  String get detailedName =>
      'Shelf $shelfId - Compartment $compartmentNo - Sub $subcompartmentNo';

  Map<String, dynamic> toJson() {
    return {
      'shelf_id': shelfId,
      'compartment_no': compartmentNo,
      'subcompartment_no': subcompartmentNo,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShelfLocation &&
        other.shelfId == shelfId &&
        other.compartmentNo == compartmentNo &&
        other.subcompartmentNo == subcompartmentNo;
  }

  @override
  int get hashCode =>
      shelfId.hashCode ^ compartmentNo.hashCode ^ subcompartmentNo.hashCode;
}
