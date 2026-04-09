import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// UOM GROUP MODEL CLASS
/// =======================
class UomGroup {
  final int code;
  final String message;
  final int ugpEntry;
  final int uomEntry;
  final String ugpName;
  final String uomCode;
  final double baseQty;
  final double altQty;
  final String status;

  UomGroup({
    required this.code,
    required this.message,
    required this.ugpEntry,
    required this.uomEntry,
    required this.ugpName,
    required this.uomCode,
    required this.baseQty,
    required this.altQty,
    required this.status,
  });

  factory UomGroup.fromJson(Map<String, dynamic> json) => UomGroup(
    code: json['code'],
    message: json['message'],
    ugpEntry: json['ugpEntry'],
    uomEntry: json['uoMEntry'], // ✅ match API
    ugpName: json['ugpName'],
    uomCode: json['uoMCode'],   // ✅ match API
    baseQty: (json['baseQty'] as num).toDouble(),
    altQty: (json['altQty'] as num).toDouble(),
    status: json['status'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "ugpEntry": ugpEntry,
    "uoMEntry": uomEntry,
    "ugpName": ugpName,
    "uoMCode": uomCode,
    "baseQty": baseQty,
    "altQty": altQty,
    "status": status,
  };
}

/// =======================
/// UOM GROUP API & STORAGE
/// =======================
class UomGroupApi {
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Fetch from API and store locally
  static Future<List<UomGroup>> fetchAndStoreUomGroups({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetUoMGroup");

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
          final List<UomGroup> list = (result['data'] as List)
              .map((e) => UomGroup.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "uom_groups",
            jsonEncode(list.map((e) => e.toJson()).toList()),
          );

          return list;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching UOM Group: $e");
      return [];
    }
  }

  /// Get local data
  static Future<List<UomGroup>> getLocalUomGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("uom_groups");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => UomGroup.fromJson(e)).toList();
    }

    return [];
  }

  /// Clear local
  static Future<void> clearLocalUomGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uom_groups");
  }
}