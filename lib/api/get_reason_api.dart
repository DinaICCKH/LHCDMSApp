import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_api.dart';

/// =======================
/// REASON MODEL
/// =======================
class Reason {
  final int code;
  final String message;
  final String reason;
  final String reasonEN;
  final String reasonKH;

  Reason({
    required this.code,
    required this.message,
    required this.reason,
    required this.reasonEN,
    required this.reasonKH,
  });

  /// SAFE PARSERS
  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  /// =======================
  /// FROM JSON (FIXED FOR YOUR API)
  /// =======================
  factory Reason.fromJson(Map<String, dynamic> json) {
    return Reason(
      code: _int(json['Code']),
      message: _str(json['Message']),
      reason: _str(json['Reason']),
      reasonEN: _str(json['ReasonEN']),
      reasonKH: _str(json['ReasonKH']),
    );
  }

  /// =======================
  /// TO JSON (STORE LOCALLY)
  /// =======================
  Map<String, dynamic> toJson() {
    return {
      "Code": code,
      "Message": message,
      "Reason": reason,
      "ReasonEN": reasonEN,
      "ReasonKH": reasonKH,
    };
  }
}

/// =======================
/// REASON API
/// =======================
class ReasonApi {
  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/";

  /// =======================
  /// FETCH + STORE
  /// =======================
  static Future<List<Reason>> fetchAndStoreReasons({
    required String password,
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetReason");

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

      print("📡 REASON RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<Reason> reasons =
          (result['data'] as List)
              .map((e) => Reason.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            "reasons",
            jsonEncode(reasons.map((e) => e.toJson()).toList()),
          );

          return reasons;
        }
      }

      return [];
    } catch (e) {
      print("❌ Error fetching reasons: $e");
      return [];
    }
  }

  /// =======================
  /// GET LOCAL (FIXED KEY)
  /// =======================
  static Future<List<Reason>> getLocalReasons() async {
    final prefs = await SharedPreferences.getInstance();

    // 🐛 FIX: Changed from "customers" to "reasons" to match where it is stored
    final jsonStr = prefs.getString("reasons");

    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);

    return jsonList
        .map((e) => Reason.fromJson(e))
        .toList();
  }

  /// =======================
  /// CLEAR LOCAL
  /// =======================
  static Future<void> clearLocalReasons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("reasons");
  }
} // 🐛 FIX: Removed trailing comma at the very end of the class