import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kuberadmsdn/api/login_api.dart';
import 'package:kuberadmsdn/api/sale_order_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuberadmsdn/api/save_itemlogpromotion_api.dart';
import '../api/get_customer_api.dart' as api;
import '../api/get_item_api.dart' as itemApi;
import '../api/get_promotionresult_api.dart';
import 'models/sale_order_model.dart';
import 'package:flutter/material.dart';

class SaleController extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────
  api.Customer? selectedCustomer;
  List<SaleItem> selectedItems = [];

  List<api.Customer> customers = [];
  List<itemApi.Item> items = [];

  bool isLoadingCustomer = true;
  bool isLoadingItem = true;
  bool isSaving = false;
  bool isRunningPromotion = false;
  bool isPromotionLocked = false;

  // ── Discount ──────────────────────────────────────────────────────────────
  double discountPercent = 0.0;
  double discountAmount = 0.0;
  bool _isUpdatingDiscount = false;

  // ── Order Details ─────────────────────────────────────────────────────────
  String ownerValue = "Admin";
  String paymentMethodValue = "Invoice";
  TimeOfDay? deliveryTime;

  // ── Computed ──────────────────────────────────────────────────────────────
  double get subTotal => selectedItems.fold(0.0, (sum, i) {
    // Works for both: uses net promotional total if available, otherwise calculates standard gross.
    final double finalLineVal = (i.lineTotal != null && i.lineTotal! > 0)
        ? i.lineTotal!
        : ((i.qty ?? 0) * (i.price ?? 0)).toDouble();
    return sum + finalLineVal;
  });

  double get docTotal {
    final total = subTotal - discountAmount;
    return total < 0 ? 0.0 : total; // Prevent negative values
  }

  // ─────────────────────────────────────────────
  // DATA LOADERS
  // ─────────────────────────────────────────────
  Future<void> loadCustomers() async {
    isLoadingCustomer = true;
    notifyListeners();

    customers = await api.CustomerApi.getLocalCustomers();

    isLoadingCustomer = false;
    notifyListeners();
  }

  Future<void> loadItems() async {
    isLoadingItem = true;
    notifyListeners();

    items = await itemApi.ItemApi.getLocalItems();

    isLoadingItem = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // CUSTOMER
  // ─────────────────────────────────────────────
  void selectCustomer(api.Customer customer) {
    selectedCustomer = customer;
    selectedItems.clear();
    notifyListeners();
  }

  void clearCustomer() {
    selectedCustomer = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────
  bool isItemSelected(String itemCode) =>
      selectedItems.any((e) => e.itemCode == itemCode);

  void toggleItem(dynamic item) {
    final idx = selectedItems.indexWhere((e) => e.itemCode == item.itemCode);

    if (idx >= 0) {
      selectedItems.removeAt(idx);
    } else {
      selectedItems.add(SaleItem(
        itemCode: item.itemCode,
        name: item.itemName,
        price: item.sellingPrice,
        qty: 1,
        uom: item.invUoMCode,
        itemGroupName: item.itemGroupName,
        subGroupDes: item.subGroupDes,
        subGroup2Des: item.subGroup2Des,
        manufacturerDes: item.manufacturerDes,
        whsCode: item.dflwhs,
        ocrCode: item.ocrCode,
        ocrCode2: item.ocrCode2,
        ocrCode3: item.ocrCode3,
        ocrCode4: item.ocrCode4,
      ));
    }

    notifyListeners();
  }

  void updateItemQty(SaleItem item, int change) {
    final index = selectedItems.indexWhere((e) => e.itemCode == item.itemCode);
    if (index == -1) return;

    final current = selectedItems[index];
    final newQty = current.qty + change;

    if (newQty <= 0) {
      selectedItems.removeAt(index);
    } else {
      selectedItems[index] = SaleItem(
        itemCode: current.itemCode,
        name: current.name,
        price: current.price,
        qty: newQty,
        uom: current.uom,
        whsCode: current.whsCode,
        ocrCode: current.ocrCode,
        ocrCode2: current.ocrCode2,
        ocrCode3: current.ocrCode3,
        ocrCode4: current.ocrCode4,
        itemGroupName: current.itemGroupName,
        subGroupDes: current.subGroupDes,
        subGroup2Des: current.subGroup2Des,

        uDiscPer: current.uDiscPer,
        uDiscAmt: current.uDiscAmt,

        uInvDiscountPer: current.uInvDiscountPer,
        uInvDicountAmt: current.uInvDicountAmt,

        uInOther9: current.uInOther9,
        uMnOther9: current.uMnOther9,
        uRemarkOther9: current.uRemarkOther9,

        uInOther10: current.uInOther10,
        uMnOther10: current.uMnOther10,
        uRemarkOther10: current.uRemarkOther10,

        uInOther11: current.uInOther11,
        uMnOther11: current.uMnOther11,
        uRemarkOther11: current.uRemarkOther11,

        uInOther12: current.uInOther12,
        uMnOther12: current.uMnOther12,
        uRemarkOther12: current.uRemarkOther12,

        uInvPaymentAmt: current.uInvPaymentAmt,
        uPaymentPer: current.uPaymentPer,
        uPaymentAmt: current.uPaymentAmt,
        uInvPaymentPer: current.uInvPaymentPer,

        uInvVoucherAmt: current.uInvVoucherAmt,
        uVoucher: current.uVoucher,
        uVoucherNo: current.uVoucherNo,

        uInvTransportAmt: current.uInvTransportAmt,
        uTransportationPercent: current.uTransportationPercent,
        uTransportationAmt: current.uTransportationAmt,

        uInvSpecialAmt: current.uInvSpecialAmt,
        uSpecialPricePercent: current.uSpecialPricePercent,
        uSpecialPriceAmt: current.uSpecialPriceAmt,

        uPolicyDisc: current.uPolicyDisc,
        uInvTransportPer: current.uInvTransportPer,
        uInvSpecialPer: current.uInvSpecialPer,
        uInvSpecialFreeAmt: current.uInvSpecialFreeAmt,

        uAddOnStatus: current.uAddOnStatus,
        uInvTransprtFAmt: current.uInvTransprtFAmt,

        uInvCurrency: current.uInvCurrency,
        uMnCurrency: current.uMnCurrency,
        uRemarkCurrency: current.uRemarkCurrency,

        uInvFactory: current.uInvFactory,
        uMnFactory: current.uMnFactory,
        uRemarkFactory: current.uRemarkFactory,

        uInvTransportB7: current.uInvTransportB7,
        uMnTransportB7: current.uMnTransportB7,
        uRemarkTransportB7: current.uRemarkTransportB7,

        uInvTransportB8: current.uInvTransportB8,
        uMnTransportB8: current.uMnTransportB8,
        uRemarkTransportB8: current.uRemarkTransportB8,

        uInvEmployeeCom: current.uInvEmployeeCom,
        uMnEmployeeCom: current.uMnEmployeeCom,
        uRemarkEmployeeCom: current.uRemarkEmployeeCom,

        uInvDepotCom: current.uInvDepotCom,
        uMnDepotCom: current.uMnDepotCom,
        uRemarkDepotCom: current.uRemarkDepotCom,

        uInvQuarterCom: current.uInvQuarterCom,
        uMnQuarterCom: current.uMnQuarterCom,
        uRemarkQuarterCom: current.uRemarkQuarterCom,

        uInvMarketing: current.uInvMarketing,
        uMnMarketing: current.uMnMarketing,
        uRemarkMarketing: current.uRemarkMarketing,

        uSpecialTrAmt: current.uSpecialTrAmt,
        uSpecialTrnPer: current.uSpecialTrnPer,

        uQtyFactory: current.uQtyFactory,
      );
    }

    notifyListeners();
  }

  void updateItemQtyByValue(SaleItem item, double qty) {
    final index = selectedItems.indexWhere(
          (e) => e.itemCode == item.itemCode && e.lineTotal == item.lineTotal,
    );
    if (index == -1) return;

    selectedItems[index] = selectedItems[index].copyWith(qty: qty);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // DISCOUNT
  // ─────────────────────────────────────────────

  /// Returns the updated [discountAmount] so the UI can sync the text field.
  double onDiscountPercentChanged(String value) {
    if (_isUpdatingDiscount) return discountAmount;
    _isUpdatingDiscount = true;

    double percent = double.tryParse(value) ?? 0.0;
    percent = percent.clamp(0.0, 100.0);

    discountPercent = percent;
    discountAmount = subTotal * percent / 100;

    notifyListeners();
    _isUpdatingDiscount = false;
    return discountAmount;
  }

  /// Returns the updated [discountPercent] so the UI can sync the text field.
  double onDiscountAmountChanged(String value) {
    if (_isUpdatingDiscount) return discountPercent;
    _isUpdatingDiscount = true;

    double amount = double.tryParse(value) ?? 0.0;
    amount = amount.clamp(0.0, subTotal);

    discountAmount = amount;
    discountPercent = subTotal > 0 ? (amount / subTotal) * 100 : 0.0;

    notifyListeners();
    _isUpdatingDiscount = false;
    return discountPercent;
  }

  // ─────────────────────────────────────────────
  // ORDER DETAILS
  // ─────────────────────────────────────────────
  void setOwner(String value) {
    ownerValue = value;
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    paymentMethodValue = value;
    notifyListeners();
  }

  void setDeliveryTime(TimeOfDay time) {
    deliveryTime = time;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // PROMOTION
  // ─────────────────────────────────────────────
  Future<bool> saveItemLog() async {
    if (selectedCustomer == null || selectedItems.isEmpty) return false;
    if (isRunningPromotion || isPromotionLocked) return false;

    isRunningPromotion = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final logId = "PROMO${now.millisecondsSinceEpoch}";

      final logs = selectedItems.asMap().entries.map((entry) {
        final item = entry.value;
        return UserLogItemPayload(
          id: logId,
          lineNum: entry.key + 1,
          cardCode: selectedCustomer!.cardCode,
          itemCode: item.itemCode,
          qty: (item.qty ?? 0).toDouble(),
          discountPer: discountPercent,
          uom: item.uom,
          price: (item.price ?? 0).toDouble(),
          lineTotal: ((item.qty ?? 0) * (item.price ?? 0)).toDouble(),
          reason: "PROMO",
          docDate: now.toIso8601String().split("T").first,
          paymentMethod: paymentMethodValue,
        );
      }).toList();

      debugPrint("PROMOTION REQUEST:");
      debugPrint(jsonEncode(logs.map((e) => e.toJson()).toList()));

      final result = await UserLogItemApi.submitLogs(logs: logs);

      debugPrint("SAVE RESPONSE: ${result.message}");

      if (!result.isSuccess) {
        debugPrint("Save failed, skip promotion");
        return false;
      }

      isPromotionLocked = true;
      notifyListeners();

      final promoResult = await PromotionService.getPromotionResult(logId);

      debugPrint("PROMOTION RESULT: total=${promoResult.total}, items=${promoResult.data.length}");

      applyPromotionResult(promoResult.data);

      isPromotionLocked = true;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("PROMOTION ERROR: $e");
      return false;
    } finally {
      isRunningPromotion = false;
      notifyListeners();
    }
  }

  void applyPromotionResult(List<PromotionResult> promoList) {
    for (final promo in promoList) {
      final index = selectedItems.indexWhere(
            (e) => e.itemCode == promo.itemCode,
      );

      if (index == -1) continue;

      final item = selectedItems[index];

      // ── FREE QUANTITY ───────────────────────────────────────────────────
      if (promo.promotionType == "FreeQuantity") {
        final freeQty = promo.match1.toDouble();

        final alreadyExists = selectedItems.any(
              (e) => e.itemCode == promo.itemCode && e.uRemarkOther12 == "FREE_ITEM",
        );

        if (alreadyExists) continue;

        selectedItems.insert(
          index + 1,
          SaleItem(
            itemCode: item.itemCode,
            name: "${item.name} (FREE)",
            price: 0,
            whsCode: item.whsCode,
            ocrCode: item.ocrCode,
            ocrCode2: item.ocrCode2,
            ocrCode3: item.ocrCode3,
            ocrCode4: item.ocrCode4,
            qty: freeQty,
            uom: item.uom,
            itemGroupName: item.itemGroupName,
            subGroupDes: item.subGroupDes,
            subGroup2Des: item.subGroup2Des,
            uInvDiscountPer: 0,
            uInvDicountAmt: 0,
            disAmt: (item.price ?? 0) * freeQty,
            discPrcnt: 100,
            lineTotal: 0,
            uRemarkOther12: "FREE_ITEM",
          ),
        );
        continue;
      }

      // ── NORMAL PROMOTION ────────────────────────────────────────────────
      double discountPer = item.uInvDiscountPer ?? 0;
      double discountAmt = item.uInvDicountAmt ?? 0;

      double invPaymentAmt = item.uInvPaymentAmt ?? 0;
      double paymentPer = item.uPaymentPer ?? 0;
      double paymentAmt = item.uPaymentAmt ?? 0;
      double invPaymentPer = item.uInvPaymentPer ?? 0;

      double InOther9 = item.uInOther9 ?? 0;
      double MnOther9 = item.uMnOther9 ?? 0;
      String remark9 = item.uRemarkOther9 ?? "";

      double InOther10 = item.uInOther10 ?? 0;
      double MnOther10 = item.uMnOther10 ?? 0;
      String remark10 = item.uRemarkOther10 ?? "";

      double InOther11 = item.uInOther11 ?? 0;
      double MnOther11 = item.uMnOther11 ?? 0;
      String remark11 = item.uRemarkOther11 ?? "";

      double InOther12 = item.uInOther12 ?? 0;
      double MnOther12 = item.uMnOther12 ?? 0;
      String remark12 = item.uRemarkOther12 ?? "";

      double specialAmt = item.uSpecialPriceAmt ?? 0;
      double specialPer = item.uSpecialPricePercent ?? 0;

      double voucherAmt = item.uInvVoucherAmt ?? 0;

      double transportAmt = item.uInvTransportAmt ?? 0;
      double transportPer = item.uInvTransportPer ?? 0;
      double transportFAmt = item.uInvTransprtFAmt ?? 0;

      double invSpecialAmt = item.uInvSpecialAmt ?? 0;
      double invSpecialPer = item.uInvSpecialPer ?? 0;

      double specialTrAmt = item.uSpecialTrAmt ?? 0;
      double specialTrnPer = item.uSpecialTrnPer ?? 0;
      double invSpecialFreeAmt = item.uInvSpecialFreeAmt ?? 0;

      double invCurrency = item.uInvCurrency ?? 0;
      double mnCurrency = item.uMnCurrency ?? 0;
      String remarkCurrency = item.uRemarkCurrency ?? "";

      double invFactory = item.uInvFactory ?? 0;
      double mnFactory = item.uMnFactory ?? 0;
      String remarkFactory = item.uRemarkFactory ?? "";

      double invTransportB7 = item.uInvTransportB7 ?? 0;
      double mnTransportB7 = item.uMnTransportB7 ?? 0;
      String remarkTransportB7 = item.uRemarkTransportB7 ?? "";

      double invTransportB8 = item.uInvTransportB8 ?? 0;
      double mnTransportB8 = item.uMnTransportB8 ?? 0;
      String remarkTransportB8 = item.uRemarkTransportB8 ?? "";

      double invEmployeeCom = item.uInvEmployeeCom ?? 0;
      double mnEmployeeCom = item.uMnEmployeeCom ?? 0;
      String remarkEmployeeCom = item.uRemarkEmployeeCom ?? "";

      double invDepotCom = item.uInvDepotCom ?? 0;
      double mnDepotCom = item.uMnDepotCom ?? 0;
      String remarkDepotCom = item.uRemarkDepotCom ?? "";

      double invQuarterCom = item.uInvQuarterCom ?? 0;
      double mnQuarterCom = item.uMnQuarterCom ?? 0;
      String remarkQuarterCom = item.uRemarkQuarterCom ?? "";

      double invMarketing = item.uInvMarketing ?? 0;
      double mnMarketing = item.uMnMarketing ?? 0;
      String remarkMarketing = item.uRemarkMarketing ?? "";

      // ── Apply Promotion ────────────────────────────────────────────────
      switch (promo.promotionType) {
        case "Discount":
          discountPer = promo.match;
          discountAmt = promo.match1;
          break;

        case "Cash_Invoice":
          invPaymentAmt = promo.match1;
          invPaymentPer = promo.match;
          break;

        case "Cash_Income":
          paymentAmt = promo.match1;
          paymentPer = promo.match;
          break;

        case "Transportation":
          transportAmt = promo.match1;
          transportPer = promo.match;
          transportFAmt = promo.match;
          break;

        case "Special_Discount":
          invSpecialAmt = promo.match1;
          invSpecialPer = promo.match;
          break;

        case "Special_Transportation":
          specialTrAmt = promo.match1;
          specialTrnPer = promo.match;
          invSpecialFreeAmt = promo.match;
          break;

        case "Currency":
          invCurrency = promo.match1;
          mnCurrency = promo.match;
          remarkCurrency = promo.remark ?? "";
          break;

        case "FactorySupport":
          invFactory = promo.match1;
          mnFactory = promo.match;
          remarkFactory = promo.remark ?? "";
          break;

        case "TransportbyBoat7":
          invTransportB7 = promo.match1;
          mnTransportB7 = promo.match;
          remarkTransportB7 = promo.remark ?? "";
          break;

        case "TransportbyBoat8":
          invTransportB8 = promo.match1;
          mnTransportB8 = promo.match;
          remarkTransportB8 = promo.remark ?? "";
          break;

        case "EmployeeCommission":
          invEmployeeCom = promo.match1;
          mnEmployeeCom = promo.match;
          remarkEmployeeCom = promo.remark ?? "";
          break;

        case "DepotCommission":
          invDepotCom = promo.match1;
          mnDepotCom = promo.match;
          remarkDepotCom = promo.remark ?? "";
          break;

        case "QuarterCommission":
          invQuarterCom = promo.match1;
          mnQuarterCom = promo.match;
          remarkQuarterCom = promo.remark ?? "";
          break;

        case "MarketingExpense":
          invMarketing = promo.match1;
          mnMarketing = promo.match;
          remarkMarketing = promo.remark ?? "";
          break;

        case "Other9":
          MnOther9 = promo.match;
          InOther9= promo.match1;
          remark9 = promo.remark ?? "";
          break;

        case "Other10":
          MnOther10 = promo.match;
          InOther10 = promo.match1;
          remark10 = promo.remark ?? "";
          break;

        case "Other11":
          MnOther11 = promo.match;
          InOther11 = promo.match1;
          remark11 = promo.remark ?? "";
          break;

        case "Other12":
          MnOther12 = promo.match;
          InOther12 = promo.match1;
          remark12 = promo.remark ?? "";
          break;

        case "Voucher":
          voucherAmt = promo.match1;
          break;
      }

      final grossTotal = (item.qty ?? 0) * (item.price ?? 0);

      final totalDiscount = discountAmt +
          InOther9 +
          InOther10 +
          InOther11 +
          InOther12 +
          specialAmt +
          voucherAmt +
          invPaymentAmt +
          paymentAmt +
          transportAmt +
          invSpecialAmt +
          specialTrAmt +
          invCurrency +
          invFactory +
          invTransportB7 +
          invTransportB8 +
          invEmployeeCom +
          invDepotCom +
          invQuarterCom +
          invMarketing;

      final netLineTotal = grossTotal - totalDiscount;

      // ── Update Item ───────────────────────────────────────────────────
      selectedItems[index] = SaleItem(
        itemCode: item.itemCode,
        name: item.name,
        price: item.price,
        qty: item.qty,
        uom: item.uom,
        whsCode: item.whsCode,
        ocrCode: item.ocrCode,
        ocrCode2: item.ocrCode2,
        ocrCode3: item.ocrCode3,
        ocrCode4: item.ocrCode4,
        itemGroupName: item.itemGroupName,
        subGroupDes: item.subGroupDes,
        subGroup2Des: item.subGroup2Des,

        uInvDiscountPer: discountPer,
        uInvDicountAmt: discountAmt,

        uInvPaymentAmt: invPaymentAmt,
        uPaymentPer: paymentPer,
        uPaymentAmt: paymentAmt,
        uInvPaymentPer: invPaymentPer,

        uInOther9: InOther9,
        uMnOther9: MnOther9,
        uRemarkOther9: remark9,

        uInOther10: InOther10,
        uMnOther10: MnOther10,
        uRemarkOther10: remark10,

        uInOther11: InOther11,
        uMnOther11: MnOther11,
        uRemarkOther11: remark11,

        uInOther12: InOther12,
        uMnOther12: MnOther12,
        uRemarkOther12: remark12,

        uSpecialPriceAmt: specialAmt,
        uSpecialPricePercent: specialPer,

        uInvVoucherAmt: voucherAmt,

        uInvTransportAmt: transportAmt,
        uInvTransportPer: transportPer,
        uInvTransprtFAmt: transportFAmt,

        uInvSpecialAmt: invSpecialAmt,
        uInvSpecialPer: invSpecialPer,

        uSpecialTrAmt: specialTrAmt,
        uSpecialTrnPer: specialTrnPer,
        uInvSpecialFreeAmt: invSpecialFreeAmt,

        uInvCurrency: invCurrency,
        uMnCurrency: mnCurrency,
        uRemarkCurrency: remarkCurrency,

        uInvFactory: invFactory,
        uMnFactory: mnFactory,
        uRemarkFactory: remarkFactory,

        uInvTransportB7: invTransportB7,
        uMnTransportB7: mnTransportB7,
        uRemarkTransportB7: remarkTransportB7,

        uInvTransportB8: invTransportB8,
        uMnTransportB8: mnTransportB8,
        uRemarkTransportB8: remarkTransportB8,

        uInvEmployeeCom: invEmployeeCom,
        uMnEmployeeCom: mnEmployeeCom,
        uRemarkEmployeeCom: remarkEmployeeCom,

        uInvDepotCom: invDepotCom,
        uMnDepotCom: mnDepotCom,
        uRemarkDepotCom: remarkDepotCom,

        uInvQuarterCom: invQuarterCom,
        uMnQuarterCom: mnQuarterCom,
        uRemarkQuarterCom: remarkQuarterCom,

        uInvMarketing: invMarketing,
        uMnMarketing: mnMarketing,
        uRemarkMarketing: remarkMarketing,

        lineTotal: netLineTotal,
      );
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SAVE ORDER
  // ─────────────────────────────────────────────
  Future<bool> saveOrder({required String remark}) async {
    if (selectedCustomer == null || selectedItems.isEmpty) return false;

    isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      String formatIsoSeconds(DateTime dateTime) {
        final isoString = dateTime.toIso8601String();
        if (isoString.contains('.')) {
          return isoString.split('.').first;
        }
        return isoString;
      }

      final formattedTimestamp = formatIsoSeconds(now);
      final currentUserCode = SessionManager.currentUser?.userCode ?? "Admin";
      final currentSalesCode = SessionManager.currentUser?.slpCode ?? "";

      String fmtTime(TimeOfDay? t) {
        if (t == null) return "";
        return "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
      }

      final payload = SaleOrderPayload(
        docDate: formattedTimestamp,
        docDueDate: formattedTimestamp,
        uDeliveryTime: fmtTime(deliveryTime),

        cardCode: selectedCustomer!.cardCode,
        cardName: selectedCustomer!.cardName,
        address: selectedCustomer!.fullAddress,

        discPrcnt: discountPercent,
        discSum: discountAmount,
        subTotal: subTotal,
        docTotal: docTotal,
        userSign: currentUserCode,
        salesCode: currentSalesCode,
        ref2: "",

        comments: remark,

        uPaymentMethod: paymentMethodValue,
        uOwner: ownerValue,

        createDate: formattedTimestamp,

        checkInDate: "",
        checkOutDate: "",

        so1Lines: List.generate(selectedItems.length, (index) {
          final i = selectedItems[index];

          // ── DYNAMIC FALLBACK SYSTEM ──
          // If promotional calculation was completed, use that lineTotal.
          // Otherwise, dynamically fallback to standard item configuration calculations.
          final double finalCalculatedLineTotal = (i.lineTotal != null && i.lineTotal! > 0)
              ? i.lineTotal!
              : ((i.qty ?? 0) * (i.price ?? 0)).toDouble();

          return SaleOrderLine(
            docEntry: 0,
            lineNum: index + 1,

            itemCode: i.itemCode,
            dscription: i.name,

            quantity: i.qty,
            uomCode: i.uom,
            unitMsr: i.uom,

            price: i.price,
            lineTotal: double.parse(finalCalculatedLineTotal.toStringAsFixed(2)),

            taxCode: "VATOUT00",
            whsCode: i.whsCode ?? "WH001",

            ocrCode: i.ocrCode ?? "",
            ocrCode2: i.ocrCode2,
            ocrCode3: i.ocrCode3,
            ocrCode4: i.ocrCode4,

            uInvPaymentAmt: double.parse((i.uInvPaymentAmt ?? 0).toStringAsFixed(2)),
            uPaymentPer: double.parse((i.uPaymentPer ?? 0).toStringAsFixed(2)),
            uPaymentAmt: double.parse((i.uPaymentAmt ?? 0).toStringAsFixed(2)),

            uInvDiscountPer: double.parse((i.uInvDiscountPer ?? 0).toStringAsFixed(2)),
            uInvDicountAmt: double.parse((i.uInvDicountAmt ?? 0).toStringAsFixed(2)),
            uDiscPer: double.parse((i.uDiscPer ?? 0).toStringAsFixed(2)),
            uDiscAmt: double.parse((i.uDiscAmt ?? 0).toStringAsFixed(2)),

            uInvVoucherAmt: double.parse((i.uInvVoucherAmt ?? 0).toStringAsFixed(2)),
            uVoucher: i.uVoucher ?? "",
            uVoucherNo: i.uVoucherNo ?? "",

            uInvTransportAmt: double.parse((i.uInvTransportAmt ?? 0).toStringAsFixed(2)),
            uTransportationPercent: double.parse((i.uTransportationPercent ?? 0).toStringAsFixed(2)),
            uTransportationAmt: double.parse((i.uTransportationAmt ?? 0).toStringAsFixed(2)),

            uInvSpecialAmt: double.parse((i.uInvSpecialAmt ?? 0).toStringAsFixed(2)),
            uSpecialPricePercent: double.parse((i.uSpecialPricePercent ?? 0).toStringAsFixed(2)),
            uSpecialPriceAmt: double.parse((i.uSpecialPriceAmt ?? 0).toStringAsFixed(2)),

            uPolicyDisc: double.parse((i.uPolicyDisc ?? 0).toStringAsFixed(2)),
            uInvTransportPer: double.parse((i.uInvTransportPer ?? 0).toStringAsFixed(2)),
            uInvSpecialPer: double.parse((i.uInvSpecialPer ?? 0).toStringAsFixed(2)),
            uInvSpecialFreeAmt: double.parse((i.uInvSpecialFreeAmt ?? 0).toStringAsFixed(2)),
            uInvPaymentPer: double.parse((i.uInvPaymentPer ?? 0).toStringAsFixed(2)),
            uAddOnStatus: i.uAddOnStatus ?? "",
            uInvTransprtFAmt: double.parse((i.uInvTransprtFAmt ?? 0).toStringAsFixed(2)),

            uInvCurrency: double.parse((i.uInvCurrency ?? 0.0).toStringAsFixed(2)),
            uMnCurrency: double.parse((i.uMnCurrency ?? 0).toStringAsFixed(2)),
            uRemarkCurrency: i.uRemarkCurrency ?? "",

            uInvFactory: double.parse((i.uInvFactory ?? 0.0).toStringAsFixed(2)),
            uMnFactory: double.parse((i.uMnFactory ?? 0).toStringAsFixed(2)),
            uRemarkFactory: i.uRemarkFactory ?? "",

            uInvTransportB7: double.parse((i.uInvTransportB7 ?? 0).toStringAsFixed(2)),
            uMnTransportB7: double.parse((i.uMnTransportB7 ?? 0).toStringAsFixed(2)),
            uRemarkTransportB7: i.uRemarkTransportB7 ?? "",

            uInvTransportB8: double.parse((i.uInvTransportB8 ?? 0).toStringAsFixed(2)),
            uMnTransportB8: double.parse((i.uMnTransportB8 ?? 0).toStringAsFixed(2)),
            uRemarkTransportB8: i.uRemarkTransportB8 ?? "",

            uInvEmployeeCom: double.parse((i.uInvEmployeeCom ?? 0).toStringAsFixed(2)),
            uMnEmployeeCom: double.parse((i.uMnEmployeeCom ?? 0).toStringAsFixed(2)),
            uRemarkEmployeeCom: i.uRemarkEmployeeCom ?? "",

            uInvDepotCom: double.parse((i.uInvDepotCom ?? 0).toStringAsFixed(2)),
            uMnDepotCom: double.parse((i.uMnDepotCom ?? 0).toStringAsFixed(2)),
            uRemarkDepotCom: i.uRemarkDepotCom ?? "",

            uInvQuarterCom: double.parse((i.uInvQuarterCom ?? 0).toStringAsFixed(2)),
            uMnQuarterCom: double.parse((i.uMnQuarterCom ?? 0).toStringAsFixed(2)),
            uRemarkQuarterCom: i.uRemarkQuarterCom ?? "",

            uInvMarketing: double.parse((i.uInvMarketing ?? 0).toStringAsFixed(2)),
            uMnMarketing: double.parse((i.uMnMarketing ?? 0).toStringAsFixed(2)),
            uRemarkMarketing: i.uRemarkMarketing ?? "",

            uInOther9: double.parse((i.uInOther9 ?? 0).toStringAsFixed(2)),
            uMnOther9: double.parse((i.uMnOther9 ?? 0).toStringAsFixed(2)),
            uRemarkOther9: i.uRemarkOther9 ?? "",

            uInOther10: double.parse((i.uInOther10 ?? 0).toStringAsFixed(2)),
            uMnOther10: double.parse((i.uMnOther10 ?? 0).toStringAsFixed(2)),
            uRemarkOther10: i.uRemarkOther10 ?? "",

            uInOther11: double.parse((i.uInOther11 ?? 0).toStringAsFixed(2)),
            uMnOther11: double.parse((i.uMnOther11 ?? 0).toStringAsFixed(2)),
            uRemarkOther11: i.uRemarkOther11 ?? "",

            uInOther12: double.parse((i.uInOther12 ?? 0).toStringAsFixed(2)),
            uMnOther12: double.parse((i.uMnOther12 ?? 0).toStringAsFixed(2)),
            uRemarkOther12: i.uRemarkOther12 ?? "",

            uSpecialTrAmt: double.parse((i.uSpecialTrAmt ?? 0).toStringAsFixed(2)),
            uSpecialTrnPer: double.parse((i.uSpecialTrnPer ?? 0).toStringAsFixed(2)),
            uQtyFactory: double.parse((i.uQtyFactory ?? 0).toStringAsFixed(2)),
          );
        }),
      );

      assert(() {
        try {
          const encoder = JsonEncoder.withIndent('  ');
          final prettyJson = encoder.convert(payload.toJson());
          debugPrint("\n=================== 📦 OUTBOUND SO PAYLOAD ===================");
          debugPrint(prettyJson);
          debugPrint("==============================================================\n");
        } catch (e) {
          debugPrint("❌ Failed to stringify debug payload: $e");
        }
        return true;
      }());

      final result = await SaleOrderApi.submitOrder(payload: payload);

      if (!result.isSuccess) {
        debugPrint("❌ API ERROR RESPONSE: ${result.message}");
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList("localOrders") ?? [];
      existing.add(jsonEncode(payload.toJson()));
      await prefs.setStringList("localOrders", existing);

      return true;
    } catch (e) {
      debugPrint("❌ SAVE ORDER CRASH ERROR: $e");
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────
  void resetAll() {
    selectedCustomer = null;
    selectedItems.clear();
    discountPercent = 0.0;
    discountAmount = 0.0;
    ownerValue = "Admin";
    paymentMethodValue = "Invoice";
    deliveryTime = TimeOfDay.now();
    isPromotionLocked = false;
    isRunningPromotion = false;
    isSaving = false;
    notifyListeners();
  }
}