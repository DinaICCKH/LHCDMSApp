import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
// SALE ORDER API SERVICE
// Endpoint: POST https://www.icckh.com/dms/dev/lhc/api/Marketing/AddOrUpdateSO
// ─────────────────────────────────────────────────────────────────

class SaleOrderApi {
  static const String _baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/Marketing/AddOrUpdateSO";

  // ── Main method to submit a Sale Order ──────────────────────────
  static Future<SaleOrderResult> submitOrder({
    required SaleOrderPayload payload,
  }) async {
    try {
      final body = jsonEncode(payload.toJson());

      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return SaleOrderResult.success(decoded);
      } else {
        return SaleOrderResult.failure(
          "Server error: ${response.statusCode} — ${response.body}",
        );
      }
    } on SocketException {
      return SaleOrderResult.failure(
        "No internet connection. Order saved locally.",
      );
    } on HttpException catch (e) {
      return SaleOrderResult.failure("HTTP error: $e");
    } on FormatException catch (e) {
      return SaleOrderResult.failure("Response format error: $e");
    } catch (e) {
      return SaleOrderResult.failure("Unexpected error: $e");
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// RESULT WRAPPER
// ─────────────────────────────────────────────────────────────────
class SaleOrderResult {
  final bool isSuccess;
  final String? message;
  final dynamic data;

  SaleOrderResult._({
    required this.isSuccess,
    this.message,
    this.data,
  });

  factory SaleOrderResult.success(dynamic data) =>
      SaleOrderResult._(isSuccess: true, data: data);

  factory SaleOrderResult.failure(String message) =>
      SaleOrderResult._(isSuccess: false, message: message);
}

// ─────────────────────────────────────────────────────────────────
// PAYLOAD MODEL
// ─────────────────────────────────────────────────────────────────
class SaleOrderPayload {
  final String mode;
  final int docEntry;
  final int bplId;
  final String bplName;
  final String canceled;
  final String docStatus;
  final String docDate;
  final String docDueDate;
  final String uDeliveryTime;
  final String cardCode;
  final String cardName;
  final String address;
  final String numAtCard;
  final double vatSum;
  final double discPrcnt;
  final double discSum;
  final double subTotal;
  final double docTotal;
  final double paidToDate;
  final String ref1;
  final String ref2;
  final String comments;
  final String uPaymentMethod;
  final String uOwner;
  final String createDate;
  final String userSign;
  final String userSign2;
  final String salesCode;
  final String apiStatus;
  final String apiErrMessage;
  final String sapDocEntry;
  final String sapDocNum;
  final String checkInDate;
  final double checkInLateLong;
  final String checkInRemark;
  final double checkOutLateLong;
  final String checkOutDate;
  final String checkOutRemark;
  final String imageUrl;
  final String sapSyncStatus;
  final String sapLastError;
  final String nextApprover;
  final String appStatus;
  final String dataSource;
  final List<SaleOrderLine> so1Lines;

  SaleOrderPayload({
    this.mode = "Add",
    this.docEntry = 0,
    this.bplId = 1,
    this.bplName = "LY HONG CHHOY TRADING CO., LTD",
    this.canceled = "N",
    this.docStatus = "O",
    required this.docDate,
    required this.docDueDate,
    required this.uDeliveryTime,
    required this.cardCode,
    required this.cardName,
    required this.address,
    this.numAtCard = "",
    this.vatSum = 0,
    required this.discPrcnt,
    required this.discSum,
    required this.subTotal,
    required this.docTotal,
    this.paidToDate = 0,
    this.ref1 = "",
    required this.ref2,
    required this.comments,
    required this.uPaymentMethod,
    required this.uOwner,
    required this.createDate,
    this.userSign = "Admin",
    this.userSign2 = "",
    this.salesCode = "",
    this.apiStatus = "N",
    this.apiErrMessage = "Pending Integrated",
    this.sapDocEntry = "",
    this.sapDocNum = "",
    required this.checkInDate,
    this.checkInLateLong = 0,
    this.checkInRemark = "",
    this.checkOutLateLong = 0,
    required this.checkOutDate,
    this.checkOutRemark = "",
    this.imageUrl = "",
    this.sapSyncStatus = "N",
    this.sapLastError = "Pending Integrated to SAP",
    this.nextApprover = "",
    this.appStatus = "D",
    this.dataSource = "App",
    required this.so1Lines,
  });

  Map<String, dynamic> toJson() => {
    "Mode": mode,
    "DocEntry": docEntry,
    "BPLId": bplId,
    "BPLName": bplName,
    "CANCELED": canceled,
    "DocStatus": docStatus,
    "DocDate": docDate,
    "DocDueDate": docDueDate,
    "U_DeliveryTime": uDeliveryTime,
    "CardCode": cardCode,
    "CardName": cardName,
    "Address": address,
    "NumAtCard": numAtCard,
    "VatSum": vatSum,
    "DiscPrcnt": discPrcnt,
    "DiscSum": discSum,
    "SubTotal": subTotal,
    "DocTotal": docTotal,
    "PaidToDate": paidToDate,
    "Ref1": ref1,
    "Ref2": ref2,
    "Comments": comments,
    "U_PaymentMethod": uPaymentMethod,
    "U_Owner": uOwner,
    "CreateDate": createDate,
    "UserSign": userSign,
    "UserSign2": userSign2,
    "SalesCode": salesCode,
    "APIStatus": apiStatus,
    "APIErrMessage": apiErrMessage,
    "SAPDocEntry": sapDocEntry,
    "SAPDocNum": sapDocNum,
    "CheckInDate": checkInDate,
    "CheckInLateLong": checkInLateLong,
    "CheckInRemark": checkInRemark,
    "CheckOutLateLong": checkOutLateLong,
    "CheckOutDate": checkOutDate,
    "CheckOutRemark": checkOutRemark,
    "ImageURL": imageUrl,
    "SAPSyncStatus": sapSyncStatus,
    "SAPLastError": sapLastError,
    "NextApprover": nextApprover,
    "AppStatus": appStatus,
    "DataSource": dataSource,
    "SO1Lines": so1Lines.map((e) => e.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────
// LINE ITEM MODEL
// ─────────────────────────────────────────────────────────────────
class SaleOrderLine {
  final int docEntry;
  final int lineNum;
  final String itemCode;
  final String dscription;
  final double quantity;
  final String uomCode;
  final String unitMsr;
  final double price;
  final double discPrcnt;
  final double disAmt;
  final String taxCode;
  final double lineTotal;
  final String whsCode;
  final String ocrCode;
  final String uInvCurrency;
  final double uMnCurrency;

  SaleOrderLine({
    this.docEntry = 0,
    required this.lineNum,
    required this.itemCode,
    required this.dscription,
    required this.quantity,
    required this.uomCode,
    this.unitMsr = "",
    required this.price,
    this.discPrcnt = 0,
    this.disAmt = 0,
    this.taxCode = "",
    required this.lineTotal,
    this.whsCode = "WH001",
    this.ocrCode = "",
    this.uInvCurrency = "USD",
    this.uMnCurrency = 0,
  });

  Map<String, dynamic> toJson() => {
    "DocEntry": docEntry,
    "LineNum": lineNum,
    "ItemCode": itemCode,
    "Dscription": dscription,
    "Quantity": quantity,
    "UomCode": uomCode,
    "UnitMsr": unitMsr,
    "Price": price,
    "DiscPrcnt": discPrcnt,
    "DisAmt": disAmt,
    "TaxCode": taxCode,
    "LineTotal": lineTotal,
    "WhsCode": whsCode,
    "OcrCode": ocrCode,
    "OcrCode2": null,
    "OcrCode3": null,
    "OcrCode4": null,
    "U_InvPaymentAmt": 0,
    "U_PaymentPer": 0,
    "U_PaymentAmt": 0,
    "U_InvDiscountPer": 0,
    "U_InvDicountAmt": 0,
    "U_DiscPer": 0,
    "U_DiscAmt": 0,
    "U_InvVoucherAmt": 0,
    "U_Voucher": "",
    "U_VoucherNo": "",
    "U_InvTransportAmt": 0,
    "U_TransportationPercent": 0,
    "U_TransportationAmt": 0,
    "U_InvSpecialAmt": 0,
    "U_specialPricePercent": 0,
    "U_specialPriceAmt": 0,
    "U_PolicyDisc": 0,
    "U_InvTransportPer": 0,
    "U_InvSpecialPer": 0,
    "U_InvSpecialFreeAmt": 0,
    "U_InvPaymentPer": 0,
    "U_AddOnStatus": "",
    "U_InvTransprtFAmt": 0,
    "U_InvCurrency": uInvCurrency,
    "U_MnCurrency": uMnCurrency,
    "U_RemarkCurrency": "",
    "U_InvFactory": "",
    "U_MnFactory": 0,
    "U_RemarkFactory": "",
    "U_InvTransportB7": 0,
    "U_MnTransportB7": 0,
    "U_RemarkTransportB7": "",
    "U_InvTransportB8": 0,
    "U_MnTransportB8": 0,
    "U_RemarkTransportB8": "",
    "U_InvEmployeeCom": 0,
    "U_MnEmployeeCom": 0,
    "U_RemarkEmployeeCom": "",
    "U_InvDepotCom": 0,
    "U_MnDepotCom": 0,
    "U_RemarkDepotCom": "",
    "U_InvQuarterCom": 0,
    "U_MnQuarterCom": 0,
    "U_RemarkQuarterCom": "",
    "U_InvMarketing": 0,
    "U_MnMarketing": 0,
    "U_RemarkMarketing": "",
    "U_InOther9": 0,
    "U_MnOther9": 0,
    "U_RemarkOther9": "",
    "U_InOther10": 0,
    "U_MnOther10": 0,
    "U_RemarkOther10": "",
    "U_InOther11": 0,
    "U_MnOther11": 0,
    "U_RemarkOther11": "",
    "U_InOther12": 0,
    "U_MnOther12": 0,
    "U_RemarkOther12": "",
    "U_SpecialTrAmt": 0,
    "U_SpecialTrnPer": 0,
    "U_QtyFactory": 0,
  };
}
