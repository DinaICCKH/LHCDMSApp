import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points to your session manager

class DailySaleReportItem {
  final int? code;
  final String? message;
  final String? type;
  final String? saleName;
  final double? totalAmtAsDate;
  final int? totalInvoiceAsDate;
  final double? totalAmtYesterday;
  final int? totalInvoiceYesterday;
  final double? amountRateChangePercent;
  final String? amountStatus;

  DailySaleReportItem({
    this.code,
    this.message,
    this.type,
    this.saleName,
    this.totalAmtAsDate,
    this.totalInvoiceAsDate,
    this.totalAmtYesterday,
    this.totalInvoiceYesterday,
    this.amountRateChangePercent,
    this.amountStatus,
  });

  factory DailySaleReportItem.fromJson(Map<String, dynamic> json) {
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

    return DailySaleReportItem(
      code: toNullableInt(json['Code']),
      message: json['Message']?.toString(),
      type: json['Type']?.toString(),
      saleName: json['SaleName']?.toString(),
      totalAmtAsDate: toNullableDouble(json['TotalAmtAsDate']),
      totalInvoiceAsDate: toNullableInt(json['TotalInvoiceAsDate']),
      totalAmtYesterday: toNullableDouble(json['TotalAmtYesterday']),
      totalInvoiceYesterday: toNullableInt(json['TotalInvoiceYesterday']),
      amountRateChangePercent: toNullableDouble(json['AmountRateChangePercent']),
      amountStatus: json['AmountStatus']?.toString(),
    );
  }
}

class DailySaleReportApi {
  static const String apiUrl = "https://www.icckh.com/dms/dev/lhc/api/Marketing/Report01DailySaleReport";

  static Future<List<DailySaleReportItem>> fetchReport({
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
          return rawList.map((e) => DailySaleReportItem.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("❌ Error fetching Daily Sale Report: $e");
    }
    return [];
  }
}