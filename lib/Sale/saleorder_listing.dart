import 'package:flutter/material.dart';
import '/api/get_saleorderlist_api.dart'; // Updated to point to your new API file name

class SaleOrderListingPage extends StatefulWidget {
  const SaleOrderListingPage({super.key});

  @override
  State<SaleOrderListingPage> createState() => _SaleOrderListingPageState();
}

class _SaleOrderListingPageState extends State<SaleOrderListingPage> {
  List<SaleListingResult> allRows = [];
  List<SaleListingResult> filteredRows = [];
  List<SaleListingResult> displayedRows = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = "";

  final int pageSize = 30;
  int currentPage = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLiveSaleOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// =============================================================
  /// FETCH LIVE DATA FROM NETWORK (NO LOCAL STORAGE CACHING)
  /// =============================================================
  Future<void> _fetchLiveSaleOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Calls your single flat class API service handler
      final results = await SaleOrderApi.fetchSaleOrders(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e",
        fromDate: "2026-01-01",
        toDate: "2026-12-31",
        status: "Open",
      );

      setState(() {
        allRows = results;
        filteredRows = results;
        currentPage = 1;
        displayedRows = _paginate(filteredRows);
        isLoading = false;
      });

      print("✅ UI Loaded Sale Order Rows: ${results.length}");
    } catch (e) {
      print("❌ LIVE FETCH ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// =============================================================
  /// PAGINATION PROCESSING
  /// =============================================================
  List<SaleListingResult> _paginate(List<SaleListingResult> items) {
    final end = (pageSize * currentPage);
    if (end >= items.length) {
      return items;
    }
    return items.sublist(0, end);
  }

  /// =============================================================
  /// INFINITE SCROLL LISTENER
  /// =============================================================
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore) {
      _loadMoreRows();
    }
  }

  /// =============================================================
  /// LOAD MORE ROWS PROCESSING
  /// =============================================================
  Future<void> _loadMoreRows() async {
    if (displayedRows.length >= filteredRows.length) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    currentPage++;

    setState(() {
      displayedRows = _paginate(filteredRows);
      isLoadingMore = false;
    });
  }

  /// =============================================================
  /// CLIENT-SIDE SEARCH FILTER
  /// =============================================================
  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allRows.where((row) {
      final cardCode = (row.cardCode ?? "").toLowerCase();
      final cardName = (row.cardName ?? "").toLowerCase();
      final numAtCard = (row.numAtCard ?? "").toLowerCase();
      final itemCode = (row.itemCode ?? "").toLowerCase();
      final description = (row.dscription ?? "").toLowerCase();

      return cardCode.contains(searchQuery) ||
          cardName.contains(searchQuery) ||
          numAtCard.contains(searchQuery) ||
          itemCode.contains(searchQuery) ||
          description.contains(searchQuery);
    }).toList();

    setState(() {
      filteredRows = filtered;
      currentPage = 1;
      displayedRows = _paginate(filteredRows);
    });
  }

  /// =============================================================
  /// FLAT TRANSACTION CARD UI COMPONENT
  /// =============================================================
  Widget orderRowCard(SaleListingResult row) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.description, color: Color(0xFF1976D2)),
        ),
        title: Text(
          row.cardName ?? "Unknown Customer",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "PO/Ref: ${row.numAtCard ?? '-'} | Item: ${row.itemCode ?? '-'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const Divider(),
          _detailRow("Card Code", row.cardCode ?? "-"),
          _detailRow("Doc Date", row.docDate != null ? row.docDate!.toIso8601String().split('T')[0] : "-"),
          _detailRow("Status", row.appStatus ?? "-"),
          _detailRow("Item Desc", row.dscription ?? "-"),
          _detailRow("Quantity", row.quantity != null ? row.quantity!.toStringAsFixed(2) : "0.00"),
          _detailRow("UoM", row.uomCode),
          _detailRow("Price", row.price != null ? "\$${row.price!.toStringAsFixed(2)}" : "\$0.00"),
          _detailRow("Line Total", row.lineTotal != null ? "\$${row.lineTotal!.toStringAsFixed(2)}" : "\$0.00"),
          _detailRow("Doc Total", "\$${row.docTotal.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  /// =============================================================
  /// TRANSACTION DETAIL ROW LAYOUT
  /// =============================================================
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(fontSize: 13),
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
          "Sales Order Flat List",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLiveSaleOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          /// Search Input Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: "Search by customer, PO, item code...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// Metadata Summary Display Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Record Rows: ${filteredRows.length}",
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
            ),
          ),
          const SizedBox(height: 6),

          /// Primary Asynchronous Content List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedRows.isEmpty
                ? const Center(
              child: Text("No records found", style: TextStyle(fontSize: 15)),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: displayedRows.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < displayedRows.length) {
                  return orderRowCard(displayedRows[index]);
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
