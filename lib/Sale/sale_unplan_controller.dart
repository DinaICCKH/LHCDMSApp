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
  double get subTotal =>
      selectedItems.fold(0.0, (sum, i) => sum + i.price * i.qty);

  double get docTotal => subTotal - discountAmount;

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
        itemGroupName: current.itemGroupName,
        subGroupDes: current.subGroupDes,
        subGroup2Des: current.subGroup2Des,
        uInvDicountAmt: current.uInvDicountAmt,
        uInvDiscountPer: current.uInvDiscountPer,
        uSpecialPriceAmt: current.uSpecialPriceAmt,
        uSpecialPricePercent: current.uSpecialPricePercent,
        uInvVoucherAmt: current.uInvVoucherAmt,
        uMnOther9: current.uMnOther9,
        uMnOther10: current.uMnOther10,
        uMnOther11: current.uMnOther11,
        uMnOther12: current.uMnOther12,
        uRemarkOther9: current.uRemarkOther9,
        uRemarkOther10: current.uRemarkOther10,
        uRemarkOther11: current.uRemarkOther11,
        uRemarkOther12: current.uRemarkOther12,
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
          qty: item.qty.toDouble(),
          discountPer: discountPercent,
          uom: item.uom,
          price: item.price.toDouble(),
          lineTotal: (item.qty * item.price).toDouble(),
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
              (e) =>
          e.itemCode == promo.itemCode && e.uRemarkOther12 == "FREE_ITEM",
        );

        if (alreadyExists) continue;

        selectedItems.insert(
          index + 1,
          SaleItem(
            itemCode: item.itemCode,
            name: "${item.name} (FREE)",
            price: item.price,
            qty: freeQty,
            uom: item.uom,
            itemGroupName: item.itemGroupName,
            subGroupDes: item.subGroupDes,
            subGroup2Des: item.subGroup2Des,
            uInvDiscountPer: 100,
            uInvDicountAmt: item.price * freeQty,
            lineTotal: 0,
            uRemarkOther12: "FREE_ITEM",
          ),
        );
        continue;
      }

      // ── NORMAL PROMOTION ────────────────────────────────────────────────
      double discountPer   = item.uInvDiscountPer;
      double discountAmt   = item.uInvDicountAmt;
      double other9Per     = item.uInOther9;
      double other9Amt     = item.uMnOther9;
      double other10Per    = item.uInOther10;
      double other10Amt    = item.uMnOther10;
      double other11Per    = item.uInOther11;
      double other11Amt    = item.uMnOther11;
      double other12Per    = item.uInOther12;
      double other12Amt    = item.uMnOther12;
      double specialAmt    = item.uSpecialPriceAmt;
      double specialPer    = item.uSpecialPricePercent;
      double voucherAmt    = item.uInvVoucherAmt;
      String remark9       = item.uRemarkOther9;
      String remark10      = item.uRemarkOther10;
      String remark11      = item.uRemarkOther11;
      String remark12      = item.uRemarkOther12;

      switch (promo.promotionType) {
        case "Discount":
          discountPer = promo.match;
          discountAmt = promo.match1;
          break;
        case "Other9":
          other9Per = promo.match;
          other9Amt = promo.match1;
          remark9 = promo.remark ?? "";
          break;
        case "Other10":
          other10Per = promo.match;
          other10Amt = promo.match1;
          remark10 = promo.remark ?? "";
          break;
        case "Other11":
          other11Per = promo.match;
          other11Amt = promo.match1;
          remark11 = promo.remark ?? "";
          break;
        case "Other12":
          other12Per = promo.match;
          other12Amt = promo.match1;
          remark12 = promo.remark ?? "";
          break;
        case "SpecialPrice":
          specialPer = promo.match;
          specialAmt = promo.match1;
          break;
        case "Voucher":
          voucherAmt = promo.match1;
          break;
      }

      final grossTotal = item.qty * item.price;
      final totalDiscount = discountAmt +
          other9Amt +
          other10Amt +
          other11Amt +
          other12Amt +
          specialAmt +
          voucherAmt;
      final netLineTotal = grossTotal - totalDiscount;

      selectedItems[index] = SaleItem(
        itemCode: item.itemCode,
        name: item.name,
        price: item.price,
        qty: item.qty,
        uom: item.uom,
        itemGroupName: item.itemGroupName,
        subGroupDes: item.subGroupDes,
        subGroup2Des: item.subGroup2Des,
        uInvDiscountPer: discountPer,
        uInvDicountAmt: discountAmt,
        uSpecialPriceAmt: specialAmt,
        uSpecialPricePercent: specialPer,
        uInvVoucherAmt: voucherAmt,
        uInOther9: other9Per,
        uMnOther9: other9Amt,
        uRemarkOther9: remark9,
        uInOther10: other10Per,
        uMnOther10: other10Amt,
        uRemarkOther10: remark10,
        uInOther11: other11Per,
        uMnOther11: other11Amt,
        uRemarkOther11: remark11,
        uInOther12: other12Per,
        uMnOther12: other12Amt,
        uRemarkOther12: remark12,
        lineTotal: netLineTotal,
      );
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // SAVE ORDER
  // ─────────────────────────────────────────────
  /// Saves the order to SharedPreferences.
  /// Returns true on success, false on failure.
  /// The UI is responsible for showing the confirm dialog before calling this.
  Future<bool> saveOrder({required String remark}) async {
    if (selectedCustomer == null || selectedItems.isEmpty) return false;

    isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      // ─────────────────────────────────────────────────────────────────
      // ⏰ DATE FORMATTER: Removes trailing milliseconds/microseconds
      // Transforms: "2026-05-18T13:39:34.495064" -> "2026-05-18T13:39:34"
      // ─────────────────────────────────────────────────────────────────
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

        createDate: formattedTimestamp, // 👈 Applied here

        checkInDate: "",
        checkOutDate: "",

        so1Lines: List.generate(selectedItems.length, (index) {
          final i = selectedItems[index];

          return SaleOrderLine(
            docEntry: 0,
            lineNum: index + 1,

            itemCode: i.itemCode,
            dscription: i.name,

            quantity: i.qty,
            uomCode: i.uom,
            unitMsr: i.uom,

            price: i.price,
            lineTotal: i.qty * i.price,

            taxCode: "VATOUT00",
            whsCode: i.whsCode ?? "WH001",

            // ───────── COST CENTER (NO FAKE DEFAULTS) ─────────
            ocrCode: i.ocrCode ?? "",
            ocrCode2: i.ocrCode2,
            ocrCode3: i.ocrCode3,
            ocrCode4: i.ocrCode4,

            // ───────── PAYMENT ─────────
            uInvPaymentAmt: i.uInvPaymentAmt,
            uPaymentPer: i.uPaymentPer,
            uPaymentAmt: i.uPaymentAmt,

            // ───────── DISCOUNT ─────────
            uInvDiscountPer: i.uInvDiscountPer,
            uInvDicountAmt: i.uInvDicountAmt,
            uDiscPer: i.uDiscPer,
            uDiscAmt: i.uDiscAmt,

            // ───────── VOUCHER ─────────
            uInvVoucherAmt: i.uInvVoucherAmt,
            uVoucher: i.uVoucher ?? "",
            uVoucherNo: i.uVoucherNo ?? "",

            // ───────── TRANSPORT ─────────
            uInvTransportAmt: i.uInvTransportAmt,
            uTransportationPercent: i.uTransportationPercent,
            uTransportationAmt: i.uTransportationAmt,

            // ───────── SPECIAL ─────────
            uInvSpecialAmt: i.uInvSpecialAmt,
            uSpecialPricePercent: i.uSpecialPricePercent,
            uSpecialPriceAmt: i.uSpecialPriceAmt,

            // ───────── POLICY ─────────
            uPolicyDisc: i.uPolicyDisc,
            uInvTransportPer: i.uInvTransportPer,
            uInvSpecialPer: i.uInvSpecialPer,
            uInvSpecialFreeAmt: i.uInvSpecialFreeAmt,
            uInvPaymentPer: i.uInvPaymentPer,
            uAddOnStatus: i.uAddOnStatus ?? "",
            uInvTransprtFAmt: i.uInvTransprtFAmt,

            // ───────── CURRENCY ─────────
            uInvCurrency: i.uInvCurrency ?? "",
            uMnCurrency: i.uMnCurrency,
            uRemarkCurrency: i.uRemarkCurrency ?? "",

            // ───────── FACTORY ─────────
            uInvFactory: i.uInvFactory ?? "",
            uMnFactory: i.uMnFactory,
            uRemarkFactory: i.uRemarkFactory ?? "",

            // ───────── TRANSPORT B7 ─────────
            uInvTransportB7: i.uInvTransportB7,
            uMnTransportB7: i.uMnTransportB7,
            uRemarkTransportB7: i.uRemarkTransportB7 ?? "",

            // ───────── TRANSPORT B8 ─────────
            uInvTransportB8: i.uInvTransportB8,
            uMnTransportB8: i.uMnTransportB8,
            uRemarkTransportB8: i.uRemarkTransportB8 ?? "",

            // ───────── COMMISSION ─────────
            uInvEmployeeCom: i.uInvEmployeeCom,
            uMnEmployeeCom: i.uMnEmployeeCom,
            uRemarkEmployeeCom: i.uRemarkEmployeeCom ?? "",

            uInvDepotCom: i.uInvDepotCom,
            uMnDepotCom: i.uMnDepotCom,
            uRemarkDepotCom: i.uRemarkDepotCom ?? "",

            uInvQuarterCom: i.uInvQuarterCom,
            uMnQuarterCom: i.uMnQuarterCom,
            uRemarkQuarterCom: i.uRemarkQuarterCom ?? "",

            uInvMarketing: i.uInvMarketing,
            uMnMarketing: i.uMnMarketing,
            uRemarkMarketing: i.uRemarkMarketing ?? "",

            // ───────── OTHER ─────────
            uInOther9: i.uInOther9,
            uMnOther9: i.uMnOther9,
            uRemarkOther9: i.uRemarkOther9 ?? "",

            uInOther10: i.uInOther10,
            uMnOther10: i.uMnOther10,
            uRemarkOther10: i.uRemarkOther10 ?? "",

            uInOther11: i.uInOther11,
            uMnOther11: i.uMnOther11,
            uRemarkOther11: i.uRemarkOther11 ?? "",

            uInOther12: i.uInOther12,
            uMnOther12: i.uMnOther12,
            uRemarkOther12: i.uRemarkOther12 ?? "",

            // ───────── SPECIAL FINAL ─────────
            uSpecialTrAmt: i.uSpecialTrAmt,
            uSpecialTrnPer: i.uSpecialTrnPer,
            uQtyFactory: i.uQtyFactory,
          );
        }),
      );

      // ─────────────────────────────────────────────────────────────────
      // 🔍 DEBUG: PRETTY PRINT PAYLOAD BEFORE SENDING TO API
      // ─────────────────────────────────────────────────────────────────
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

      // save local backup (optional)
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
    deliveryTime = null;
    isPromotionLocked = false;
    isRunningPromotion = false;
    isSaving = false;
    notifyListeners();
  }
}
