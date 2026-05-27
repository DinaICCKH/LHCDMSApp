import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_api.dart';

/// =======================
/// SALE SUMMARY MODEL
/// =======================
class SaleSummary {
  final int code;
  final String message;
  final double totalAmt;
  final int total;
  final int pendingSync;

  SaleSummary({
    required this.code,
    required this.message,
    required this.totalAmt,
    required this.total,
    required this.pendingSync,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> json) {

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      return (value as num).toDouble();
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      return (value as num).toInt();
    }

    String toStr(dynamic value) {
      return value?.toString() ?? '';
    }

    return SaleSummary(
      code: toInt(json['Code']),
      message: toStr(json['Message']),
      totalAmt: toDouble(json['TotalAmt']),
      total: toInt(json['Total']),
      pendingSync: toInt(json['PendingSync']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Code": code,
      "Message": message,
      "TotalAmt": totalAmt,
      "Total": total,
      "PendingSync": pendingSync,
    };
  }
}

/// =======================
/// SALE SUMMARY API
/// =======================
class SaleSummaryApi {

  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/";

  static const String localKey = "sale_summary";

  /// =======================
  /// FETCH & STORE SALE SUMMARY
  /// =======================
  static Future<List<SaleSummary>> fetchAndStoreSaleSummary({
    required String password,
  }) async {

    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found. Please login first.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetSaleSummarys");

    final body = jsonEncode({
      "UserCode": user.userCode,
      "Password": password,
      "DeviceID": user.deviceID,
    });

    try {

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: body,
      );

      print("📡 [Sale Summary Response]: ${response.statusCode}");

      if (response.statusCode == 200) {

        final result = jsonDecode(response.body);

        if (result['success'] == true &&
            result['data'] is List) {

          final List<dynamic> rawList = result['data'];

          /// PRINT NETWORK RECORD COUNT
          print(
            "📥 [Sale Summary Loaded]: "
                "${rawList.length} records received from API.",
          );

          final List<SaleSummary> summaries =
          rawList
              .map((e) => SaleSummary.fromJson(e))
              .toList();

          final prefs =
          await SharedPreferences.getInstance();

          final String encodedData = jsonEncode(
            summaries
                .map((e) => e.toJson())
                .toList(),
          );

          /// SAVE LOCAL
          await prefs.setString(
            localKey,
            encodedData,
          );

          /// PRINT SAVE SUCCESS
          print(
            "💾 [Sale Summary Saved]: "
                "${summaries.length} records saved locally.",
          );

          /// PREVIEW DATA
          print(
            "🔍 [Preview Saved Data]: $encodedData",
          );

          return summaries;

        } else {

          print(
            "⚠️ [API Warning]: "
                "Response success is false "
                "or data is not a list.",
          );

          print(response.body);
        }
      } else {

        print(
          "❌ [Server Error]: "
              "HTTP status code ${response.statusCode}",
        );
      }

      return [];

    } catch (e) {

      print("❌ Error fetching sale summary: $e");

      return [];
    }
  }

  /// =======================
  /// GET LOCAL SALE SUMMARY
  /// =======================
  static Future<List<SaleSummary>>
  getLocalSaleSummary() async {

    final prefs =
    await SharedPreferences.getInstance();

    final jsonStr =
    prefs.getString(localKey);

    if (jsonStr != null) {

      final List<dynamic> jsonList =
      jsonDecode(jsonStr);

      /// PRINT LOCAL DATA COUNT
      print(
        "📖 [Local Data Read]: "
            "Found ${jsonList.length} "
            "sale summary records locally.",
      );

      /// PREVIEW LOCAL DATA
      print(
        "🔍 [Preview Local Data]: $jsonStr",
      );

      return jsonList
          .map((e) => SaleSummary.fromJson(e))
          .toList();
    }

    print(
      "ℹ️ [Local Data Read]: "
          "No sale summary found in SharedPreferences.",
    );

    return [];
  }

  /// =======================
  /// CLEAR LOCAL SALE SUMMARY
  /// =======================
  static Future<void>
  clearLocalSaleSummary() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(localKey);

    print(
      "🗑️ [Local Data Cleared]: "
          "Successfully deleted "
          "'$localKey' from SharedPreferences.",
    );
  }
}