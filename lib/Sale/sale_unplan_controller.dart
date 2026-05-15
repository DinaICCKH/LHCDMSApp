import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_customer_api.dart' as api;
import '../api/get_item_api.dart' as itemApi;
import 'models/sale_order_model.dart';

class SaleController {
  api.Customer? selectedCustomer;
  List<SaleItem> selectedItems = [];

  // ─────────────────────────────────────────────
  // SELECT CUSTOMER
  // ─────────────────────────────────────────────
  void selectCustomer(api.Customer customer) {
    selectedCustomer = customer;
    selectedItems.clear();
  }

}