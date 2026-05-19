class Customer {
  String code;
  String name;
  String phone;
  String address;

  Customer({
    required this.code,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class SaleItem {
  // ───────────────── BASIC ITEM ─────────────────
  String itemCode;
  String name;
  double qty;
  double price;
  double lineTotal;
  String uom;

  // ───────────────── WAREHOUSE ─────────────────
  String whsCode;

  // ───────────────── COST CENTER ─────────────────
  String ocrCode;
  String ocrCode2;
  String ocrCode3;
  String ocrCode4;

  // ───────────────── ITEM INFO ─────────────────
  String? itemGroupName;
  String? subGroupDes;
  String? subGroup2Des;
  String? manufacturerDes;

  // ───────────────── NORMAL DISCOUNT ─────────────────
  double discPrcnt;
  double disAmt;

  double uDiscPer;
  double uDiscAmt;

  // ───────────────── PROMO DISCOUNT ─────────────────
  double uInvDiscountPer;
  double uInvDicountAmt;

  // ───────────────── OTHER 9 ─────────────────
  double uInOther9;
  double uMnOther9;
  String uRemarkOther9;

  // ───────────────── OTHER 10 ─────────────────
  double uInOther10;
  double uMnOther10;
  String uRemarkOther10;

  // ───────────────── OTHER 11 ─────────────────
  double uInOther11;
  double uMnOther11;
  String uRemarkOther11;

  // ───────────────── OTHER 12 ─────────────────
  double uInOther12;
  double uMnOther12;
  String uRemarkOther12;

  // ───────────────── PAYMENT ─────────────────
  double uInvPaymentAmt;
  double uPaymentPer;
  double uPaymentAmt;
  double uInvPaymentPer;

  // ───────────────── VOUCHER ─────────────────
  double uInvVoucherAmt;
  String uVoucher;
  String uVoucherNo;

  // ───────────────── TRANSPORT ─────────────────
  double uInvTransportAmt;
  double uTransportationPercent;
  double uTransportationAmt;

  // ───────────────── SPECIAL PRICE ─────────────────
  double uInvSpecialAmt;
  double uSpecialPricePercent;
  double uSpecialPriceAmt;

  // ───────────────── POLICY ─────────────────
  double uPolicyDisc;
  double uInvTransportPer;
  double uInvSpecialPer;
  double uInvSpecialFreeAmt;

  // ───────────────── EXTRA ─────────────────
  String uAddOnStatus;
  double uInvTransprtFAmt;

  // ───────────────── CURRENCY ─────────────────
  String uInvCurrency;
  double uMnCurrency;
  String uRemarkCurrency;

  // ───────────────── FACTORY ─────────────────
  String uInvFactory;
  double uMnFactory;
  String uRemarkFactory;

  // ───────────────── TRANSPORT B7 ─────────────────
  double uInvTransportB7;
  double uMnTransportB7;
  String uRemarkTransportB7;

  // ───────────────── TRANSPORT B8 ─────────────────
  double uInvTransportB8;
  double uMnTransportB8;
  String uRemarkTransportB8;

  // ───────────────── EMPLOYEE COM ─────────────────
  double uInvEmployeeCom;
  double uMnEmployeeCom;
  String uRemarkEmployeeCom;

  // ───────────────── DEPOT COM ─────────────────
  double uInvDepotCom;
  double uMnDepotCom;
  String uRemarkDepotCom;

  // ───────────────── QUARTER COM ─────────────────
  double uInvQuarterCom;
  double uMnQuarterCom;
  String uRemarkQuarterCom;

  // ───────────────── MARKETING ─────────────────
  double uInvMarketing;
  double uMnMarketing;
  String uRemarkMarketing;

  // ───────────────── SPECIAL TRANSPORT ─────────────────
  double uSpecialTrAmt;
  double uSpecialTrnPer;

  double uQtyFactory;

  SaleItem({
    required this.itemCode,
    required this.name,
    this.qty = 1,
    required this.price,
    this.lineTotal = 0,
    this.uom = "PCS",

    this.whsCode = "WH001",

    this.ocrCode = "",
    this.ocrCode2 = "",
    this.ocrCode3 = "",
    this.ocrCode4 = "",

    this.itemGroupName,
    this.subGroupDes,
    this.subGroup2Des,
    this.manufacturerDes,

    this.discPrcnt = 0,
    this.disAmt = 0,
    this.uDiscPer = 0,
    this.uDiscAmt = 0,

    this.uInvDiscountPer = 0,
    this.uInvDicountAmt = 0,

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

    this.uInvPaymentAmt = 0,
    this.uPaymentPer = 0,
    this.uPaymentAmt = 0,
    this.uInvPaymentPer = 0,

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

    this.uSpecialTrAmt = 0,
    this.uSpecialTrnPer = 0,

    this.uQtyFactory = 0,
  });

  // ───────────────── CALCULATIONS ─────────────────

  double get subTotal => qty * price;

  double get totalDiscount =>
      disAmt +
          uInvDicountAmt +
          uMnOther9 +
          uMnOther10 +
          uMnOther11 +
          uMnOther12;

  double get total => subTotal - totalDiscount;

  double get computedLineTotal => total;

  // ───────────────── COPY WITH ─────────────────

  SaleItem copyWith({
    double? qty,
    double? price,
    double? lineTotal,

    double? discPrcnt,
    double? disAmt,

    double? uDiscPer,
    double? uDiscAmt,

    double? uInvDiscountPer,
    double? uInvDicountAmt,

    double? uInOther9,
    double? uMnOther9,
    String? uRemarkOther9,

    double? uInOther10,
    double? uMnOther10,
    String? uRemarkOther10,

    double? uInOther11,
    double? uMnOther11,
    String? uRemarkOther11,

    double? uInOther12,
    double? uMnOther12,
    String? uRemarkOther12,

    double? uInvVoucherAmt,
    String? uVoucher,
    String? uVoucherNo,

    double? uInvTransportAmt,
    double? uTransportationPercent,
    double? uTransportationAmt,

    double? uInvSpecialAmt,
    double? uSpecialPricePercent,
    double? uSpecialPriceAmt,

    double? uPolicyDisc,
    double? uInvTransportPer,
    double? uInvSpecialPer,
    double? uInvSpecialFreeAmt,

    double? uInvPaymentAmt,
    double? uPaymentPer,
    double? uPaymentAmt,
    double? uInvPaymentPer,

    String? uAddOnStatus,
    double? uInvTransprtFAmt,

    String? uInvCurrency,
    double? uMnCurrency,
    String? uRemarkCurrency,

    String? uInvFactory,
    double? uMnFactory,
    String? uRemarkFactory,

    double? uInvTransportB7,
    double? uMnTransportB7,
    String? uRemarkTransportB7,

    double? uInvTransportB8,
    double? uMnTransportB8,
    String? uRemarkTransportB8,

    double? uInvEmployeeCom,
    double? uMnEmployeeCom,
    String? uRemarkEmployeeCom,

    double? uInvDepotCom,
    double? uMnDepotCom,
    String? uRemarkDepotCom,

    double? uInvQuarterCom,
    double? uMnQuarterCom,
    String? uRemarkQuarterCom,

    double? uInvMarketing,
    double? uMnMarketing,
    String? uRemarkMarketing,

    double? uSpecialTrAmt,
    double? uSpecialTrnPer,

    double? uQtyFactory,
  }) {
    return SaleItem(
      itemCode: itemCode,
      name: name,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      lineTotal: lineTotal ?? this.lineTotal,
      uom: uom,
      whsCode: whsCode,
      ocrCode: ocrCode,
      ocrCode2: ocrCode2,
      ocrCode3: ocrCode3,
      ocrCode4: ocrCode4,

      itemGroupName: itemGroupName,
      subGroupDes: subGroupDes,
      subGroup2Des: subGroup2Des,
      manufacturerDes: manufacturerDes,

      discPrcnt: discPrcnt ?? this.discPrcnt,
      disAmt: disAmt ?? this.disAmt,

      uDiscPer: uDiscPer ?? this.uDiscPer,
      uDiscAmt: uDiscAmt ?? this.uDiscAmt,

      uInvDiscountPer: uInvDiscountPer ?? this.uInvDiscountPer,
      uInvDicountAmt: uInvDicountAmt ?? this.uInvDicountAmt,

      uInOther9: uInOther9 ?? this.uInOther9,
      uMnOther9: uMnOther9 ?? this.uMnOther9,
      uRemarkOther9: uRemarkOther9 ?? this.uRemarkOther9,

      uInOther10: uInOther10 ?? this.uInOther10,
      uMnOther10: uMnOther10 ?? this.uMnOther10,
      uRemarkOther10: uRemarkOther10 ?? this.uRemarkOther10,

      uInOther11: uInOther11 ?? this.uInOther11,
      uMnOther11: uMnOther11 ?? this.uMnOther11,
      uRemarkOther11: uRemarkOther11 ?? this.uRemarkOther11,

      uInOther12: uInOther12 ?? this.uInOther12,
      uMnOther12: uMnOther12 ?? this.uMnOther12,
      uRemarkOther12: uRemarkOther12 ?? this.uRemarkOther12,

      uInvPaymentAmt: uInvPaymentAmt ?? this.uInvPaymentAmt,
      uPaymentPer: uPaymentPer ?? this.uPaymentPer,
      uPaymentAmt: uPaymentAmt ?? this.uPaymentAmt,
      uInvPaymentPer: uInvPaymentPer ?? this.uInvPaymentPer,

      uInvVoucherAmt: uInvVoucherAmt ?? this.uInvVoucherAmt,
      uVoucher: uVoucher ?? this.uVoucher,
      uVoucherNo: uVoucherNo ?? this.uVoucherNo,

      uInvTransportAmt: uInvTransportAmt ?? this.uInvTransportAmt,
      uTransportationPercent: uTransportationPercent ?? this.uTransportationPercent,
      uTransportationAmt: uTransportationAmt ?? this.uTransportationAmt,

      uInvSpecialAmt: uInvSpecialAmt ?? this.uInvSpecialAmt,
      uSpecialPricePercent: uSpecialPricePercent ?? this.uSpecialPricePercent,
      uSpecialPriceAmt: uSpecialPriceAmt ?? this.uSpecialPriceAmt,

      uPolicyDisc: uPolicyDisc ?? this.uPolicyDisc,
      uInvTransportPer: uInvTransportPer ?? this.uInvTransportPer,
      uInvSpecialPer: uInvSpecialPer ?? this.uInvSpecialPer,
      uInvSpecialFreeAmt: uInvSpecialFreeAmt ?? this.uInvSpecialFreeAmt,

      uAddOnStatus: uAddOnStatus ?? this.uAddOnStatus,
      uInvTransprtFAmt: uInvTransprtFAmt ?? this.uInvTransprtFAmt,

      uInvCurrency: uInvCurrency ?? this.uInvCurrency,
      uMnCurrency: uMnCurrency ?? this.uMnCurrency,
      uRemarkCurrency: uRemarkCurrency ?? this.uRemarkCurrency,

      uInvFactory: uInvFactory ?? this.uInvFactory,
      uMnFactory: uMnFactory ?? this.uMnFactory,
      uRemarkFactory: uRemarkFactory ?? this.uRemarkFactory,

      uInvTransportB7: uInvTransportB7 ?? this.uInvTransportB7,
      uMnTransportB7: uMnTransportB7 ?? this.uMnTransportB7,
      uRemarkTransportB7: uRemarkTransportB7 ?? this.uRemarkTransportB7,

      uInvTransportB8: uInvTransportB8 ?? this.uInvTransportB8,
      uMnTransportB8: uMnTransportB8 ?? this.uMnTransportB8,
      uRemarkTransportB8: uRemarkTransportB8 ?? this.uRemarkTransportB8,

      uInvEmployeeCom: uInvEmployeeCom ?? this.uInvEmployeeCom,
      uMnEmployeeCom: uMnEmployeeCom ?? this.uMnEmployeeCom,
      uRemarkEmployeeCom: uRemarkEmployeeCom ?? this.uRemarkEmployeeCom,

      uInvDepotCom: uInvDepotCom ?? this.uInvDepotCom,
      uMnDepotCom: uMnDepotCom ?? this.uMnDepotCom,
      uRemarkDepotCom: uRemarkDepotCom ?? this.uRemarkDepotCom,

      uInvQuarterCom: uInvQuarterCom ?? this.uInvQuarterCom,
      uMnQuarterCom: uMnQuarterCom ?? this.uMnQuarterCom,
      uRemarkQuarterCom: uRemarkQuarterCom ?? this.uRemarkQuarterCom,

      uInvMarketing: uInvMarketing ?? this.uInvMarketing,
      uMnMarketing: uMnMarketing ?? this.uMnMarketing,
      uRemarkMarketing: uRemarkMarketing ?? this.uRemarkMarketing,

      uSpecialTrAmt: uSpecialTrAmt ?? this.uSpecialTrAmt,
      uSpecialTrnPer: uSpecialTrnPer ?? this.uSpecialTrnPer,

      uQtyFactory: uQtyFactory ?? this.uQtyFactory,
    );
  }
}