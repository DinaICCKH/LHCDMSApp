import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// CUSTOMER MODEL CLASS
/// =======================
class Customer {
  final int code;
  final String message;
  final String cardCode;
  final String cardName;
  final String cardFName;
  final int groupCode;
  final String groupName;
  final String id;
  final String tel1;
  final String tel2;
  final String mobile;
  final String contactPerson;
  final String contactPersonName;
  final String fullAddress;
  final String paymentTerm;
  final String priceList;
  final double creditLimit;

  Customer({
    required this.code,
    required this.message,
    required this.cardCode,
    required this.cardName,
    required this.cardFName,
    required this.groupCode,
    required this.groupName,
    required this.id,
    required this.tel1,
    required this.tel2,
    required this.mobile,
    required this.contactPerson,
    required this.contactPersonName,
    required this.fullAddress,
    required this.paymentTerm,
    required this.priceList,
    required this.creditLimit,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    code: json['code'],
    message: json['message'],
    cardCode: json['cardCode'],
    cardName: json['cardName'],
    cardFName: json['cardFName'],
    groupCode: json['groupCode'],
    groupName: json['groupName'],
    id: json['id'],
    tel1: json['tel1'],
    tel2: json['tel2'],
    mobile: json['mobile'],
    contactPerson: json['contactPerson'],
    contactPersonName: json['contactPersonName'],
    fullAddress: json['fullAddress'],
    paymentTerm: json['paymenterm'] ?? "",
    priceList: json['priceList'] ?? "",
    creditLimit: (json['creditLimit'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "cardCode": cardCode,
    "cardName": cardName,
    "cardFName": cardFName,
    "groupCode": groupCode,
    "groupName": groupName,
    "id": id,
    "tel1": tel1,
    "tel2": tel2,
    "mobile": mobile,
    "contactPerson": contactPerson,
    "contactPersonName": contactPersonName,
    "fullAddress": fullAddress,
    "paymenterm": paymentTerm,
    "priceList": priceList,
    "creditLimit": creditLimit,
  };
}

/// =======================
/// CUSTOMER API & LOCAL STORAGE
/// =======================
class CustomerApi {
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Get customers from API and store to SharedPreferences
  static Future<List<Customer>> fetchAndStoreCustomers({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetCustomer");
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
          final List<Customer> customers = (result['data'] as List)
              .map((e) => Customer.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              "customers", jsonEncode(customers.map((e) => e.toJson()).toList()));

          return customers;
        }
      }
      return [];
    } catch (e) {
      print("Error fetching customers: $e");
      return [];
    }
  }

  /// Retrieve customers from local storage
  static Future<List<Customer>> getLocalCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("customers");
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Customer.fromJson(e)).toList();
    }
    return [];
  }

  /// Clear stored customers
  static Future<void> clearLocalCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("customers");
  }
}