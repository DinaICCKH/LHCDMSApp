import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// UOM MODEL CLASS
/// =======================
class Uom {
  final int code;
  final String message;
  final int uomEntry;
  final String uomCode;
  final String? status;

  Uom({
    required this.code,
    required this.message,
    required this.uomEntry,
    required this.uomCode,
    this.status,
  });

  factory Uom.fromJson(Map<String, dynamic> json) => Uom(
    code: json['code'],
    message: json['message'],
    uomEntry: json['uoMEntry'],   // ✅ match API
    uomCode: json['uoMCode'],     // ✅ match API
    status: json['status'],       // ✅ nullable
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "uoMEntry": uomEntry,
    "uoMCode": uomCode,
    "status": status,
  };
}

/// =======================
/// UOM API & LOCAL STORAGE
/// =======================
class UomApi {
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Fetch UOM from API and store locally
  static Future<List<Uom>> fetchAndStoreUoms({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetUoM");

    final body = jsonEncode({
      "UserCode": userCode,
      "Password": password,
      "DeviceID": deviceID,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] != null) {
          final List<Uom> uoms = (result['data'] as List)
              .map((e) => Uom.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "uoms",
            jsonEncode(uoms.map((e) => e.toJson()).toList()),
          );

          return uoms;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching UOM: $e");
      return [];
    }
  }

  /// Get UOM from local
  static Future<List<Uom>> getLocalUoms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("uoms");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Uom.fromJson(e)).toList();
    }

    return [];
  }

  /// Clear local UOM
  static Future<void> clearLocalUoms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uoms");
  }
}