import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_api.dart';

/// =======================
/// VISIT PLAN MODEL
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

  /// SAFE PARSERS
  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) =>
      (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  /// =======================
  /// FROM JSON (FIXED CASE)
  /// =======================
  factory VisitPlan.fromJson(Map<String, dynamic> json) {
    return VisitPlan(
      code: _int(json['Code']),
      message: _str(json['Message']),

      docEntry: _int(json['DocEntry']),
      salesCode: _int(json['SalesCode']),
      docYear: _int(json['DocYear']),

      remarkH: _str(json['RemarkH']),
      docNum: _str(json['DocNum']),
      status: _str(json['Status']),

      visitDate: DateTime.tryParse(_str(json['VisitDate'])) ??
          DateTime.now(),

      cardCode: _str(json['CardCode']),
      cardName: _str(json['CardName']),
      tel1: _str(json['Tel1']),
      contactPersonName: _str(json['ContactPersonName']),

      reasonType: _str(json['ReasonType']),
      remark: _str(json['Remark']),
      synced: _str(json['Synced']),

      detailEntry: _int(json['DetailEntry']),
      fullAddress: _str(json['FullAddress']),
    );
  }

  /// =======================
  /// TO JSON (LOCAL STORAGE)
  /// =======================
  Map<String, dynamic> toJson() => {
    "Code": code,
    "Message": message,
    "DocEntry": docEntry,
    "SalesCode": salesCode,
    "DocYear": docYear,
    "RemarkH": remarkH,
    "DocNum": docNum,
    "Status": status,
    "VisitDate": visitDate.toIso8601String(),
    "CardCode": cardCode,
    "CardName": cardName,
    "Tel1": tel1,
    "ContactPersonName": contactPersonName,
    "ReasonType": reasonType,
    "Remark": remark,
    "Synced": synced,
    "DetailEntry": detailEntry,
    "FullAddress": fullAddress,
  };
}

/// =======================
/// VISIT PLAN API (FIXED LIKE ITEM API)
/// =======================
class VisitPlanApi {
  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/";

  /// =======================
  /// FETCH + STORE
  /// =======================
  static Future<List<VisitPlan>> fetchAndStoreVisitPlans({
    required String password,
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetVisitPlan");

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

      print("📡 VISIT PLAN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<VisitPlan> list =
          (result['data'] as List)
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
      print("❌ Error fetching Visit Plan: $e");
      return [];
    }
  }

  /// =======================
  /// GET LOCAL
  /// =======================
  static Future<List<VisitPlan>> getLocalVisitPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("visit_plans");

    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);

    return jsonList.map((e) => VisitPlan.fromJson(e)).toList();
  }

  /// =======================
  /// CLEAR LOCAL
  /// =======================
  static Future<void> clearLocalVisitPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("visit_plans");
  }
}