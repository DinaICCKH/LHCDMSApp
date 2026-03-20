import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
class ItemPricing {
  final int code;
  final String message;
  final String itemCode;
  final String priceListCode;
  final String uoMEntry;
  final double amount;
  final String status;

  ItemPricing({
    required this.code,
    required this.message,
    required this.itemCode,
    required this.priceListCode,
    required this.uoMEntry,
    required this.amount,
    required this.status,
  });

  factory ItemPricing.fromJson(Map<String, dynamic> json) => ItemPricing(
    code: json['code'],
    message: json['message'],
    itemCode: json['itemCode'],
    priceListCode: json['priceListCode'],
    uoMEntry: json['uoMEntry'],
    amount: (json['amount'] as num).toDouble(),
    status: json['status'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "itemCode": itemCode,
    "priceListCode": priceListCode,
    "uoMEntry": uoMEntry,
    "amount": amount,
    "status": status,
  };
}

/// =======================
/// Item Pricing API & STORAGE
/// =======================
class ItemPricingApi {
  static const String baseUrl = "http://192.168.88.108:90/api/DMS";

  /// Fetch from API and store locally
  static Future<List<ItemPricing>> fetchAndStoreItemPricing({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetItemPricing");

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
          final List<ItemPricing> list = (result['data'] as List)
              .map((e) => ItemPricing.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "item_pricing",
            jsonEncode(list.map((e) => e.toJson()).toList()),
          );

          return list;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching Item Pricing: $e");
      return [];
    }
  }

  /// Get local data
  static Future<List<ItemPricing>> getLocalItemPricing() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("item_pricing");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => ItemPricing.fromJson(e)).toList();
    }

    return [];
  }

  /// Clear local
  static Future<void> clearLocalItemPricing() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("item_pricing");
  }
}