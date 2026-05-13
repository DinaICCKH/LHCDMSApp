import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
// USER LOG ITEM API SERVICE
// Endpoint:
// POST https://www.icckh.com/dms/dev/lhc/api/Marketing/AddUserLogItem
// ─────────────────────────────────────────────────────────────────

class UserLogItemApi {
  static final http.Client _client = http.Client();

  static const String _baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/Marketing/AddUserLogItem";

  // ── Submit User Log Items ──────────────────────────────────────
  static Future<UserLogResult> submitLogs({
    required List<UserLogItemPayload> logs,
  }) async {
    try {
      final body = jsonEncode(
        logs.map((e) => e.toJson()).toList(),
      );

      final response = await _client
          .post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30));

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return UserLogResult.success(decoded);
      }

      return UserLogResult.failure(
        "Server error: ${response.statusCode} - ${response.body}",
      );
    } on SocketException {
      return UserLogResult.failure(
        "No internet connection",
      );
    } on HttpException catch (e) {
      return UserLogResult.failure(
        "HTTP error: ${e.message}",
      );
    } on FormatException catch (e) {
      return UserLogResult.failure(
        "Invalid response format: $e",
      );
    } catch (e) {
      return UserLogResult.failure(
        "Unexpected error: $e",
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// RESULT WRAPPER
// ─────────────────────────────────────────────────────────────────

class UserLogResult {
  final bool isSuccess;
  final String? message;
  final dynamic data;

  UserLogResult._({
    required this.isSuccess,
    this.message,
    this.data,
  });

  factory UserLogResult.success(dynamic data) =>
      UserLogResult._(
        isSuccess: true,
        data: data,
      );

  factory UserLogResult.failure(String message) =>
      UserLogResult._(
        isSuccess: false,
        message: message,
      );
}

// ─────────────────────────────────────────────────────────────────
// PAYLOAD MODEL
// ─────────────────────────────────────────────────────────────────

class UserLogItemPayload {
  final String id;
  final int lineNum;
  final String cardCode;
  final String itemCode;
  final double qty;
  final double discountPer;
  final String uom;
  final double price;
  final double lineTotal;
  final String reason;
  final String docDate;
  final String paymentMethod;

  UserLogItemPayload({
    required this.id,
    required this.lineNum,
    required this.cardCode,
    required this.itemCode,
    required this.qty,
    required this.discountPer,
    required this.uom,
    required this.price,
    required this.lineTotal,
    required this.reason,
    required this.docDate,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    "ID": id,
    "LineNum": lineNum,
    "CardCode": cardCode,
    "ItemCode": itemCode,
    "Qty": qty,
    "DiscountPer": discountPer,
    "UoM": uom,
    "Price": price,
    "LineTotal": lineTotal,
    "Reason": reason,
    "DocDate": docDate,
    "PaymentMethod": paymentMethod,
  };
}
