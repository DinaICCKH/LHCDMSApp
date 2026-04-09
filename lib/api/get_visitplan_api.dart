import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// VISIT PLAN MODEL CLASS
/// =======================
class VisitPlan {
  final int code;
  final String message;
  final int docEntry;
  final int salesCode;
  final int docYear;
  final String remarkH;
  final String docNum;
  final String status;
  final DateTime visitDate;
  final String cardCode;
  final String cardName;
  final String tel1;
  final String contactPersonName;
  final String reasonType;
  final String remark;
  final String synced;
  final int detailEntry;
  final String fullAddress;

  VisitPlan({
    required this.code,
    required this.message,
    required this.docEntry,
    required this.salesCode,
    required this.docYear,
    required this.remarkH,
    required this.docNum,
    required this.status,
    required this.visitDate,
    required this.cardCode,
    required this.cardName,
    required this.tel1,
    required this.contactPersonName,
    required this.reasonType,
    required this.remark,
    required this.synced,
    required this.detailEntry,
    required this.fullAddress,
  });

  factory VisitPlan.fromJson(Map<String, dynamic> json) => VisitPlan(
    code: json['code'] ?? 0,
    message: json['message'] ?? "",
    docEntry: json['docEntry'] ?? 0,
    salesCode: json['salesCode'] ?? 0,
    docYear: json['docYear'] ?? 0,
    remarkH: json['remarkH'] ?? "",
    docNum: json['docNum'] ?? "",
    status: json['status'] ?? "",
    visitDate: DateTime.tryParse(json['visitDate'] ?? "") ?? DateTime.now(),
    cardCode: json['cardCode'] ?? "",
    cardName: json['cardName'] ?? "",
    tel1: json['tel1'] ?? "",
    contactPersonName: json['contactPersonName'] ?? "",
    reasonType: json['reasonType'] ?? "",
    remark: json['remark'] ?? "",
    synced: json['synced'] ?? "",
    detailEntry: json['detailEntry'] ?? 0,
    fullAddress: json['fullAddress'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "docEntry": docEntry,
    "salesCode": salesCode,
    "docYear": docYear,
    "remarkH": remarkH,
    "docNum": docNum,
    "status": status,
    "visitDate": visitDate.toIso8601String(),
    "cardCode": cardCode,
    "cardName": cardName,
    "tel1": tel1,
    "contactPersonName": contactPersonName,
    "reasonType": reasonType,
    "remark": remark,
    "synced": synced,
    "detailEntry": detailEntry,
    "fullAddress": fullAddress,
  };
}

/// =======================
/// VISIT PLAN API & STORAGE
/// =======================
class VisitPlanApi {
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Fetch from API and store locally
  static Future<List<VisitPlan>> fetchAndStoreVisitPlans({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetVisitPlan");


    final body = jsonEncode({
    "UserCode": userCode,
    "Password": password,
    "DeviceID": deviceID,
    });

    try {
    final response = await http
        .post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
    )
        .timeout(const Duration(seconds: 15));

    print("VisitPlan Status: ${response.statusCode}");
    print("VisitPlan Body: ${response.body}");

    if (response.statusCode == 200) {
    final Map<String, dynamic> result = jsonDecode(response.body);

    if (result['success'] == true && result['data'] != null) {
    final List<VisitPlan> list = (result['data'] as List)
        .map((e) => VisitPlan.fromJson(e))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
    "visit_plans",
    jsonEncode(list.map((e) => e.toJson()).toList()),
    );

    return list;
    }
    }

    return [];
    } catch (e) {
    print("Error fetching Visit Plan: $e");
    return [];
    }


  }

  /// Get local data
  static Future<List<VisitPlan>> getLocalVisitPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("visit_plans");


    if (jsonStr != null) {
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((e) => VisitPlan.fromJson(e)).toList();
    }

    return [];


  }

  /// Clear local storage
  static Future<void> clearLocalVisitPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("visit_plans");
  }
}
