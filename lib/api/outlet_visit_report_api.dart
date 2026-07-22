// outlet_visit_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points to your session manager

class OutletVisitItem {
  final int? code;
  final String? message;
  final String? type;
  final String? saleName;
  final int? salesCode;
  final int? docYear;
  final String? docNum;
  final String? visitDate;
  final String? cardCode;
  final String? reasonType;
  final String? remark;
  final String? visited;
  final int? detailEntry;
  final int? soEntry;

  OutletVisitItem({
    this.code,
    this.message,
    this.type,
    this.saleName,
    this.salesCode,
    this.docYear,
    this.docNum,
    this.visitDate,
    this.cardCode,
    this.reasonType,
    this.remark,
    this.visited,
    this.detailEntry,
    this.soEntry,
  });

  factory OutletVisitItem.fromJson(Map<String, dynamic> json) {
    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return OutletVisitItem(
      code: toNullableInt(json['Code']),
      message: json['Message']?.toString(),
      type: json['Type']?.toString(),
      saleName: json['SaleName']?.toString(),
      salesCode: toNullableInt(json['SalesCode']),
      docYear: toNullableInt(json['DocYear']),
      docNum: json['DocNum']?.toString(),
      visitDate: json['VisitDate']?.toString(),
      cardCode: json['CardCode']?.toString(),
      reasonType: json['ReasonType']?.toString(),
      remark: json['Remark']?.toString(),
      visited: json['Visited']?.toString(),
      detailEntry: toNullableInt(json['DetailEntry']),
      soEntry: toNullableInt(json['SOEntry']),
    );
  }
}

class OutletVisitApi {
  static const String apiUrl = "https://www.icckh.com/dms/dev/lhc/api/Marketing/Report02OutletVisit";

  static Future<List<OutletVisitItem>> fetchReport({
    required String passwordHash,
    required String asDate, // Format: "yyyy-MM-dd"
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      print("❌ No user session found.");
      return [];
    }

    final Map<String, dynamic> requestMap = {
      "UserCode": user.userCode,
      "Password": passwordHash,
      "DeviceID": user.deviceID,
      "AsDate": asDate,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestMap),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['success'] == true && decoded['data'] is List) {
          final List<dynamic> rawList = decoded['data'];
          return rawList.map((e) => OutletVisitItem.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("❌ Error fetching Outlet Visit Report: $e");
    }
    return [];
  }
}