import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale_order_model.dart';

class LocalStorageService {
  // Load Customers from local storage
  static Future<List<Customer>> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("customers");
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Customer(
        code: e['code'],
        name: e['name'],
        phone: e['phone'],
        address: e['address'],
      )).toList();
    }
    return [];
  }

  // Load Items from local storage
  static Future<List<SaleItem>> loadItems(List<String> uomList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("items");
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => SaleItem(
        itemCode: e['itemCode'],
        name: e['name'],
        price: (e['price'] as num).toDouble(),
        qty: 1,
        uom: uomList.first,
      )).toList();
    }
    return [];
  }
}