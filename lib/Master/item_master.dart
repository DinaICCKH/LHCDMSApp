import 'package:flutter/material.dart';
import '/api/get_item_api.dart';

/// =============================================================
/// ITEM MASTER DIRECTORY PAGE
/// =============================================================
class ItemMasterPage extends StatefulWidget {
  const ItemMasterPage({super.key});

  @override
  State<ItemMasterPage> createState() => _ItemMasterPageState();
}

class _ItemMasterPageState extends State<ItemMasterPage> {
  List<Item> allItems = [];
  List<Item> filteredItems = [];
  List<Item> displayedItems = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = "";

  final int pageSize = 30;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      final items = await ItemApi.getLocalItems();

      setState(() {
        allItems = items;
        filteredItems = items;
        currentPage = 1;
        displayedItems = _paginate(filteredItems);
        isLoading = false;
      });
      print("✅ UI Loaded Items: ${items.length}");
    } catch (e) {
      print("❌ LOAD ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Item> _paginate(List<Item> items) {
    final end = (pageSize * currentPage);
    if (end >= items.length) return items;
    return items.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (displayedItems.length >= filteredItems.length) return;

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    currentPage++;

    setState(() {
      displayedItems = _paginate(filteredItems);
      isLoadingMore = false;
    });
  }

  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allItems.where((item) {
      return item.itemCode.toLowerCase().contains(searchQuery) ||
          item.itemName.toLowerCase().contains(searchQuery) ||
          item.itemGroupName.toLowerCase().contains(searchQuery) ||
          (item.manufacturerDes ?? "").toLowerCase().contains(searchQuery) ||
          (item.subGroupDes ?? "").toLowerCase().contains(searchQuery) ||
          (item.itemBrandDes ?? "").toLowerCase().contains(searchQuery);
    }).toList();

    setState(() {
      filteredItems = filtered;
      currentPage = 1;
      displayedItems = _paginate(filteredItems);
    });
  }

  /// =============================================================
  /// REFINED MODERN ITEM DISPLAY CARD
  /// =============================================================
  Widget itemCard(Item item) {
    final imageUrl = (item.imageUrlServer ?? "").isNotEmpty
        ? "https://www.icckh.com${item.imageUrlServer}"
        : null;

    final bool isOutOfStock = item.onhand <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                cacheWidth: 150,
                cacheHeight: 150,
                errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, size: 26, color: Colors.grey.shade400),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade600),
                    ),
                  );
                },
              )
                  : Icon(Icons.inventory_2_rounded, size: 26, color: Colors.grey.shade400),
            ),
          ),
          title: Text(
            item.itemName.isEmpty ? "-" : item.itemName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.itemCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
                const Spacer(),
                Text(
                  "\$${item.sellingPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 0),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Clean Two-Column Grid Setup for Specifications
            Row(
              children: [
                Expanded(child: _infoBlock("Group Name", item.itemGroupName)),
                Expanded(child: _infoBlock("Brand / Tag", item.itemBrandDes ?? item.itemBrand)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _infoBlock(
                      "Stock Available",
                      item.onhand.toStringAsFixed(2),
                      textColor: isOutOfStock ? Colors.red.shade700 : const Color(0xFF334155),
                    )
                ),
                Expanded(child: _infoBlock("Reserved", item.available.toStringAsFixed(2))),
              ],
            ),
            const SizedBox(height: 12),

            // Status Tracking Row Layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Operating Status", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOutOfStock ? "OUT OF STOCK" : item.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? "-" : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor ?? const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  /// =============================================================
  /// MAIN APPLICATION INTERFACE TREE
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Calming light canvas background
      appBar: AppBar(
        title: const Text(
          "Item Master Directory",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Deeper premium corporate blue
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar Container
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E3A8A),
            child: TextField(
              onChanged: _filter,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search item code, brand, name...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Data Context Metric Counter bar
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Catalog Records",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${filteredItems.length} items",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),

          // Main Body Display List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
                : displayedItems.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_rounded, size: 48, color: Colors.black26),
                  SizedBox(height: 8),
                  Text("No inventory matches found", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: displayedItems.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < displayedItems.length) {
                  return itemCard(displayedItems[index]);
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}