import 'package:flutter/material.dart';
import '/api/get_saleorderlist_api.dart'; // Pointing to your API file name

class SaleOrderListingPage extends StatefulWidget {
  const SaleOrderListingPage({super.key});

  @override
  State<SaleOrderListingPage> createState() => _SaleOrderListingPageState();
}

/// =============================================================
/// INTERNAL GROUPING MODEL
/// =============================================================
class GroupedSaleOrder {
  final int docEntry;
  final SaleListingResult header;
  final List<SaleListingResult> lines;

  GroupedSaleOrder({
    required this.docEntry,
    required this.header,
    required this.lines,
  });
}

class _SaleOrderListingPageState extends State<SaleOrderListingPage> {
  // We manage Grouped Sales Orders instead of flat raw rows
  List<GroupedSaleOrder> allOrders = [];
  List<GroupedSaleOrder> filteredOrders = [];
  List<GroupedSaleOrder> displayedOrders = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = "";

  // Pagination configs
  final int pageSize = 15; // Grouped documents take more space, so smaller page sizing works better
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String _selectedStatus = "All";

  final Map<String, String> _statusOptions = {
    "All": "All Statuses",
    "Draft": "Draft",
    "Approved": "Approved",
    "Rejected": "Rejected",
    "Cancelled": "Cancelled",
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, 1);
    _selectedToDate = now;

    _fetchLiveSaleOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatApiDate(DateTime? date) {
    if (date == null) return "2000-01-01";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// =============================================================
  /// HELPER ENGINE: COMBINES MULTIPLE API ROWS INTO REAL DOCUMENTS
  /// =============================================================
  List<GroupedSaleOrder> _groupRowsByDocEntry(List<SaleListingResult> flatRows) {
    final Map<int, List<SaleListingResult>> groupedLines = {};
    final Map<int, SaleListingResult> orderHeaders = {};

    for (var row in flatRows) {
      // Fallback safely to a unique key if DocEntry is missing
      final int key = row.docEntry ?? row.hashCode;

      if (!groupedLines.containsKey(key)) {
        groupedLines[key] = [];
        orderHeaders[key] = row; // Take first occurrence as parent document header details
      }
      groupedLines[key]!.add(row);
    }

    return groupedLines.entries.map((entry) {
      return GroupedSaleOrder(
        docEntry: entry.key,
        header: orderHeaders[entry.key]!,
        lines: entry.value,
      );
    }).toList();
  }

  /// =============================================================
  /// FETCH & CONVERT DATA STREAM
  /// =============================================================
  Future<void> _fetchLiveSaleOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      final flatResults = await SaleOrderApi.fetchSaleOrders(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e",
        fromDate: _formatApiDate(_selectedFromDate),
        toDate: _formatApiDate(_selectedToDate),
        status: _selectedStatus,
      );

      // Transform raw rows into structured commercial documents
      final structuredOrders = _groupRowsByDocEntry(flatResults);

      setState(() {
        allOrders = structuredOrders;
        filteredOrders = structuredOrders;
        currentPage = 1;
        displayedOrders = _paginate(filteredOrders);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<GroupedSaleOrder> _paginate(List<GroupedSaleOrder> items) {
    final end = (pageSize * currentPage);
    if (end >= items.length) return items;
    return items.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoadingMore) {
      _loadMoreRows();
    }
  }

  Future<void> _loadMoreRows() async {
    if (displayedOrders.length >= filteredOrders.length) return;

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));
    currentPage++;

    setState(() {
      displayedOrders = _paginate(filteredOrders);
      isLoadingMore = false;
    });
  }

  /// =============================================================
  /// GLOBAL DEEP TEXT FILTER SEARCH ENGINE
  /// =============================================================
  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allOrders.where((order) {
      final h = order.header;

      final matchHeader = (h.docEntry?.toString() ?? "").toLowerCase().contains(searchQuery) ||
          (h.cardCode ?? "").toLowerCase().contains(searchQuery) ||
          (h.cardName ?? "").toLowerCase().contains(searchQuery) ||
          (h.numAtCard ?? "").toLowerCase().contains(searchQuery) ||
          (h.uOwner ?? "").toLowerCase().contains(searchQuery);

      // Check item definitions inside any of its children line items
      final matchLines = order.lines.any((line) =>
      (line.itemCode ?? "").toLowerCase().contains(searchQuery) ||
          (line.dscription ?? "").toLowerCase().contains(searchQuery));

      return matchHeader || matchLines;
    }).toList();

    setState(() {
      filteredOrders = filtered;
      currentPage = 1;
      displayedOrders = _paginate(filteredOrders);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? (_selectedFromDate ?? DateTime.now()) : (_selectedToDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = picked;
        } else {
          _selectedToDate = picked;
        }
      });
    }
  }

  Widget _buildStatusBadge(String? status, {bool isSync = false}) {
    String label = status ?? "-";
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;

    if (isSync) {
      if (label == "I") {
        label = "Synced";
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
      } else {
        label = "Pending Sync";
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
      }
    } else {
      switch (label) {
        case "D":
          label = "Draft";
          bgColor = Colors.black87;
          textColor = Colors.white;
          break;
        case "I":
          label = "Approved";
          bgColor = Colors.green.shade50;
          textColor = Colors.green.shade700;
          break;
        case "R":
          label = "Rejected";
          bgColor = Colors.purple.shade50;
          textColor = Colors.purple.shade700;
          break;
        case "S":
          label = "Sync to SAP";
          bgColor = Colors.blue.shade50;
          textColor = Colors.blue.shade700;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  /// =============================================================
  /// REAL COMMERCIAL DOCUMENT CARD COMPONENT (GROUPED ITEM ENGINE)
  /// =============================================================
  Widget orderDocumentCard(GroupedSaleOrder order) {
    final h = order.header;
    final String formattedDate = h.docDate != null ? h.docDate!.toIso8601String().split('T')[0] : "-";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),

          // --- HEADER: TOP SECTION OF REAL DOCUMENT SYSTEM ---
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order ID: #${h.docEntry ?? '-'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey),
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(h.appStatus ?? h.docStatus),
                      const SizedBox(width: 6),
                      Text(
                        "\$${h.docTotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 12, thickness: 1),

              // Customer Core Identity Row
              Text(
                "${h.cardCode ?? '-'}  |  ${h.cardName ?? 'Unknown Customer'}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 6),

              // Multi-column Header Meta Data Info Matrix
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 2,
                ),
                children: [
                  _docHeaderMetaItem(Icons.calendar_today, "Date: $formattedDate"),
                  _docHeaderMetaItem(Icons.local_shipping, "Delivery: ${h.uDeliveryTime ?? '-'}"),
                  _docHeaderMetaItem(Icons.payment, "Payment: ${h.uPaymentMethod ?? '-'}"),
                  _docHeaderMetaItem(Icons.badge, "Owner: ${h.uOwner ?? '-'}"),
                ],
              ),
            ],
          ),

          // --- ROW DETAIL CONTENT: EXPANDABLE ITEMIZED TABLE ---
          children: [
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Specific Extended Subheading Variables
                  _documentSectionHeader("DOCUMENT LOGISTICS"),
                  _documentDetailRow("Customer Address", h.address ?? "-"),
                  _documentDetailRow("PO/Ref Number", h.numAtCard ?? "-"),
                  _documentDetailRow("Remarks / Comments", h.comments ?? "-"),
                  Row(
                    children: [
                      const SizedBox(width: 120, child: Text("SAP Sync Status:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                      _buildStatusBadge(h.sapSyncStatus, isSync: true),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _documentSectionHeader("ITEMIZED LINE ROWS (${order.lines.length})"),

                  // Clean, real-document style table list view block layout
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.lines.length,
                    separatorBuilder: (context, index) => const Divider(height: 12, color: Colors.grey),
                    itemBuilder: (context, idx) {
                      final item = order.lines[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Descriptor Title Line Block
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.blueGrey.shade100,
                                child: Text("${item.lineNum ?? (idx + 1)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${item.itemCode} - ${item.dscription ?? 'No Description'}",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Technical Warehouse Data Line
                          Padding(
                            padding: const EdgeInsets.only(left: 28, bottom: 4),
                            child: Text(
                              "WhsCode: ${item.whsCode ?? '-'}   |   Ocr Codes: ${item.ocrCode ?? '-'}/${item.ocrCode2 ?? '-'}/${item.ocrCode3 ?? '-'}/${item.ocrCode4 ?? '-'}",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ),

                          // Calculation metrics line block matching general ledger documents
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item.quantity?.toStringAsFixed(2) ?? '0.00'} ${item.uomCode}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                Text("Price: \$${item.price?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontSize: 12)),
                                Text("Disc: \$${item.discountAmt?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  "Total: \$${item.lineTotal?.toStringAsFixed(2) ?? '0.00'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const Divider(thickness: 1, color: Colors.black26),

                  // FINANCIAL RECEIPT SUMMARY CARD BLOCK
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          _financialSummaryRow("Sub Total Amount:", "\$${h.subTotal.toStringAsFixed(2)}"),
                          _financialSummaryRow("Discount (${h.discPrcnt.toStringAsFixed(1)}%):", "-\$${h.discSum.toStringAsFixed(2)}"),
                          const Divider(height: 8),
                          _financialSummaryRow(
                            "Grand Total:",
                            "\$${h.docTotal.toStringAsFixed(2)}",
                            isBoldTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _docHeaderMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54))),
      ],
    );
  }

  Widget _documentSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1976D2), letterSpacing: 0.5),
      ),
    );
  }

  Widget _documentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _financialSummaryRow(String label, String value, {bool isBoldTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBoldTotal ? 13 : 12,
              fontWeight: isBoldTotal ? FontWeight.bold : FontWeight.normal,
              color: isBoldTotal ? Colors.black : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBoldTotal ? 14 : 12,
              fontWeight: isBoldTotal ? FontWeight.bold : FontWeight.w600,
              color: isBoldTotal ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// MAIN UI ROOT BUILDER
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sales Order Documents",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLiveSaleOrders),
        ],
      ),
      body: Column(
        children: [
          /// 🛠 Parameter Filter Options Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text("From Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ),
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedFromDate == null ? "Select Date" : _selectedFromDate!.toIso8601String().split('T')[0],
                                    style: TextStyle(fontSize: 13, color: _selectedFromDate == null ? Colors.grey : Colors.black87),
                                  ),
                                  const Icon(Icons.calendar_month, size: 18, color: Color(0xFF1976D2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text("To Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedToDate == null ? "Select Date" : _selectedToDate!.toIso8601String().split('T')[0],
                                    style: TextStyle(fontSize: 13, color: _selectedToDate == null ? Colors.grey : Colors.black87),
                                  ),
                                  const Icon(Icons.calendar_month, size: 18, color: Color(0xFF1976D2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text("Order Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                                onChanged: (String? newValue) {
                                  if (newValue != null) setState(() => _selectedStatus = newValue);
                                },
                                items: _statusOptions.entries.map((entry) {
                                  return DropdownMenuItem<String>(value: entry.key, child: Text(entry.value));
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _fetchLiveSaleOrders,
                      icon: const Icon(Icons.search, size: 18, color: Colors.white),
                      label: const Text("Search", style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Local Results Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: "Search local documents or items...",
                prefixIcon: const Icon(Icons.find_in_page),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          /// Document Metadata Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Unique Documents: ${filteredOrders.length}",
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 2),

          /// Asynchronous Document List View
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedOrders.isEmpty
                ? const Center(child: Text("No documents found", style: TextStyle(fontSize: 15)))
                : ListView.builder(
              controller: _scrollController,
              itemCount: displayedOrders.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < displayedOrders.length) {
                  return orderDocumentCard(displayedOrders[index]);
                }
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}