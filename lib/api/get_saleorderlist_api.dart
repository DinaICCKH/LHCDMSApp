
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_api.dart';

/// =============================================================
/// SALE LISTING RESULT MODEL CLASS
/// =============================================================
class SaleListingResult {
  // HEADER FIELDS (From Table T1: SO)
  final int code;
  final String? message;
  final String? bplId;
  final String? bplName;
  final String? docStatus;
  final DateTime? docDate;
  final String? uDeliveryTime;
  final String? uPaymentMethod;
  final String? uOwner;
  final String? cardCode;
  final String? cardName;
  final String? address;
  final String? numAtCard;
  final double subTotal;
  final double discPrcnt;
  final double discSum;
  final double docTotal;
  final String? comments;
  final String? userSign;
  final String? salesCode;
  final String? apiStatus;
  final String? apiErrMessage;
  final String? sapDocEntry;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? checkOutLateLong;
  final String? checkOutRemark;
  final String? sapSyncStatus;
  final String? appStatus;
  final String? dataSource;

  // LINE FIELDS (From Table T2: SO1)
  final int? lineNum;
  final String? itemCode;
  final String? dscription;
  final double? quantity;
  final String uomCode;
  final double? price;
  final double? discountAmt;
  final double? lineTotal;
  final String? whsCode;
  final String? ocrCode;
  final String? ocrCode2;
  final String? ocrCode3;
  final String? ocrCode4;

  SaleListingResult({
    required this.code,
    this.message,
    this.bplId,
    this.bplName,
    this.docStatus,
    this.docDate,
    this.uDeliveryTime,
    this.uPaymentMethod,
    this.uOwner,
    this.cardCode,
    this.cardName,
    this.address,
    this.numAtCard,
    required this.subTotal,
    required this.discPrcnt,
    required this.discSum,
    required this.docTotal,
    this.comments,
    this.userSign,
    this.salesCode,
    this.apiStatus,
    this.apiErrMessage,
    this.sapDocEntry,
    this.checkInDate,
    this.checkOutDate,
    this.checkOutLateLong,
    this.checkOutRemark,
    this.sapSyncStatus,
    this.appStatus,
    this.dataSource,
    this.lineNum,
    this.itemCode,
    this.dscription,
    this.quantity,
    required this.uomCode,
    this.price,
    this.discountAmt,
    this.lineTotal,
    this.whsCode,
    this.ocrCode,
    this.ocrCode2,
    this.ocrCode3,
    this.ocrCode4,
  });

  factory SaleListingResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      return (value as num).toDouble();
    }

    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      return (value as num).toDouble();
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      return (value as num).toInt();
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      return (value as num).toInt();
    }

    String? toNullableStr(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    String toStr(dynamic value) {
      return value?.toString() ?? '';
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return SaleListingResult(
      // Header Fields
      code: toInt(json['Code']),
      message: toNullableStr(json['Message']),
      bplId: toNullableStr(json['BPLId']),
      bplName: toNullableStr(json['BPLName']),
      docStatus: toNullableStr(json['DocStatus']),
      docDate: parseDate(json['DocDate']),
      uDeliveryTime: toNullableStr(json['U_DeliveryTime']),
      uPaymentMethod: toNullableStr(json['U_PaymentMethod']),
      uOwner: toNullableStr(json['U_Owner']),
      cardCode: toNullableStr(json['CardCode']),
      cardName: toNullableStr(json['CardName']),
      address: toNullableStr(json['Address']),
      numAtCard: toNullableStr(json['NumAtCard']),
      subTotal: toDouble(json['SubTotal']),
      discPrcnt: toDouble(json['DiscPrcnt']),
      discSum: toDouble(json['DiscSum']),
      docTotal: toDouble(json['DocTotal']),
      comments: toNullableStr(json['Comments']),
      userSign: toNullableStr(json['UserSign']),
      salesCode: toNullableStr(json['SalesCode']),
      apiStatus: toNullableStr(json['APIStatus']),
      apiErrMessage: toNullableStr(json['APIErrMessage']),
      sapDocEntry: toNullableStr(json['SAPDocEntry']),
      checkInDate: parseDate(json['CheckInDate']),
      checkOutDate: parseDate(json['CheckOutDate']),
      checkOutLateLong: toNullableStr(json['CheckOutLateLong']),
      checkOutRemark: toNullableStr(json['CheckOutRemark']),
      sapSyncStatus: toNullableStr(json['SAPSyncStatus']),
      appStatus: toNullableStr(json['AppStatus']),
      dataSource: toNullableStr(json['DataSource']),

      // Line Fields
      lineNum: toNullableInt(json['LineNum']),
      itemCode: toNullableStr(json['ItemCode']),
      dscription: toNullableStr(json['Dscription']),
      quantity: toNullableDouble(json['Quantity']),
      uomCode: toStr(json['UomCode']), // Required in your class rules
      price: toNullableDouble(json['Price']),
      discountAmt: toNullableDouble(json['DiscountAmt']),
      lineTotal: toNullableDouble(json['LineTotal']),
      whsCode: toNullableStr(json['WhsCode']),
      ocrCode: toNullableStr(json['OcrCode']),
      ocrCode2: toNullableStr(json['OcrCode2']),
      ocrCode3: toNullableStr(json['OcrCode3']),
      ocrCode4: toNullableStr(json['OcrCode4']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'Message': message,
      'BPLId': bplId,
      'BPLName': bplName,
      'DocStatus': docStatus,
      'DocDate': docDate?.toIso8601String(),
      'U_DeliveryTime': uDeliveryTime,
      'U_PaymentMethod': uPaymentMethod,
      'U_Owner': uOwner,
      'CardCode': cardCode,
      'CardName': cardName,
      'Address': address,
      'NumAtCard': numAtCard,
      'SubTotal': subTotal,
      'DiscPrcnt': discPrcnt,
      'DiscSum': discSum,
      'DocTotal': docTotal,
      'Comments': comments,
      'UserSign': userSign,
      'SalesCode': salesCode,
      'APIStatus': apiStatus,
      'APIErrMessage': apiErrMessage,
      'SAPDocEntry': sapDocEntry,
      'CheckInDate': checkInDate?.toIso8601String(),
      'CheckOutDate': checkOutDate?.toIso8601String(),
      'CheckOutLateLong': checkOutLateLong,
      'CheckOutRemark': checkOutRemark,
      'SAPSyncStatus': sapSyncStatus,
      'AppStatus': appStatus,
      'DataSource': dataSource,
      'LineNum': lineNum,
      'ItemCode': itemCode,
      'Dscription': dscription,
      'Quantity': quantity,
      'UomCode': uomCode,
      'Price': price,
      'DiscountAmt': discountAmt,
      'LineTotal': lineTotal,
      'WhsCode': whsCode,
      'OcrCode': ocrCode,
      'OcrCode2': ocrCode2,
      'OcrCode3': ocrCode3,
      'OcrCode4': ocrCode4,
    };
  }
}

/// =============================================================
/// SALE LISTING API SERVICE
/// =============================================================
class SaleOrderApi {
  static const String baseUrl = "https://www.icckh.com/dms/dev/lhc/api/Marketing/";

  /// Fetches the live list of sales orders directly from the endpoint.
  static Future<List<SaleListingResult>> fetchSaleOrders({
    required String passwordHash,
    required String fromDate,
    required String toDate,
    required String status,
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found. Please login first.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetSaleOrderListing");
    final body = jsonEncode({
      "UserCode": user.userCode,
      "PasswordHash": passwordHash,
      "DeviceID": user.deviceID,
      "FromDate": fromDate,
      "ToDate": toDate,
      "Status": status,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("📡 [Network Response Status]: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<dynamic> rawList = result['data'];
          print("📥 [Data Loaded]: Successfully received ${rawList.length} rows from API.");

          return rawList.map((e) => SaleListingResult.fromJson(e)).toList();
        } else {
          print("⚠️ [API Warning]: Success is false or data format mismatch. Body: ${response.body}");
        }
      } else {
        print("❌ [Server Error]: HTTP status code ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("❌ Error fetching sale orders: $e");
      return [];
    }
  }
}

