import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// ITEM MODEL CLASS
/// =======================
class Item {
  final int code;
  final String message;
  final String itemCode;
  final String itemName;
  final int itemGroupCode;
  final String itemGroupName;
  final int ugpEntry;
  final double onhand;
  final double onOrder;
  final double isCommited;
  final double available;
  final double minLevel;
  final double maxLevel;
  final String status;
  final String? imageUrlServer;
  final String? imageUrlLocal;
  final String frgnName;
  final String invUoMCode;
  final int invUoMEntry;
  final DateTime updatedDate;
  final String ocrCode;
  final String ocrCode2;
  final String ocrCode3;
  final String ocrCode4;
  final String manufacturer;
  final String? manufacturerDes;
  final String subGroup;
  final String? subGroupDes;
  final String itemBrand;
  final String? itemBrandDes;
  final String itemType;
  final String? itemTypeDes;
  final String proteinType;
  final String? proteinTypeDes;
  final String subGroup2;
  final String? subGroup2Des;
  final String factory;
  final String? factoryDes;
  final String barCode;
  final int defEntry;
  final double altQty;

  Item({
    required this.code,
    required this.message,
    required this.itemCode,
    required this.itemName,
    required this.itemGroupCode,
    required this.itemGroupName,
    required this.ugpEntry,
    required this.onhand,
    required this.onOrder,
    required this.isCommited,
    required this.available,
    required this.minLevel,
    required this.maxLevel,
    required this.status,
    this.imageUrlServer,
    this.imageUrlLocal,
    required this.frgnName,
    required this.invUoMCode,
    required this.invUoMEntry,
    required this.updatedDate,
    required this.ocrCode,
    required this.ocrCode2,
    required this.ocrCode3,
    required this.ocrCode4,
    required this.manufacturer,
    this.manufacturerDes,
    required this.subGroup,
    this.subGroupDes,
    required this.itemBrand,
    this.itemBrandDes,
    required this.itemType,
    this.itemTypeDes,
    required this.proteinType,
    this.proteinTypeDes,
    required this.subGroup2,
    this.subGroup2Des,
    required this.factory,
    this.factoryDes,
    required this.barCode,
    required this.defEntry,
    required this.altQty,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    code: json['code'],
    message: json['message'],
    itemCode: json['itemCode'],
    itemName: json['itemName'],
    itemGroupCode: json['itemGroupCode'],
    itemGroupName: json['itemGroupName'],
    ugpEntry: json['ugpEntry'],
    onhand: (json['onhand'] as num).toDouble(),
    onOrder: (json['onOrder'] as num).toDouble(),
    isCommited: (json['isCommited'] as num).toDouble(),
    available: (json['available'] as num).toDouble(),
    minLevel: (json['minLevel'] as num).toDouble(),
    maxLevel: (json['maxLevel'] as num).toDouble(),
    status: json['status'],
    imageUrlServer: json['imageUrlServer'],
    imageUrlLocal: json['imageUrlLocal'],
    frgnName: json['frgnName'],
    invUoMCode: json['invUoMCode'],
    invUoMEntry: json['invUoMEntry'],
    updatedDate: DateTime.parse(json['updatedDate']),
    ocrCode: json['ocrCode'],
    ocrCode2: json['ocrCode2'],
    ocrCode3: json['ocrCode3'],
    ocrCode4: json['ocrCode4'],
    manufacturer: json['manufacturer'],
    manufacturerDes: json['manufacturerDes'],
    subGroup: json['subGroup'],
    subGroupDes: json['subGroupDes'],
    itemBrand: json['itemBrand'],
    itemBrandDes: json['itemBrandDes'],
    itemType: json['itemType'],
    itemTypeDes: json['itemTypeDes'],
    proteinType: json['proteinType'],
    proteinTypeDes: json['proteinTypeDes'],
    subGroup2: json['subGroup2'],
    subGroup2Des: json['subGroup2Des'],
    factory: json['factory'],
    factoryDes: json['factoryDes'],
    barCode: json['barCode'],
    defEntry: json['defEntry'],
    altQty: (json['altQty'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "itemCode": itemCode,
    "itemName": itemName,
    "itemGroupCode": itemGroupCode,
    "itemGroupName": itemGroupName,
    "ugpEntry": ugpEntry,
    "onhand": onhand,
    "onOrder": onOrder,
    "isCommited": isCommited,
    "available": available,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "status": status,
    "imageUrlServer": imageUrlServer,
    "imageUrlLocal": imageUrlLocal,
    "frgnName": frgnName,
    "invUoMCode": invUoMCode,
    "invUoMEntry": invUoMEntry,
    "updatedDate": updatedDate.toIso8601String(),
    "ocrCode": ocrCode,
    "ocrCode2": ocrCode2,
    "ocrCode3": ocrCode3,
    "ocrCode4": ocrCode4,
    "manufacturer": manufacturer,
    "manufacturerDes": manufacturerDes,
    "subGroup": subGroup,
    "subGroupDes": subGroupDes,
    "itemBrand": itemBrand,
    "itemBrandDes": itemBrandDes,
    "itemType": itemType,
    "itemTypeDes": itemTypeDes,
    "proteinType": proteinType,
    "proteinTypeDes": proteinTypeDes,
    "subGroup2": subGroup2,
    "subGroup2Des": subGroup2Des,
    "factory": factory,
    "factoryDes": factoryDes,
    "barCode": barCode,
    "defEntry": defEntry,
    "altQty": altQty,
  };
}

/// =======================
/// ITEM API & LOCAL STORAGE
/// =======================
class ItemApi {
  static const String baseUrl = "http://192.168.88.108:90/api/DMS";

  /// Get items from API and store to SharedPreferences
  static Future<List<Item>> fetchAndStoreItems({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/GetItems");
    final body = jsonEncode({
      "UserCode": userCode,
      "Password": password,
      "DeviceID": deviceID,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          final List<Item> items = (result['data'] as List)
              .map((e) => Item.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              "items", jsonEncode(items.map((e) => e.toJson()).toList()));

          return items;
        }
      }
      return [];
    } catch (e) {
      print("Error fetching items: $e");
      return [];
    }
  }

  /// Retrieve items from local storage
  static Future<List<Item>> getLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("items");
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Item.fromJson(e)).toList();
    }
    return [];
  }

  /// Clear stored items
  static Future<void> clearLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("items");
  }
}