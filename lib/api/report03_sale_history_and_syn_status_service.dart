import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points to your session manager

class Report03SaleHistoryandSynStatusRecord {
  final int code;
  final String message;
  final String type;
  final String saleName;
  final int docEntry;
  final String docStatus;
  final String docDate;
  final String docDueDate;
  final String deliveryTime;
  final String cardCode;
  final String cardName;
  final double docTotal;
  final String apiStatus;
  final String apiErrMessage;
  final String sapDocEntry;
  final String sapLastError;

  Report03SaleHistoryandSynStatusRecord({
    required this.code,
    required this.message,
    required this.type,
    required this.saleName,
    required this.docEntry,
    required this.docStatus,
    required this.docDate,
    required this.docDueDate,
    required this.deliveryTime,
    required this.cardCode,
    required this.cardName,
    required this.docTotal,
    required this.apiStatus,
    required this.apiErrMessage,
    required this.sapDocEntry,
    required this.sapLastError,
  });

  factory Report03SaleHistoryandSynStatusRecord.fromJson(
      Map<String, dynamic> json) {
    return Report03SaleHistoryandSynStatusRecord(
      code: json['Code'] ?? 0,
      message: json['Message'] ?? '',
      type: json['Type'] ?? '',
      saleName: json['SaleName'] ?? '',
      docEntry: json['DocEntry'] ?? 0,
      docStatus: json['DocStatus'] ?? '',
      docDate: json['DocDate'] ?? '',
      docDueDate: json['DocDueDate'] ?? '',
      deliveryTime: json['U_DeliveryTime'] ?? '',
      cardCode: json['CardCode'] ?? '',
      cardName: json['CardName'] ?? '',
      docTotal: (json['DocTotal'] as num?)?.toDouble() ?? 0.0,
      apiStatus: json['APIStatus'] ?? '',
      apiErrMessage: json['APIErrMessage'] ?? '',
      sapDocEntry: json['SAPDocEntry']?.toString() ?? '',
      sapLastError: json['SAPLastError'] ?? '',
    );
  }
}

class Report03SaleHistoryandSynStatusResponse {
  final bool success;
  final String message;
  final int total;
  final List<Report03SaleHistoryandSynStatusRecord> data;

  Report03SaleHistoryandSynStatusResponse({
    required this.success,
    required this.message,
    required this.total,
    required this.data,
  });

  factory Report03SaleHistoryandSynStatusResponse.fromJson(
      Map<String, dynamic> json) {

    List<Report03SaleHistoryandSynStatusRecord> dataList = [];

    if (json['data'] is List) {
      dataList = (json['data'] as List)
          .map((e) => Report03SaleHistoryandSynStatusRecord.fromJson(e))
          .toList();
    }

    return Report03SaleHistoryandSynStatusResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      total: json['total'] ?? dataList.length,
      data: dataList,
    );
  }
}

class Report03SaleHistoryandSynStatusService {
  static const String endpoint =
      'https://www.icckh.com/dms/dev/lhc/api/Marketing/Report03SaleHistoryandSynStatus';

  Future<Report03SaleHistoryandSynStatusResponse> fetchReport({
    required String passwordHash,
    required String fromDate,
    required String toDate,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      print("❌ No user session found.");
      return Report03SaleHistoryandSynStatusResponse(
        success: false,
        message: 'No user session found',
        total: 0,
        data: [],
      );
    }

    final body = {
      "UserCode": user.userCode,
      "Password": passwordHash,
      "DeviceID": user.deviceID,
      "FromDate": fromDate,
      "ToDate": toDate,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is! Map<String, dynamic>) {
        return Report03SaleHistoryandSynStatusResponse(
          success: false,
          message: 'Invalid response format',
          total: 0,
          data: [],
        );
      }

      return Report03SaleHistoryandSynStatusResponse.fromJson(jsonResponse);

    } catch (e) {
      return Report03SaleHistoryandSynStatusResponse(
        success: false,
        message: e.toString(),
        total: 0,
        data: [],
      );
    }
  }
}