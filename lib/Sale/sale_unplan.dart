import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_customer_api.dart' as api;
import '../api/get_item_api.dart' as itemApi;
import 'sale_unplan_controller.dart';
import 'models/sale_order_model.dart';

class SaleUnplanPage extends StatefulWidget {
  const SaleUnplanPage({super.key});

  @override
  State<SaleUnplanPage> createState() => _SaleUnplanPageState();
}

class _SaleUnplanPageState extends State<SaleUnplanPage> {
  final SaleController controller = SaleController();

  int _step = 1;
  String searchCustomer = "";
  String searchItem = "";
  api.Customer? selectedCustomer;

  List<api.Customer> customers = [];
  bool isLoadingCustomer = true;

  List<itemApi.Item> items = [];
  bool isLoadingItem = true;

  final TextEditingController remarkController = TextEditingController();

  // Track expanded index for single expand
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadItems();
  }

  Future<void> _loadCustomers() async {
    setState(() => isLoadingCustomer = true);
    customers = await api.CustomerApi.getLocalCustomers();
    setState(() => isLoadingCustomer = false);
  }

  Future<void> _loadItems() async {
    setState(() => isLoadingItem = true);
    items = await itemApi.ItemApi.getLocalItems();
    setState(() => isLoadingItem = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step > 1) {
          setState(() => _step--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Sale Order", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue.shade700,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _step == 1
                  ? buildCustomerStep()
                  : _step == 2
                  ? buildItemStep()
                  : buildSummaryStep(),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- Customer Step ----------------
  Widget buildCustomerStep() {
    if (isLoadingCustomer) return const Center(child: CircularProgressIndicator());

    List<api.Customer> filtered = customers.where((c) {
      if (searchCustomer == "*") return true;
      return c.cardName.toLowerCase().contains(searchCustomer.toLowerCase()) ||
          c.cardCode.toLowerCase().contains(searchCustomer.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (selectedCustomer != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer ID: ${selectedCustomer!.cardCode}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Name: ${selectedCustomer!.cardName}", style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Address: ${selectedCustomer!.fullAddress}", style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Phone No.: ${selectedCustomer!.tel1}", style: const TextStyle(color: Colors.black)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCustomer = null;
                          controller.selectedCustomer = null;
                        });
                      },
                      child: const Text("Change", style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (selectedCustomer == null) ...[
          TextField(
            decoration: InputDecoration(
              hintText: "Search customer...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => searchCustomer = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                api.Customer c = filtered[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text("${c.cardName} (${c.cardCode})", style: const TextStyle(color: Colors.black)),
                    subtitle: Text(c.fullAddress, style: const TextStyle(color: Colors.black)),
                    onTap: () {
                      setState(() {
                        selectedCustomer = c;
                        controller.selectCustomer(c);
                        _step = 2;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ]
      ],
    );
  }

  /// ---------------- Item Step ----------------
  Widget buildItemStep() {
    if (isLoadingItem) return const Center(child: CircularProgressIndicator());

    List<itemApi.Item> filteredItems = items.where((i) {
      if (searchItem == "*") return true;
      return i.itemName.toLowerCase().contains(searchItem.toLowerCase()) ||
          i.itemCode.toLowerCase().contains(searchItem.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Customer Header
        Card(
          color: Colors.white,
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: Text("${selectedCustomer?.cardName ?? ""} (${selectedCustomer?.cardCode ?? ""})"),
            subtitle: Text(selectedCustomer?.fullAddress ?? ""),
          ),
        ),
        const SizedBox(height: 8),
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: "Search item...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => searchItem = val),
        ),
        const SizedBox(height: 8),
        // Search Results (Expandable, single expanded)
        if (searchItem.isNotEmpty || searchItem == "*")
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                itemApi.Item item = filteredItems[index];
                bool isExpanded = expandedIndex == index;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("${item.itemName} (${item.itemCode})"),
                        subtitle: Text("Price: \$${item.sellingPrice.toStringAsFixed(2)} | UOM: ${item.invUoMCode}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () {
                                setState(() {
                                  expandedIndex = isExpanded ? null : index;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  controller.addItem(SaleItem(
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
                                  searchItem = "";
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Group: ${item.itemGroupName}"),
                              Text("SubGroup1: ${item.subGroupDes}"),
                              Text("SubGroup2: ${item.subGroup2Des}"),
                              Text("Manufacturer: ${item.manufacturerDes}"),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // Selected Items
        Expanded(
          child: ListView.builder(
            itemCount: controller.selectedItems.length,
            itemBuilder: (context, index) {
              SaleItem item = controller.selectedItems[index];
              double total = item.price * item.qty;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text("${item.itemCode} - ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Price: \$${item.price.toStringAsFixed(2)}"),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setState(() => item.qty = item.qty > 1 ? item.qty - 1 : 1),
                              ),
                              Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => setState(() => item.qty++),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(item.uom, overflow: TextOverflow.visible)), // full UOM
                        ],
                      ),
                      Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => controller.removeItem(item)),
                  ),
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          onPressed: controller.selectedItems.isEmpty ? null : () => setState(() => _step = 3),
          child: const Text("Confirm Items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  /// ---------------- Summary Step ----------------
  Widget buildSummaryStep() {
    double promoTotal = controller.runPromotion();
    double subtotal = controller.subtotal;
    double discountAmt = subtotal - promoTotal;

    TextStyle labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
    TextStyle valueStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.black),
                    title: Text("${selectedCustomer?.cardName ?? ""} (${selectedCustomer?.cardCode ?? ""})"),
                    subtitle: Text(selectedCustomer?.fullAddress ?? ""),
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.selectedItems.map((item) {
                  double total = item.price * item.qty;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      title: Text("${item.itemCode} - ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Price: \$${item.price.toStringAsFixed(2)}"),
                          Text("Qty: ${item.qty}"),
                          Text(item.uom), // full UOM only
                          Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Subtotal", style: labelStyle), Text("\$${subtotal.toStringAsFixed(2)}", style: valueStyle)],
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Discount Amount", style: labelStyle), Text("\$${discountAmt.toStringAsFixed(2)}", style: valueStyle)],
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Doc Total", style: labelStyle), Text("\$${promoTotal.toStringAsFixed(2)}", style: valueStyle)],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: remarkController,
                          decoration: const InputDecoration(hintText: "Remark", border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
              onPressed: () {
                setState(() => promoTotal = controller.runPromotion());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Promotion Applied!")));
              },
              child: const Text("Run Promotion", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
              onPressed: saveOrder,
              child: const Text("Save Order", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// ---------------- Save to Local Storage ----------------
  Future<void> saveOrder() async {
    if (selectedCustomer == null || controller.selectedItems.isEmpty) return;

    final now = DateTime.now();
    final invoiceNumber = "${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}";
    final order = {
      "invoiceNumber": invoiceNumber,
      "createDate": now.toIso8601String(),
      "createBy": "userLogin", // replace with actual login user
      "docStatus": "Pending",
      "customer": {
        "code": selectedCustomer!.cardCode,
        "name": selectedCustomer!.cardName,
        "address": selectedCustomer!.fullAddress,
        "phone": selectedCustomer!.tel1,
      },
      "remark": remarkController.text,
      "items": controller.selectedItems
          .map((i) => {
        "itemCode": i.itemCode,
        "name": i.name,
        "price": i.price,
        "qty": i.qty,
        "uom": i.uom,
        "itemGroupName": i.itemGroupName,
        "subGroupDes": i.subGroupDes,
        "subGroup2Des": i.subGroup2Des,
        "manufacturerDes": i.manufacturerDes,
      })
          .toList(),
    };

    final prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList("localOrders") ?? [];
    existing.add(jsonEncode(order));
    await prefs.setStringList("localOrders", existing);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order saved locally!")));
    setState(() {
      _step = 1;
      selectedCustomer = null;
      controller.selectedItems.clear();
      remarkController.clear();
      searchCustomer = "";
      searchItem = "";
      expandedIndex = null;
    });
  }
}