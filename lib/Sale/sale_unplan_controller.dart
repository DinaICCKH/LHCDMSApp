import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_customer_api.dart' as api;
import '../api/get_item_api.dart' as itemApi;
import 'models/sale_order_model.dart';

class SaleController {
  api.Customer? selectedCustomer; // selected customer
  List<SaleItem> selectedItems = [];

  /// Select a customer and reset selected items
  void selectCustomer(api.Customer customer) {
    selectedCustomer = customer;
    selectedItems.clear();
  }

  /// Add item to the selectedItems list
  void addItem(SaleItem item) {
    int index = selectedItems.indexWhere((i) => i.itemCode == item.itemCode);
    if (index != -1) {
      selectedItems[index].qty += item.qty;
    } else {
      selectedItems.add(item);
    }
  }

  /// Remove item
  void removeItem(SaleItem item) {
    selectedItems.removeWhere((i) => i.itemCode == item.itemCode);
  }

  /// Update quantity
  void updateItemQty(SaleItem item, int qty) {
    int index = selectedItems.indexWhere((i) => i.itemCode == item.itemCode);
    if (index != -1) selectedItems[index].qty = qty;
  }

  /// Calculate subtotal
  double get subtotal {
    return selectedItems.fold(
        0, (prev, e) => prev + e.price * e.qty);
  }

  /// Mock promotion (10% off if subtotal > 50)
  double runPromotion() {
    double sub = subtotal;
    if (sub > 50) return sub * 0.9;
    return sub;
  }

  /// Save order locally
  Future<void> saveOrder(String remark, String loggedInUser) async {
    if (selectedCustomer == null || selectedItems.isEmpty) return;

    final now = DateTime.now();
    final invoiceNumber =
        "${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}";

    final orderData = {
      "invoiceNumber": invoiceNumber,
      "docStatus": "Pending",
      "createBy": loggedInUser,
      "createDate": now.toIso8601String(),
      "remark": remark,
      "customer": {
        "code": selectedCustomer!.cardCode,
        "name": selectedCustomer!.cardName,
        "address": selectedCustomer!.fullAddress,
        "phone": selectedCustomer!.tel1,
      },
      "items": selectedItems
          .map((item) => {
        "itemCode": item.itemCode,
        "name": item.name,
        "qty": item.qty,
        "price": item.price,
        "uom": item.uom,
        "itemGroupName": item.itemGroupName,
        "subGroupDes": item.subGroupDes,
        "subGroup2Des": item.subGroup2Des,
        "total": item.price * item.qty
      })
          .toList(),
      "subtotal": subtotal,
      "discountAmt": subtotal - runPromotion(),
      "docTotal": runPromotion()
    };

    final prefs = await SharedPreferences.getInstance();
    List<String> savedOrders = prefs.getStringList("saleOrders") ?? [];
    savedOrders.add(jsonEncode(orderData));
    await prefs.setStringList("saleOrders", savedOrders);
  }
}