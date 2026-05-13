import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_api.dart';

/// =======================
/// CUSTOMER MODEL
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

  /// SAFE PARSERS
  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  static double _double(dynamic v) => (v is num)
      ? v.toDouble()
      : double.tryParse(v?.toString() ?? '') ?? 0.0;

  /// =======================
  /// FROM JSON (FIXED FOR YOUR API)
  /// =======================
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      code: _int(json['Code']),
      message: _str(json['Message']),

      cardCode: _str(json['CardCode']),
      cardName: _str(json['CardName']),
      cardFName: _str(json['CardFName']),

      groupCode: _int(json['GroupCode']),
      groupName: _str(json['GroupName']),

      id: _str(json['ID']),
      tel1: _str(json['Tel1']),
      tel2: _str(json['Tel2']),
      mobile: _str(json['Mobile']),

      contactPerson: _str(json['ContactPerson']),
      contactPersonName: _str(json['ContactPersonName']),

      fullAddress: _str(json['FullAddress']),

      /// IMPORTANT: API spelling is "Paymenterm"
      paymentTerm: _str(json['Paymenterm']),

      priceList: _str(json['PriceList']),

      creditLimit: _double(json['CreditLimit']),
    );
  }

  /// =======================
  /// TO JSON (STORE LOCALLY)
  /// =======================
  Map<String, dynamic> toJson() {
    return {
      "Code": code,
      "Message": message,
      "CardCode": cardCode,
      "CardName": cardName,
      "CardFName": cardFName,
      "GroupCode": groupCode,
      "GroupName": groupName,
      "ID": id,
      "Tel1": tel1,
      "Tel2": tel2,
      "Mobile": mobile,
      "ContactPerson": contactPerson,
      "ContactPersonName": contactPersonName,
      "FullAddress": fullAddress,
      "Paymenterm": paymentTerm,
      "PriceList": priceList,
      "CreditLimit": creditLimit,
    };
  }
}

/// =======================
/// CUSTOMER API
/// (MATCH ITEM STYLE: SessionManager)
/// =======================
class CustomerApi {
  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/";

  /// =======================
  /// FETCH + STORE
  /// =======================
  static Future<List<Customer>> fetchAndStoreCustomers({
    required String password,
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetCustomer");

    final body = jsonEncode({
      "UserCode": user.userCode,
      "Password": password,
      "DeviceID": user.deviceID,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("📡 CUSTOMER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<Customer> customers =
          (result['data'] as List)
              .map((e) => Customer.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            "customers",
            jsonEncode(customers.map((e) => e.toJson()).toList()),
          );

          return customers;
        }
      }

      return [];
    } catch (e) {
      print("❌ Error fetching customers: $e");
      return [];
    }
  }

  /// =======================
  /// GET LOCAL
  /// =======================
  static Future<List<Customer>> getLocalCustomers() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonStr = prefs.getString("customers");

    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);

    return jsonList
        .map((e) => Customer.fromJson(e))
        .toList();
  }

  /// =======================
  /// CLEAR LOCAL
  /// =======================
  static Future<void> clearLocalCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("customers");
  }
}