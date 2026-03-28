import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// APIs
import '../api/get_customer_api.dart';
import '../api/get_item_api.dart';
import '../api/get_visitplan_api.dart';
import '../api/get_warehouse_api.dart';
import '../api/get_uom_api.dart';
import '../api/get_uom_group_api.dart';
import '../api/get_price_list_api.dart';
import '../api/get_itemprice_api.dart';

class SyncDataPage extends StatefulWidget {
  const SyncDataPage({super.key});

  @override
  State<SyncDataPage> createState() => _SyncDataPageState();
}

class _SyncDataPageState extends State<SyncDataPage> {
  final List<String> modules = [
    "Item",
    "Customer",
    "Warehouse",
    "UOM",
    "UOM Group",
    "Price List",
    "Item Pricing",
    "Visit Plan", // ✅ NEW
    "Clear Data",
    "Sync All"
  ];

  Map<String, double> progress = {};
  Map<String, int> syncedCount = {};
  Map<String, int> totalCount = {};
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    for (var module in modules) {
      progress[module] = 0;
      syncedCount[module] = 0;
      totalCount[module] = 0;
    }
  }

  Future<void> syncModule(String module) async {
    final prefs = await SharedPreferences.getInstance();
    final userCode = prefs.getString("codeUser") ?? "U001";
    final deviceID = prefs.getString("deviceID") ?? "UNKNOWN";
    const password = "123456";

    if (module == "Clear Data") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirm Clear Data"),
          content: const Text("Are you sure you want to remove all local data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _clearAllData();
      }
      return;
    }

    setState(() {
      isSyncing = true;
    });

    List<String> modulesToSync = module == "Sync All"
        ? modules.where((m) => m != "Sync All" && m != "Clear Data").toList()
        : [module];

    for (var mod in modulesToSync) {
      setState(() {
        progress[mod] = 0;
        syncedCount[mod] = 0;
        totalCount[mod] = 0;
      });

      try {
        List<dynamic> list = [];

        if (mod == "Item") {
          list = await ItemApi.fetchAndStoreItems(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "Customer") {
          list = await CustomerApi.fetchAndStoreCustomers(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "Warehouse") {
          list = await WarehouseApi.fetchAndStoreWarehouses(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "UOM") {
          list = await UomApi.fetchAndStoreUoms(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "UOM Group") {
          list = await UomGroupApi.fetchAndStoreUomGroups(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "Price List") {
          list = await PriceListApi.fetchAndStorePriceLists(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "Item Pricing") {
          list = await ItemPricingApi.fetchAndStoreItemPricing(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        } else if (mod == "Visit Plan") { // ✅ NEW MODULE
          list = await VisitPlanApi.fetchAndStoreVisitPlans(
            userCode: userCode,
            password: password,
            deviceID: deviceID,
          );
        }

        await _updateProgress(mod, list.length);
      } catch (e) {
        print("Error syncing $mod: $e");
      }
    }

    setState(() {
      isSyncing = false;
    });
  }

  Future<void> _clearAllData() async {
    setState(() {
      isSyncing = true;
    });

    try {
      await ItemApi.clearLocalItems();
      await CustomerApi.clearLocalCustomers();
      await WarehouseApi.clearLocalWarehouses();
      await UomApi.clearLocalUoms();
      await UomGroupApi.clearLocalUomGroups();
      await PriceListApi.clearLocalPriceLists();
      await ItemPricingApi.clearLocalItemPricing();
      await VisitPlanApi.clearLocalVisitPlans(); // ✅ CLEAR VISIT PLAN

      for (var module in modules) {
        progress[module] = 0;
        syncedCount[module] = 0;
        totalCount[module] = 0;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All local data cleared")),
      );
    } catch (e) {
      print("Error clearing data: $e");
    }

    setState(() {
      isSyncing = false;
    });
  }

  Future<void> _updateProgress(String mod, int total) async {
    totalCount[mod] = total;

    if (total == 0) {
      setState(() {
        progress[mod] = 1;
        syncedCount[mod] = 0;
      });
      return;
    }

    for (int i = 0; i < total; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      setState(() {
        syncedCount[mod] = i + 1;
        progress[mod] = (i + 1) / total;
      });
    }
  }

  Widget syncCard(String title) {
    final current = syncedCount[title] ?? 0;
    final total = totalCount[title] ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: title == "Clear Data"
            ? const Text("Remove all local stored data")
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: total > 0 ? progress[title] : 0,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 4),
            Text(
              total > 0
                  ? "$current of $total synced (${(progress[title]! * 100).toStringAsFixed(0)}%)"
                  : "No data to sync",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: title == "Clear Data"
            ? const Icon(Icons.delete, color: Colors.red)
            : Icon(
          progress[title]! >= 1 ? Icons.check_circle : Icons.sync,
          color: progress[title]! >= 1 ? Colors.green : Colors.grey,
        ),
        onTap: isSyncing ? null : () => syncModule(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sync Master Data",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: modules.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: syncCard(modules[index]),
            );
          },
        ),
      ),
    );
  }
}