import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/get_item_api.dart' as itemApi;
import 'models/customer_visit_model.dart';
import 'sale_visit_controller.dart';
import 'models/sale_order_model.dart';

class SaleFromVisitPage extends StatefulWidget {
  final CustomerVisit customer;

  const SaleFromVisitPage({super.key, required this.customer});

  @override
  State<SaleFromVisitPage> createState() => _SaleFromVisitPageState();
}

class _SaleFromVisitPageState extends State<SaleFromVisitPage> {
  final SaleVisitController controller = SaleVisitController();

  int _step = 2; // Step 2 = Item Selection, 3 = Cart Preview, 4 = Summary
  String searchItem = "";

  List<itemApi.Item> items = [];
  bool isLoadingItem = true;
  bool isSaving = false;

  final TextEditingController remarkController = TextEditingController();
  int? expandedIndex;

  File? imageFile;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    controller.selectCustomer(widget.customer);
    _loadItems();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request camera
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }

    // Request location
    if (!await Permission.location.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> _loadItems() async {
    setState(() => isLoadingItem = true);
    items = await itemApi.ItemApi.getLocalItems();
    setState(() => isLoadingItem = false);
  }

  /// ---------------- TAKE PHOTO ----------------
  Future<void> takePhoto() async {
    try {
      if (!await Permission.camera.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Camera permission required")));
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);

      if (picked != null) {
        if (!await Permission.location.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission required")));
          return;
        }

        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        setState(() {
          imageFile = File(picked.path);
          currentPosition = position;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Camera error: $e")));
    }
  }

  /// ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back if there are selected items
        if (controller.selectedItems.isNotEmpty) {
          bool exit = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Exit"),
              content: const Text(
                  "Your cart will be lost. Do you want to exit?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Exit")),
              ],
            ),
          );
          return exit;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title:
          const Text("Sale From Visit", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue.shade700,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _step == 2
                  ? buildItemStep()
                  : _step == 3
                  ? buildCartPreviewStep()
                  : buildSummaryStep(),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- ITEM SELECTION STEP ----------------
  Widget buildItemStep() {
    if (isLoadingItem) return const Center(child: CircularProgressIndicator());

    List<itemApi.Item> filteredItems = items.where((i) {
      if (searchItem == "*") return true;
      return i.itemName.toLowerCase().contains(searchItem.toLowerCase()) ||
          i.itemCode.toLowerCase().contains(searchItem.toLowerCase());
    }).toList();

    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title:
            Text("${widget.customer.cardName} (${widget.customer.cardCode})"),
            subtitle: Text(widget.customer.fullAddress.toString()),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: "Search item...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => searchItem = val),
        ),
        const SizedBox(height: 8),
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
                      subtitle: Text(
                          "Price: \$${item.sellingPrice.toStringAsFixed(2)} | UOM: ${item.invUoMCode}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more),
                            onPressed: () {
                              setState(() {
                                expandedIndex = isExpanded ? null : index;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              final existingIndex = controller.selectedItems
                                  .indexWhere((e) => e.itemCode == item.itemCode);
                              if (existingIndex >= 0) {
                                setState(() =>
                                controller.selectedItems[existingIndex].qty++);
                              } else {
                                setState(() => controller.selectedItems.add(SaleItem(
                                  itemCode: item.itemCode,
                                  name: item.itemName,
                                  price: item.sellingPrice,
                                  qty: 1,
                                  uom: item.invUoMCode,
                                  itemGroupName: item.itemGroupName,
                                  subGroupDes: item.subGroupDes,
                                  subGroup2Des: item.subGroup2Des,
                                  manufacturerDes: item.manufacturerDes,
                                )));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          onPressed: controller.selectedItems.isEmpty
              ? null
              : () => setState(() => _step = 3),
          child: const Text("Preview Cart",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  /// ---------------- CART PREVIEW STEP ----------------
  Widget buildCartPreviewStep() {
    if (controller.selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Cart is empty."),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () => setState(() => _step = 2),
              child: const Text("Back to Items"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: controller.selectedItems.length,
            itemBuilder: (context, index) {
              final item = controller.selectedItems[index];
              double total = item.price * item.qty;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text("${item.itemCode} - ${item.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price: \$${item.price.toStringAsFixed(2)}"),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => setState(() =>
                              item.qty = item.qty > 1 ? item.qty - 1 : 1)),
                          Text("${item.qty}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.green),
                              onPressed: () => setState(() => item.qty++)),
                        ],
                      ),
                      Text("Total: \$${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () => setState(() => _step = 2),
                child: const Text("Back to Items"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () => setState(() => _step = 4),
                child: const Text("Next: Summary"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ---------------- SUMMARY STEP ----------------
  Widget buildSummaryStep() {
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
                    title: Text(
                        "${widget.customer.cardName} (${widget.customer.cardCode})"),
                    subtitle: Text(
                        "${widget.customer.fullAddress}\nPhone: ${widget.customer.phone}"),
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.selectedItems.map((item) {
                  double total = item.price * item.qty;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      title: Text("${item.itemCode} - ${item.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Price: \$${item.price.toStringAsFixed(2)}"),
                          Text("Qty: ${item.qty}"),
                          Text(item.uom),
                          Text("Total: \$${total.toStringAsFixed(2)}",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
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
                        TextField(
                          controller: remarkController,
                          decoration: const InputDecoration(
                              hintText: "Remark", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        if (imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(imageFile!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        TextButton.icon(
                          onPressed: takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Take Photo"),
                        ),
                        if (currentPosition != null)
                          Text(
                              "Lat: ${currentPosition!.latitude}, Lng: ${currentPosition!.longitude}",
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          onPressed: saveOrder,
          child: isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Save Order",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  /// ---------------- SAVE ----------------
  Future<void> saveOrder() async {
    if (controller.selectedItems.isEmpty) return;

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();

    final order = {
      "customer": widget.customer.cardCode,
      "customerName": widget.customer.cardName,
      "fullAddress": widget.customer.fullAddress,
      "phone": widget.customer.phone,
      "items": controller.selectedItems
          .map((e) => {
        "itemCode": e.itemCode,
        "name": e.name,
        "qty": e.qty,
        "price": e.price,
        "uom": e.uom,
      })
          .toList(),
      "remark": remarkController.text,
      "image": imageFile?.path,
      "lat": currentPosition?.latitude,
      "lng": currentPosition?.longitude,
      "createDate": DateTime.now().toIso8601String(),
    };

    List<String> existing = prefs.getStringList("localOrders") ?? [];
    existing.add(jsonEncode(order));

    await prefs.setStringList("localOrders", existing);

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Saved Successfully")));

    Navigator.pop(context);
  }
}