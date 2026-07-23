import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kuberadmsdn/api/get_saleorder_summary_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For formatting the date/time nicely

// APIs
import '../api/get_customer_api.dart';
import '../api/get_item_api.dart';
import '../api/get_visitplan_api.dart';
import '../api/get_warehouse_api.dart';
import '../api/get_uom_api.dart';
import '../api/get_uom_group_api.dart';
import '../api/get_price_list_api.dart';
import '../api/get_itemprice_api.dart';
import '../api/get_reason_api.dart';

class SyncDataPage extends StatefulWidget {
  final Map<String, int>? initialCounts;

  const SyncDataPage({
    super.key,
    this.initialCounts,
  });

  @override
  State<SyncDataPage> createState() => _SyncDataPageState();
}

class _SyncDataPageState extends State<SyncDataPage> {
  final List<String> modules = [
    "Item", "Customer", "Warehouse", "UOM",
    "UOM Group", "Price List", "Item Pricing", "Visit Plan", "Sale Summary", "Reason",
  ];

  final List<String> visibleModules = [
    "Item", "Customer", "Visit Plan", "Sale Summary", "Reason",
  ];

  Map<String, double> progress = {};
  Map<String, int> syncedCount = {};
  Map<String, int> totalCount = {};
  Map<String, bool> syncedStatus = {};

  // Track last sync time per module
  Map<String, String> lastSyncTimes = {};

  bool isSyncing = false;
  String currentSyncingModule = "";

  @override
  void initState() {
    super.initState();

    for (var module in modules) {
      progress[module] = 0;
      syncedCount[module] = 0;
      totalCount[module] = 0;
      syncedStatus[module] = false;
      lastSyncTimes[module] = "-";
    }
    _loadSavedSyncStatus();
  }

  /// LOAD REAL LOCAL STATUS & LAST SYNC TIME
  Future<void> _loadSavedSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();

    for (var module in modules) {
      int localCount = 0;

      try {
        if (module == "Item") {
          localCount = (await ItemApi.getLocalItems()).length;
        } else if (module == "Customer") {
          localCount = (await CustomerApi.getLocalCustomers()).length;
        } else if (module == "Warehouse") {
          localCount = (await WarehouseApi.getLocalWarehouses()).length;
        } else if (module == "UOM") {
          localCount = (await UomApi.getLocalUoms()).length;
        } else if (module == "UOM Group") {
          localCount = (await UomGroupApi.getLocalUomGroups()).length;
        } else if (module == "Price List") {
          localCount = (await PriceListApi.getLocalPriceLists()).length;
        } else if (module == "Item Pricing") {
          localCount = (await ItemPricingApi.getLocalItemPricing()).length;
        } else if (module == "Visit Plan") {
          localCount = (await VisitPlanApi.getLocalVisitPlans()).length;
        } else if (module == "Sale Summary") {
          localCount = (await SaleSummaryApi.getLocalSaleSummary()).length;
        } else if (module == "Reason") {
          localCount = (await ReasonApi.getLocalReasons()).length;
        }

        // Load saved last sync timestamp string
        String? savedTime = prefs.getString("time_$module");
        if (savedTime != null) {
          lastSyncTimes[module] = savedTime;
        }

        if (localCount > 0) {
          syncedStatus[module] = true;
          syncedCount[module] = localCount;
          totalCount[module] = localCount;
          progress[module] = 1.0;
        } else {
          syncedStatus[module] = false;
          syncedCount[module] = 0;
          totalCount[module] = 0;
          progress[module] = 0;
        }
      } catch (e) {
        print("❌ Error loading $module : $e");
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// SAVE STATUS & TIMESTAMP
  Future<void> _saveSyncStatus(String module, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await prefs.setBool("sync_$module", true);
    await prefs.setInt("total_$module", total);
    await prefs.setString("time_$module", formattedTime);

    setState(() {
      lastSyncTimes[module] = formattedTime;
    });
  }

  /// RESET STATUS
  Future<void> _resetSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    for (var module in modules) {
      await prefs.remove("sync_$module");
      await prefs.remove("total_$module");
      await prefs.remove("time_$module");
      lastSyncTimes[module] = "-";
    }
  }

  /// SYNC MODULE
  Future<void> syncModule(String module) async {
    if (isSyncing) return;

    final prefs = await SharedPreferences.getInstance();
    final userCode = prefs.getString("codeUser") ?? "U001";
    final deviceID = prefs.getString("deviceID") ?? "UNKNOWN";
    const password = "123456";

    setState(() => isSyncing = true);

    List<String> modulesToSync = module == "Sync All" ? modules : [module];

    try {
      for (var mod in modulesToSync) {
        setState(() {
          currentSyncingModule = mod;
          progress[mod] = 0;
          syncedCount[mod] = 0;
          totalCount[mod] = 0;
          syncedStatus[mod] = false;
        });

        List<dynamic> list = [];

        if (mod == "Item") {
          list = await ItemApi.fetchAndStoreItems(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "Customer") {
          list = await CustomerApi.fetchAndStoreCustomers(password: password);
        } else if (mod == "Warehouse") {
          list = await WarehouseApi.fetchAndStoreWarehouses(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "UOM") {
          list = await UomApi.fetchAndStoreUoms(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "UOM Group") {
          list = await UomGroupApi.fetchAndStoreUomGroups(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "Price List") {
          list = await PriceListApi.fetchAndStorePriceLists(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "Item Pricing") {
          list = await ItemPricingApi.fetchAndStoreItemPricing(userCode: userCode, password: password, deviceID: deviceID);
        } else if (mod == "Visit Plan") {
          list = await VisitPlanApi.fetchAndStoreVisitPlans(password: password);
        } else if (mod == "Sale Summary") {
          list = await SaleSummaryApi.fetchAndStoreSaleSummary(password: password);
        } else if (mod == "Reason") {
          list = await ReasonApi.fetchAndStoreReasons(password: password);
        }

        await _updateProgress(mod, list.length);
        await _saveSyncStatus(mod, list.length);

        setState(() => syncedStatus[mod] = true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sync completed successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ SYNC ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
          currentSyncingModule = "";
        });
      }
    }
  }

  /// CLEAR ALL LOCAL DATA
  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Clear Local Data"),
        content: const Text("Are you sure you want to remove all local stored data?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => isSyncing = true);
    try {
      await ItemApi.clearLocalItems();
      await CustomerApi.clearLocalCustomers();
      await WarehouseApi.clearLocalWarehouses();
      await UomApi.clearLocalUoms();
      await UomGroupApi.clearLocalUomGroups();
      await PriceListApi.clearLocalPriceLists();
      await ItemPricingApi.clearLocalItemPricing();
      await VisitPlanApi.clearLocalVisitPlans();
      await SaleSummaryApi.clearLocalSaleSummary();
      await ReasonApi.clearLocalReasons();

      await _resetSyncStatus();

      for (var module in modules) {
        progress[module] = 0;
        syncedCount[module] = 0;
        totalCount[module] = 0;
        syncedStatus[module] = false;
        lastSyncTimes[module] = "-";
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All local data cleared"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ CLEAR ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isSyncing = false);
      }
    }
  }

  /// UPDATE PROGRESS
  Future<void> _updateProgress(String mod, int total) async {
    totalCount[mod] = total;
    if (total == 0) {
      setState(() => progress[mod] = 1);
      return;
    }
    for (int i = 0; i < total; i++) {
      await Future.delayed(const Duration(milliseconds: 5));
      setState(() {
        syncedCount[mod] = i + 1;
        progress[mod] = (i + 1) / total;
      });
    }
  }

  Widget syncCard(String title) {
    final completed = syncedStatus[title] ?? false;
    final current = syncedCount[title] ?? 0;
    final total = totalCount[title] ?? 0;
    final lastTime = lastSyncTimes[title] ?? "-";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: completed ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isSyncing ? null : () => syncModule(title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: completed ? Colors.green.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed ? Icons.check_circle : Icons.sync,
                  color: completed ? Colors.green : Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Last: $lastTime",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (completed)
                      Text(
                        "Synced successfully ($total records)",
                        style: const TextStyle(
                          color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress[title],
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            total > 0 ? "$current / $total synced" : "Ready to sync",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSyncing,
      onPopInvokedWithResult: (didPop, result) {
        if (isSyncing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please wait until sync is completed"),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            "Sync Master Data",
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: !isSyncing,
          actions: [
            IconButton(
              tooltip: "Sync All",
              onPressed: isSyncing ? null : () => syncModule("Sync All"),
              icon: const Icon(Icons.sync),
            ),
            IconButton(
              tooltip: "Clear Local Data",
              onPressed: isSyncing ? null : _clearAllData,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
                ],
              ),
              child: Row(
                children: [
                  if (isSyncing)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (isSyncing) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSyncing ? "Syncing $currentSyncingModule..." : "Tap any module to sync data manually",
                      style: TextStyle(
                        color: isSyncing ? Colors.blue : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: visibleModules.length,
                itemBuilder: (context, index) {
                  return syncCard(visibleModules[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}