import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points to your global user session context manager

/// =============================================================
/// VISIT CHECK-IN/OUT RESULT DATA MODEL
/// =============================================================
class VisitCheckInResult {
  final int code;
  final String message;
  final int docEntry;
  final String cardCode;
  final String? checkInImage;
  final String? checkOutImage;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? checkInGps;
  final String? checkOutGps;
  final String? checkInRemark;
  final String? checkOutRemark;
  final String? checkStatus;
  final int? appOrderEntry;
  final int? dmsOrderEntry;
  final String? salesCode;
  final String? userSign;

  VisitCheckInResult({
    required this.code,
    required this.message,
    required this.docEntry,
    required this.cardCode,
    this.checkInImage,
    this.checkOutImage,
    this.checkInDate,
    this.checkOutDate,
    this.checkInGps,
    this.checkOutGps,
    this.checkInRemark,
    this.checkOutRemark,
    this.checkStatus,
    this.appOrderEntry,
    this.dmsOrderEntry,
    this.salesCode,
    this.userSign,
  });

  factory VisitCheckInResult.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    String toStr(dynamic value) => value?.toString() ?? '';
    String? toNullableStr(dynamic value) => value?.toString();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return VisitCheckInResult(
      code: toInt(json['Code']),
      message: toStr(json['Message']),
      docEntry: toInt(json['DocEntry']),
      cardCode: toStr(json['CardCode']),
      checkInImage: toNullableStr(json['CheckInImage']),
      checkOutImage: toNullableStr(json['CheckOutImage']),
      checkInDate: parseDate(json['CheckInDate']),
      checkOutDate: parseDate(json['CheckOutDate']),
      checkInGps: toNullableStr(json['CheckInGPS']),
      checkOutGps: toNullableStr(json['CheckOutGPS']),
      checkInRemark: toNullableStr(json['CheckInRemark']),
      checkOutRemark: toNullableStr(json['CheckOutRemark']),
      checkStatus: toNullableStr(json['CheckStatus']),
      appOrderEntry: toNullableInt(json['AppOrderEntry']),
      dmsOrderEntry: toNullableInt(json['DMSOrderEntry']),
      salesCode: toNullableStr(json['SalesCode']),
      userSign: toNullableStr(json['UserSign']),
    );
  }
}

/// =============================================================
/// VISIT PLAN CHECK-IN API SERVICE
/// =============================================================
class VisitPlanCheckInApi {
  static const String baseUrl = "https://www.icckh.com/dms/dev/lhc/api/Marketing/";

  static Future<List<VisitCheckInResult>> fetchVisitCheckIns({
    required String passwordHash,
    required String fromDate,
    required String toDate,
    String status = "All",
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session available for parsing logs.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetVisitPlanCheckInListing");

    final Map<String, dynamic> requestMap = {
      "UserCode": user.userCode,
      "Password": passwordHash,
      "DeviceID": user.deviceID,
      "FromDate": fromDate,
      "ToDate": toDate,
      "Status": status,
    };

    print("=================== VISIT LISTING REQUEST ===================");
    print(const JsonEncoder.withIndent('  ').convert(requestMap));
    print("=============================================================");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestMap),
      ).timeout(const Duration(seconds: 15));

      print("📡 [Visit API Status Response]: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<dynamic> rawList = result['data'];
          print("📥 [Visit Data Loaded]: Successfully found ${rawList.length} transaction entries.");
          return rawList.map((e) => VisitCheckInResult.fromJson(e)).toList();
        } else {
          print("⚠️ [Visit API Error]: Success flag false. Body context: ${response.body}");
        }
      } else {
        print("❌ [Server Error]: HTTP Listing failure context code ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("❌ Error fetching check-in listings from runtime array: $e");
      return [];
    }
  }
}