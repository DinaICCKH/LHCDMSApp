import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_api.dart';

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
  final DateTime? updatedDate;
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
  final double sellingPrice;

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
    this.updatedDate,
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
    required this.sellingPrice,
  });

  /// ---------------- FROM JSON (FIXED SAFETY) ----------------
  factory Item.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      return (value as num).toDouble();
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      return (value as num).toInt();
    }

    String toStr(dynamic value) {
      return value?.toString() ?? '';
    }

    return Item(
      code: toInt(json['Code']),
      message: toStr(json['Message']),
      itemCode: toStr(json['ItemCode']),
      itemName: toStr(json['ItemName']),
      itemGroupCode: toInt(json['ItemGroupCode']),
      itemGroupName: toStr(json['ItemGroupName']),
      ugpEntry: toInt(json['UgpEntry']),
      onhand: toDouble(json['Onhand']),
      onOrder: toDouble(json['OnOrder']),
      isCommited: toDouble(json['IsCommited']),
      available: toDouble(json['Available']),
      minLevel: toDouble(json['MinLevel']),
      maxLevel: toDouble(json['MaxLevel']),
      status: toStr(json['Status']),
      imageUrlServer: json['ImageUrlServer'],
      imageUrlLocal: json['ImageUrlLocal'],
      frgnName: toStr(json['FrgnName']),
      invUoMCode: toStr(json['InvUoMCode']),
      invUoMEntry: toInt(json['InvUoMEntry']),
      updatedDate: json['UpdatedDate'] != null
          ? DateTime.tryParse(json['UpdatedDate'].toString())
          : null,
      ocrCode: toStr(json['OcrCode']),
      ocrCode2: toStr(json['OcrCode2']),
      ocrCode3: toStr(json['OcrCode3']),
      ocrCode4: toStr(json['OcrCode4']),
      manufacturer: toStr(json['Manufacturer']),
      manufacturerDes: json['ManufacturerDes'],
      subGroup: toStr(json['SubGroup']),
      subGroupDes: json['SubGroupDes'],
      itemBrand: toStr(json['ItemBrand']),
      itemBrandDes: json['ItemBrandDes'],
      itemType: toStr(json['ItemType']),
      itemTypeDes: json['ItemTypeDes'],
      proteinType: toStr(json['ProteinType']),
      proteinTypeDes: json['ProteinTypeDes'],
      subGroup2: toStr(json['SubGroup2']),
      subGroup2Des: json['SubGroup2Des'],
      factory: toStr(json['Factory']),
      factoryDes: json['FactoryDes'],
      barCode: toStr(json['BarCode']),
      defEntry: toInt(json['DefEntry']),
      altQty: toDouble(json['AltQty']),
      sellingPrice: toDouble(json['SellingPrice']),
    );
  }

  /// ---------------- TO JSON ----------------
  Map<String, dynamic> toJson() {
    return {
      "Code": code,
      "Message": message,
      "ItemCode": itemCode,
      "ItemName": itemName,
      "ItemGroupCode": itemGroupCode,
      "ItemGroupName": itemGroupName,
      "UgpEntry": ugpEntry,
      "Onhand": onhand,
      "OnOrder": onOrder,
      "IsCommited": isCommited,
      "Available": available,
      "MinLevel": minLevel,
      "MaxLevel": maxLevel,
      "Status": status,
      "ImageUrlServer": imageUrlServer,
      "ImageUrlLocal": imageUrlLocal,
      "FrgnName": frgnName,
      "InvUoMCode": invUoMCode,
      "InvUoMEntry": invUoMEntry,
      "UpdatedDate": updatedDate?.toIso8601String(),
      "OcrCode": ocrCode,
      "OcrCode2": ocrCode2,
      "OcrCode3": ocrCode3,
      "OcrCode4": ocrCode4,
      "Manufacturer": manufacturer,
      "ManufacturerDes": manufacturerDes,
      "SubGroup": subGroup,
      "SubGroupDes": subGroupDes,
      "ItemBrand": itemBrand,
      "ItemBrandDes": itemBrandDes,
      "ItemType": itemType,
      "ItemTypeDes": itemTypeDes,
      "ProteinType": proteinType,
      "ProteinTypeDes": proteinTypeDes,
      "SubGroup2": subGroup2,
      "SubGroup2Des": subGroup2Des,
      "Factory": factory,
      "FactoryDes": factoryDes,
      "BarCode": barCode,
      "DefEntry": defEntry,
      "AltQty": altQty,
      "SellingPrice": sellingPrice,
    };
  }
}

/// =======================
/// ITEM API & LOCAL STORAGE
/// =======================
class ItemApi {
  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/";

  /// ---------------- FETCH & STORE ITEMS ----------------
  static Future<List<Item>> fetchAndStoreItems({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {

    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found. Please login first.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetItems");

    final body = jsonEncode({
      "UserCode": user.userCode,
      "Password": password,
      "DeviceID": user.deviceID,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("📡 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<Item> items = (result['data'] as List)
              .map((e) => Item.fromJson(e))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            "items",
            jsonEncode(items.map((e) => e.toJson()).toList()),
          );

          return items;
        }
      }

      return [];
    } catch (e) {
      print("Error fetching items: $e");
      return [];
    }
  }

  /// ---------------- GET LOCAL ITEMS ----------------
  static Future<List<Item>> getLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("items");

    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Item.fromJson(e)).toList();
    }

    return [];
  }

  /// ---------------- CLEAR LOCAL ITEMS ----------------
  static Future<void> clearLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("items");
  }
}