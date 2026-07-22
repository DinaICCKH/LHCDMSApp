// opportunity_report_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Ensure this points to your session manager

class OpportunityReportItem {
  final int? code;
  final String? message;
  final String? type;
  final String? saleName;
  final int? totalOpportunity;
  final int? totalVisit;
  final int? totalUnVisit;
  final int? totalBuy;
  final int? totalNoBuy;
  final double? visitPercent;
  final double? unVisitPercent;
  final double? buyPercent;
  final double? noBuyPercent;

  OpportunityReportItem({
    this.code,
    this.message,
    this.type,
    this.saleName,
    this.totalOpportunity,
    this.totalVisit,
    this.totalUnVisit,
    this.totalBuy,
    this.totalNoBuy,
    this.visitPercent,
    this.unVisitPercent,
    this.buyPercent,
    this.noBuyPercent,
  });

  factory OpportunityReportItem.fromJson(Map<String, dynamic> json) {
    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return OpportunityReportItem(
      code: toNullableInt(json['Code']),
      message: json['Message']?.toString(),
      type: json['Type']?.toString(),
      saleName: json['SaleName']?.toString(),
      totalOpportunity: toNullableInt(json['TotalOpportunity']),
      totalVisit: toNullableInt(json['TotalVisit']),
      totalUnVisit: toNullableInt(json['TotalUnVisit']),
      totalBuy: toNullableInt(json['TotalBuy']),
      totalNoBuy: toNullableInt(json['TotalNoBuy']),
      visitPercent: toNullableDouble(json['VisitPercent']),
      unVisitPercent: toNullableDouble(json['UnVisitPercent']),
      buyPercent: toNullableDouble(json['BuyPercent']),
      noBuyPercent: toNullableDouble(json['NoBuyPercent']),
    );
  }
}

class OpportunityReportApi {
  static const String _url = 'https://www.icckh.com/dms/dev/lhc/api/Marketing/Report05Opportunity';

  static Future<List<OpportunityReportItem>> fetchReport({
    required String passwordHash,
    required String asDate,
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
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestMap),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List<dynamic> rawList = decoded['data'];
          return rawList.map((item) => OpportunityReportItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print("❌ Error fetching Opportunity Report: $e");
    }
    return [];
  }
}