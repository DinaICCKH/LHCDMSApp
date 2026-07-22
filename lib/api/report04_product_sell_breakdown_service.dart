import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points to your session manager

class Report04ProductSellBreakdownRecord {
  final int code;
  final String message;
  final String type;
  final String saleName;
  final String itemCode;
  final String description;
  final double quantity;
  final String uomCode;
  final double lineTotal;

  Report04ProductSellBreakdownRecord({
    required this.code,
    required this.message,
    required this.type,
    required this.saleName,
    required this.itemCode,
    required this.description,
    required this.quantity,
    required this.uomCode,
    required this.lineTotal,
  });

  factory Report04ProductSellBreakdownRecord.fromJson(Map<String, dynamic> json) {
    return Report04ProductSellBreakdownRecord(
      code: json['Code'] ?? 0,
      message: json['Message'] ?? '',
      type: json['Type'] ?? '',
      saleName: json['SaleName'] ?? '',
      itemCode: json['ItemCode'] ?? '',
      description: json['Dscription'] ?? '',
      quantity: (json['Quantity'] as num?)?.toDouble() ?? 0.0,
      uomCode: json['UomCode'] ?? '',
      lineTotal: (json['LineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Report04ProductSellBreakdownResponse {
  final bool success;
  final String message;
  final int total;
  final List<Report04ProductSellBreakdownRecord> data;

  Report04ProductSellBreakdownResponse({
    required this.success,
    required this.message,
    required this.total,
    required this.data,
  });

  factory Report04ProductSellBreakdownResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<Report04ProductSellBreakdownRecord> dataList =
    list.map((i) => Report04ProductSellBreakdownRecord.fromJson(i)).toList();

    return Report04ProductSellBreakdownResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      total: json['total'] ?? dataList.length,
      data: dataList,
    );
  }
}

class Report04ProductSellBreakdownService {
  static const String endpoint =
      'https://www.icckh.com/dms/dev/lhc/api/Marketing/Report04ProductSellBreakdown';

  Future<Report04ProductSellBreakdownResponse> fetchReport({
    required String passwordHash,
    required String fromDate,
    required String toDate,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      print("❌ No user session found.");
      return Report04ProductSellBreakdownResponse(
        success: false,
        message: 'No user session found',
        total: 0,
        data: [],
      );
    }

    final Map<String, dynamic> body = {
      "UserCode": user.userCode,
      "Password": passwordHash,
      "DeviceID": user.deviceID,
      "FromDate": fromDate,
      "ToDate": toDate,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is! Map<String, dynamic>) {
        return Report04ProductSellBreakdownResponse(
          success: false,
          message: 'Invalid response format',
          total: 0,
          data: [],
        );
      }

      return Report04ProductSellBreakdownResponse.fromJson(jsonResponse);

    } catch (e) {
      return Report04ProductSellBreakdownResponse(
        success: false,
        message: e.toString(),
        total: 0,
        data: [],
      );
    }
  }
}