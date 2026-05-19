import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────

class SaleOrderApi {
  static const String _baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/Marketing/AddOrUpdateSO";

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
        return SaleOrderResult.success(jsonDecode(response.body));
      }

      return SaleOrderResult.failure(
        "Server error: ${response.statusCode} — ${response.body}",
      );
    } on SocketException {
      return SaleOrderResult.failure("No internet connection.");
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
// HELPER (REMOVE EMPTY VALUES AUTOMATICALLY)
// ─────────────────────────────────────────────────────────────────

class JsonBuilder {
  final Map<String, dynamic> _map = {};

  void req(String key, dynamic value) {
    _map[key] = value;
  }

  void opt(String key, dynamic value) {
    if (value == null) return;

    if (value is String && value.trim().isEmpty) return;

    if (value is num && value == 0) return;

    _map[key] = value;
  }

  Map<String, dynamic> build() => _map;
}

// ─────────────────────────────────────────────────────────────────
// PAYLOAD
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
    this.docStatus = "Draft",
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
    this.apiErrMessage = "Pending",
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
    this.sapLastError = "Pending",
    this.nextApprover = "",
    this.appStatus = "D",
    this.dataSource = "App",
    required this.so1Lines,
  });

  Map<String, dynamic> toJson() {
    final j = JsonBuilder();

    j.req("Mode", mode);
    j.req("DocEntry", docEntry);
    j.req("BPLId", bplId);
    j.req("BPLName", bplName);

    j.req("CANCELED", canceled);
    j.req("DocStatus", docStatus);

    j.req("DocDate", docDate);
    j.req("DocDueDate", docDueDate);
    j.req("U_DeliveryTime", uDeliveryTime);

    j.req("CardCode", cardCode);
    j.req("CardName", cardName);
    j.req("Address", address);

    j.opt("NumAtCard", numAtCard);

    j.req("VatSum", vatSum);
    j.req("DiscPrcnt", discPrcnt);
    j.req("DiscSum", discSum);
    j.req("SubTotal", subTotal);
    j.req("DocTotal", docTotal);

    j.opt("PaidToDate", paidToDate);

    j.opt("Ref1", ref1);
    j.req("Ref2", ref2);
    j.req("Comments", comments);

    j.req("U_PaymentMethod", uPaymentMethod);
    j.req("U_Owner", uOwner);
    j.req("CreateDate", createDate);

    j.req("UserSign", userSign);
    j.opt("UserSign2", userSign2);
    j.opt("SalesCode", salesCode);

    j.req("APIStatus", apiStatus);
    j.req("APIErrMessage", apiErrMessage);

    j.opt("SAPDocEntry", sapDocEntry);
    j.opt("SAPDocNum", sapDocNum);

    j.req("CheckInDate", checkInDate);
    j.opt("CheckInLateLong", checkInLateLong);
    j.opt("CheckInRemark", checkInRemark);

    j.opt("CheckOutLateLong", checkOutLateLong);
    j.req("CheckOutDate", checkOutDate);
    j.opt("CheckOutRemark", checkOutRemark);

    j.opt("ImageURL", imageUrl);

    j.req("SAPSyncStatus", sapSyncStatus);
    j.req("SAPLastError", sapLastError);

    j.opt("NextApprover", nextApprover);
    j.req("AppStatus", appStatus);
    j.req("DataSource", dataSource);

    j.req("SO1Lines", so1Lines.map((e) => e.toJson()).toList());

    return j.build();
  }
}

// ─────────────────────────────────────────────────────────────────
// SALE ORDER LINE
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
  final double lineTotal;

  final String taxCode;
  final String whsCode;

  final String ocrCode;
  final String? ocrCode2;
  final String? ocrCode3;
  final String? ocrCode4;

  final double uInvPaymentAmt;
  final double uPaymentPer;
  final double uPaymentAmt;

  final double uInvDiscountPer;
  final double uInvDicountAmt;
  final double uDiscPer;
  final double uDiscAmt;

  final double uInvVoucherAmt;
  final String uVoucher;
  final String uVoucherNo;

  final double uInvTransportAmt;
  final double uTransportationPercent;
  final double uTransportationAmt;

  final double uInvSpecialAmt;
  final double uSpecialPricePercent;
  final double uSpecialPriceAmt;

  final double uPolicyDisc;
  final double uInvTransportPer;
  final double uInvSpecialPer;
  final double uInvSpecialFreeAmt;
  final double uInvPaymentPer;

  final String uAddOnStatus;
  final double uInvTransprtFAmt;

  final String uInvCurrency;
  final double uMnCurrency;
  final String uRemarkCurrency;

  final String uInvFactory;
  final double uMnFactory;
  final String uRemarkFactory;

  final double uInvTransportB7;
  final double uMnTransportB7;
  final String uRemarkTransportB7;

  final double uInvTransportB8;
  final double uMnTransportB8;
  final String uRemarkTransportB8;

  final double uInvEmployeeCom;
  final double uMnEmployeeCom;
  final String uRemarkEmployeeCom;

  final double uInvDepotCom;
  final double uMnDepotCom;
  final String uRemarkDepotCom;

  final double uInvQuarterCom;
  final double uMnQuarterCom;
  final String uRemarkQuarterCom;

  final double uInvMarketing;
  final double uMnMarketing;
  final String uRemarkMarketing;

  final double uInOther9;
  final double uMnOther9;
  final String uRemarkOther9;

  final double uInOther10;
  final double uMnOther10;
  final String uRemarkOther10;

  final double uInOther11;
  final double uMnOther11;
  final String uRemarkOther11;

  final double uInOther12;
  final double uMnOther12;
  final String uRemarkOther12;

  final double uSpecialTrAmt;
  final double uSpecialTrnPer;
  final double uQtyFactory;

  SaleOrderLine({
    required this.docEntry,
    required this.lineNum,
    required this.itemCode,
    required this.dscription,
    required this.quantity,
    required this.uomCode,
    this.unitMsr = "",
    required this.price,
    this.discPrcnt = 0,
    this.disAmt = 0,
    required this.lineTotal,
    this.taxCode = "",
    this.whsCode = "WH001",
    this.ocrCode = "",
    this.ocrCode2,
    this.ocrCode3,
    this.ocrCode4,
    this.uInvPaymentAmt = 0,
    this.uPaymentPer = 0,
    this.uPaymentAmt = 0,
    this.uInvDiscountPer = 0,
    this.uInvDicountAmt = 0,
    this.uDiscPer = 0,
    this.uDiscAmt = 0,
    this.uInvVoucherAmt = 0,
    this.uVoucher = "",
    this.uVoucherNo = "",
    this.uInvTransportAmt = 0,
    this.uTransportationPercent = 0,
    this.uTransportationAmt = 0,
    this.uInvSpecialAmt = 0,
    this.uSpecialPricePercent = 0,
    this.uSpecialPriceAmt = 0,
    this.uPolicyDisc = 0,
    this.uInvTransportPer = 0,
    this.uInvSpecialPer = 0,
    this.uInvSpecialFreeAmt = 0,
    this.uInvPaymentPer = 0,
    this.uAddOnStatus = "",
    this.uInvTransprtFAmt = 0,
    this.uInvCurrency = "USD",
    this.uMnCurrency = 0,
    this.uRemarkCurrency = "",
    this.uInvFactory = "",
    this.uMnFactory = 0,
    this.uRemarkFactory = "",
    this.uInvTransportB7 = 0,
    this.uMnTransportB7 = 0,
    this.uRemarkTransportB7 = "",
    this.uInvTransportB8 = 0,
    this.uMnTransportB8 = 0,
    this.uRemarkTransportB8 = "",
    this.uInvEmployeeCom = 0,
    this.uMnEmployeeCom = 0,
    this.uRemarkEmployeeCom = "",
    this.uInvDepotCom = 0,
    this.uMnDepotCom = 0,
    this.uRemarkDepotCom = "",
    this.uInvQuarterCom = 0,
    this.uMnQuarterCom = 0,
    this.uRemarkQuarterCom = "",
    this.uInvMarketing = 0,
    this.uMnMarketing = 0,
    this.uRemarkMarketing = "",
    this.uInOther9 = 0,
    this.uMnOther9 = 0,
    this.uRemarkOther9 = "",
    this.uInOther10 = 0,
    this.uMnOther10 = 0,
    this.uRemarkOther10 = "",
    this.uInOther11 = 0,
    this.uMnOther11 = 0,
    this.uRemarkOther11 = "",
    this.uInOther12 = 0,
    this.uMnOther12 = 0,
    this.uRemarkOther12 = "",
    this.uSpecialTrAmt = 0,
    this.uSpecialTrnPer = 0,
    this.uQtyFactory = 0,
  });

  Map<String, dynamic> toJson() {
    final j = JsonBuilder();

    j.req("DocEntry", docEntry);
    j.req("LineNum", lineNum);
    j.req("ItemCode", itemCode);
    j.req("Dscription", dscription);
    j.req("Quantity", quantity);
    j.req("UomCode", uomCode);
    j.req("UnitMsr", unitMsr);
    j.req("Price", price);
    j.req("DiscPrcnt", discPrcnt);
    j.req("DisAmt", disAmt);
    j.req("LineTotal", lineTotal);
    j.req("TaxCode", taxCode);
    j.req("WhsCode", whsCode);

    j.opt("OcrCode", ocrCode);
    j.opt("OcrCode2", ocrCode2);
    j.opt("OcrCode3", ocrCode3);
    j.opt("OcrCode4", ocrCode4);

    j.opt("U_InvPaymentAmt", uInvPaymentAmt);
    j.opt("U_PaymentPer", uPaymentPer);
    j.opt("U_PaymentAmt", uPaymentAmt);

    j.opt("U_InvDiscountPer", uInvDiscountPer);
    j.opt("U_InvDicountAmt", uInvDicountAmt);
    j.opt("U_DiscPer", uDiscPer);
    j.opt("U_DiscAmt", uDiscAmt);

    j.opt("U_InvVoucherAmt", uInvVoucherAmt);
    j.opt("U_Voucher", uVoucher);
    j.opt("U_VoucherNo", uVoucherNo);

    j.opt("U_InvTransportAmt", uInvTransportAmt);
    j.opt("U_TransportationPercent", uTransportationPercent);
    j.opt("U_TransportationAmt", uTransportationAmt);

    j.opt("U_InvSpecialAmt", uInvSpecialAmt);
    j.opt("U_specialPricePercent", uSpecialPricePercent);
    j.opt("U_specialPriceAmt", uSpecialPriceAmt);

    j.opt("U_PolicyDisc", uPolicyDisc);
    j.opt("U_InvTransportPer", uInvTransportPer);
    j.opt("U_InvSpecialPer", uInvSpecialPer);
    j.opt("U_InvSpecialFreeAmt", uInvSpecialFreeAmt);
    j.opt("U_InvPaymentPer", uInvPaymentPer);
    j.opt("U_AddOnStatus", uAddOnStatus);
    j.opt("U_InvTransprtFAmt", uInvTransprtFAmt);

    j.opt("U_InvCurrency", uInvCurrency);
    j.opt("U_MnCurrency", uMnCurrency);
    j.opt("U_RemarkCurrency", uRemarkCurrency);

    j.opt("U_InOther9", uInOther9);
    j.opt("U_MnOther9", uMnOther9);
    j.opt("U_RemarkOther9", uRemarkOther9);

    j.opt("U_InOther10", uInOther10);
    j.opt("U_MnOther10", uMnOther10);
    j.opt("U_RemarkOther10", uRemarkOther10);

    j.opt("U_InOther11", uInOther11);
    j.opt("U_MnOther11", uMnOther11);
    j.opt("U_RemarkOther11", uRemarkOther11);

    j.opt("U_InOther12", uInOther12);
    j.opt("U_MnOther12", uMnOther12);
    j.opt("U_RemarkOther12", uRemarkOther12);

    j.opt("U_SpecialTrAmt", uSpecialTrAmt);
    j.opt("U_SpecialTrnPer", uSpecialTrnPer);
    j.opt("U_QtyFactory", uQtyFactory);

    return j.build();
  }
}