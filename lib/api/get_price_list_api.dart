import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// PRICE LIST MODEL CLASS
/// =======================
class PriceList {
  final int code;
  final String message;
  final int listNum;
  final String listName;
  final String status;

  PriceList({
    required this.code,
    required this.message,
    required this.listNum,
    required this.listName,
    required this.status,
  });

  factory PriceList.fromJson(Map<String, dynamic> json) => PriceList(
    code: json['code'],
    message: json['message'],
    listNum: json['listNum'],
    listName: json['listName'],
    status: json['status'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "listNum": listNum,
    "listName": listName,
    "status": status,
  };
}

/// =======================
/// PRICE LIST API & STORAGE
/// =======================
class PriceListApi {
  static const String baseUrl = "http://192.168.88.108:90/api/DMS";

  /// Fetch from API and store locally
  static Future<List<PriceList>> fetchAndStorePriceLists({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetPriceList");

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
          final List<PriceList> list = (result['data'] as List)
              .map((e) => PriceList.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "price_lists",
            jsonEncode(list.map((e) => e.toJson()).toList()),
          );

          return list;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching Price List: $e");
      return [];
    }
  }

  /// Get local data
  static Future<List<PriceList>> getLocalPriceLists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("price_lists");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => PriceList.fromJson(e)).toList();
    }

    return [];
  }

  /// Clear local
  static Future<void> clearLocalPriceLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("price_lists");
  }
}