import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// WAREHOUSE MODEL CLASS
/// =======================
class Warehouse {
  final int code;
  final String message;
  final String whsCode;
  final String whsName;
  final String whsStatus;
  final String shows;

  Warehouse({
    required this.code,
    required this.message,
    required this.whsCode,
    required this.whsName,
    required this.whsStatus,
    required this.shows,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    code: json['code'],
    message: json['message'],
    whsCode: json['whsCode'],
    whsName: json['whsName'],
    whsStatus: json['whsStatus'],
    shows: json['shows'],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "whsCode": whsCode,
    "whsName": whsName,
    "whsStatus": whsStatus,
    "shows": shows,
  };
}

/// =======================
/// WAREHOUSE API & LOCAL STORAGE
/// =======================
class WarehouseApi {
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Fetch warehouse from API and store locally
  static Future<List<Warehouse>> fetchAndStoreWarehouses({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetWhs");

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
          final List<Warehouse> warehouses = (result['data'] as List)
              .map((e) => Warehouse.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "warehouses",
            jsonEncode(warehouses.map((e) => e.toJson()).toList()),
          );

          return warehouses;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching warehouses: $e");
      return [];
    }
  }

  /// Get warehouse from local storage
  static Future<List<Warehouse>> getLocalWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("warehouses");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Warehouse.fromJson(e)).toList();
    }

    return [];
  }

  /// Clear local warehouse data
  static Future<void> clearLocalWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("warehouses");
  }
}