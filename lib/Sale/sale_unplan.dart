import 'package:flutter/material.dart';
import 'sale_unplan_controller.dart';
import 'models/sale_order_model.dart';

class SaleUnplanPage extends StatefulWidget {
  const SaleUnplanPage({super.key});

  @override
  State<SaleUnplanPage> createState() => _SaleUnplanPageState();
}

class _SaleUnplanPageState extends State<SaleUnplanPage> {
  final SaleController controller = SaleController();
  int _step = 1; // 1=Customer, 2=Item, 3=Summary
  String searchCustomer = "";
  String searchItem = "";
  Customer? selectedCustomer;

  final List<Customer> customers = [
    Customer(code: "C001", name: "John Doe", phone: "012345678", address: "Phnom Penh"),
    Customer(code: "C002", name: "Jane Smith", phone: "098765432", address: "Siem Reap"),
    Customer(code: "C003", name: "Michael Lee", phone: "011223344", address: "Battambang"),
  ];

  final List<SaleItem> items = [
    SaleItem(itemCode: "I001", name: "Apple", price: 1.5),
    SaleItem(itemCode: "I002", name: "Orange", price: 2.0),
    SaleItem(itemCode: "I003", name: "Mango", price: 2.5),
    SaleItem(itemCode: "I004", name: "Banana", price: 1.2),
    SaleItem(itemCode: "I005", name: "Pineapple", price: 3.0),
  ];

  final List<String> uomList = ["PCS", "KG", "Box"];
  final TextEditingController remarkController = TextEditingController();

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

  /// ---------------- CUSTOMER STEP ----------------
  Widget buildCustomerStep() {
    List<Customer> filtered = customers
        .where((c) =>
    c.name.toLowerCase().contains(searchCustomer.toLowerCase()) ||
        c.code.toLowerCase().contains(searchCustomer.toLowerCase()))
        .toList();

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
                  Text("Customer ID: ${selectedCustomer!.code}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Name: ${selectedCustomer!.name}", style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Address: ${selectedCustomer!.address}", style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Phone No.: ${selectedCustomer!.phone}", style: const TextStyle(color: Colors.black)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCustomer = null;
                            controller.selectedCustomer = null;
                          });
                        },
                        child: const Text("Change", style: TextStyle(color: Colors.orange))),
                  )
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => searchCustomer = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                Customer c = filtered[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text("${c.name} (${c.code})", style: const TextStyle(color: Colors.black)),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 4),
                            Text(c.phone, style: const TextStyle(color: Colors.black))
                          ]),
                          Row(children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(c.address, style: const TextStyle(color: Colors.black))
                          ])
                        ]),
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

  /// ---------------- ITEM STEP ----------------
  Widget buildItemStep() {
    List<SaleItem> filteredItems = items
        .where((i) =>
    i.name.toLowerCase().contains(searchItem.toLowerCase()) ||
        i.itemCode.toLowerCase().contains(searchItem.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Customer Info (read-only)
        Card(
          color: Colors.white,
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: Text("${selectedCustomer?.name ?? ""} (${selectedCustomer?.code ?? ""})",
                style: const TextStyle(color: Colors.black)),
            subtitle: Text(selectedCustomer?.address ?? "", style: const TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(height: 8),
        // Item Search
        TextField(
          decoration: InputDecoration(
            hintText: "Search item...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => searchItem = val),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              // Suggestion List
              if (searchItem.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      SaleItem item = filteredItems[index];
                      return ListTile(
                        title: Text("${item.name} (${item.itemCode})", style: const TextStyle(color: Colors.black)),
                        subtitle: Text("\$${item.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              controller.addItem(SaleItem(
                                  itemCode: item.itemCode,
                                  name: item.name,
                                  price: item.price,
                                  qty: 1,
                                  uom: uomList[0]));
                              searchItem = "";
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              // Selected Items with editable Qty & horizontal scroll
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
                        title: Text("${item.itemCode} - ${item.name}",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text("Price: \$${item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.black)),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            if (item.qty > 1) item.qty--;
                                          });
                                        },
                                      ),
                                      Text("${item.qty}",
                                          style: const TextStyle(
                                              color: Colors.black, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                        onPressed: () {
                                          setState(() {
                                            item.qty++;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  DropdownButton<String>(
                                    value: item.uom,
                                    items: uomList
                                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => item.uom = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Total: \$${total.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          onPressed: controller.selectedItems.isEmpty ? null : () => setState(() => _step = 3),
          child: const Text("Confirm Items",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  /// ---------------- SUMMARY STEP ----------------
  Widget buildSummaryStep() {
    double promoTotal = controller.runPromotion();
    double subtotal = controller.subtotal;
    double discountAmt = subtotal - promoTotal;

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
                    title: Text("${selectedCustomer?.name ?? ""} (${selectedCustomer?.code ?? ""})",
                        style: const TextStyle(color: Colors.black)),
                    subtitle: Text(selectedCustomer?.address ?? "", style: const TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 12),
                // Items (Qty & UOM read-only)
                ...controller.selectedItems.map((item) {
                  double total = item.price * item.qty;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      title: Text("${item.itemCode} - ${item.name}",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text("Price: \$${item.price.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.black)),
                                const SizedBox(width: 16),
                                Text("Qty: ${item.qty}", style: const TextStyle(color: Colors.black)),
                                const SizedBox(width: 16),
                                Text("UOM: ${item.uom}", style: const TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Total: \$${total.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                // Totals + Remark
                Card(
                  elevation: 1,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text("Subtotal"),
                        trailing: Text("\$${subtotal.toStringAsFixed(2)}"),
                      ),
                      ListTile(
                        title: const Text("Discount Amount"),
                        trailing: Text("\$${discountAmt.toStringAsFixed(2)}"),
                      ),
                      ListTile(
                        title: const Text("Doc Total", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text("\$${promoTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: remarkController,
                          decoration: const InputDecoration(
                            hintText: "Remark",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: () {
                setState(() {
                  promoTotal = controller.runPromotion();
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Promotion Applied!")));
              },
              child: const Text("Run Promotion", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Saved!")));
              },
              child: const Text("Save Order", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}