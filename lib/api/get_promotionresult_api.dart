import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
// RESPONSE MODEL
// ─────────────────────────────────────────────────────────────

class PromotionResponse {
  final bool success;
  final String message;
  final int? total;
  final List<PromotionResult> data;

  PromotionResponse({
    required this.success,
    required this.message,
    this.total,
    required this.data,
  });

  factory PromotionResponse.fromJson(Map<String, dynamic> json) {
    return PromotionResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      total: json['total'] is int
          ? json['total']
          : int.tryParse(json['total']?.toString() ?? ''),
      data: (json['data'] is List)
          ? (json['data'] as List)
          .map((x) => PromotionResult.fromJson(x))
          .toList()
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ITEM MODEL
// ─────────────────────────────────────────────────────────────

class PromotionResult {
  final int rowID;
  final String promotionType;
  final String uom;
  final String itemCode;
  final String itemName;
  final int lineNum;
  final double unitPrice;
  final String remark;
  final double match;
  final double match1;

  PromotionResult({
    required this.rowID,
    required this.promotionType,
    required this.uom,
    required this.itemCode,
    required this.itemName,
    required this.lineNum,
    required this.unitPrice,
    required this.remark,
    required this.match,
    required this.match1,
  });

  factory PromotionResult.fromJson(Map<String, dynamic> json) {
    return PromotionResult(
      rowID: json['RowID'] ?? 0,
      promotionType: json['PromotionType'] ?? '',
      uom: json['UOM'] ?? '',
      itemCode: json['ItemCode'] ?? '',
      itemName: json['ItemName'] ?? '',
      lineNum: json['LineNum'] ?? 0,
      unitPrice: (json['UnitPrice'] as num?)?.toDouble() ?? 0.0,
      remark: json['Remark'] ?? '',
      match: (json['Match'] as num?)?.toDouble() ?? 0.0,
      match1: (json['Match1'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────

class PromotionService {
  static const String baseUrl =
      'https://www.icckh.com/dms/dev/lhc/api/Marketing/GetPromotionResult';

  static Future<PromotionResponse> getPromotionResult(
      String promotionId) async {
    try {
      final Uri url = Uri.parse(baseUrl).replace(
        queryParameters: {
          "Promotionid": promotionId,
        },
      );

      debugPrint('📡 POST URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'API Error ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);
      return PromotionResponse.fromJson(decoded);
    } catch (e) {
      throw Exception('Promotion API failed: $e');
    }
  }
}