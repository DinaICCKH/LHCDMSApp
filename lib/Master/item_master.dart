import 'package:flutter/material.dart';
import '/api/get_item_api.dart';

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

  /// =========================
  /// LOAD LOCAL ITEMS
  /// =========================
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

  /// =========================
  /// PAGINATION
  /// =========================
  List<Item> _paginate(List<Item> items) {
    final end = (pageSize * currentPage);

    if (end >= items.length) {
      return items;
    }

    return items.sublist(0, end);
  }

  /// =========================
  /// SCROLL LISTENER
  /// =========================
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore) {
      _loadMore();
    }
  }

  /// =========================
  /// LOAD MORE
  /// =========================
  Future<void> _loadMore() async {
    if (displayedItems.length >= filteredItems.length) {
      return;
    }

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

  /// =========================
  /// SEARCH
  /// =========================
  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allItems.where((item) {
      return item.itemCode.toLowerCase().contains(searchQuery) ||
          item.itemName.toLowerCase().contains(searchQuery) ||
          item.itemGroupName.toLowerCase().contains(searchQuery) ||
          (item.manufacturerDes ?? "")
              .toLowerCase()
              .contains(searchQuery) ||
          (item.subGroupDes ?? "")
              .toLowerCase()
              .contains(searchQuery) ||
          (item.itemBrandDes ?? "")
              .toLowerCase()
              .contains(searchQuery);
    }).toList();

    setState(() {
      filteredItems = filtered;

      currentPage = 1;

      displayedItems = _paginate(filteredItems);
    });
  }

  /// =========================
  /// ITEM CARD
  /// =========================
  Widget itemCard(Item item) {
    final imageUrl = (item.imageUrlServer ?? "").isNotEmpty
        ? "https://www.icckh.com${item.imageUrlServer}"
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),

        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
            imageUrl,
            width: 55,
            height: 55,
            fit: BoxFit.cover,

            /// BETTER IMAGE PERFORMANCE
            cacheWidth: 120,
            cacheHeight: 120,

            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.inventory_2,
                size: 40,
                color: Colors.grey,
              );
            },

            loadingBuilder: (
                context,
                child,
                progress,
                ) {
              if (progress == null) return child;

              return const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          )
              : const Icon(
            Icons.inventory_2,
            size: 40,
            color: Colors.grey,
          ),
        ),

        title: Text(
          item.itemName.isEmpty ? "-" : item.itemName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),

        subtitle: Text(
          "Code: ${item.itemCode}",
          style: const TextStyle(fontSize: 13),
        ),

        childrenPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 12,
        ),

        children: [
          _row("Group", item.itemGroupName),
          _row("Stock", item.onhand.toStringAsFixed(2)),
          _row("Available", item.available.toStringAsFixed(2)),
          _row("Status", item.status),
          _row("Brand", item.itemBrandDes ?? item.itemBrand),
          _row(
            "Price",
            "\$${item.sellingPrice.toStringAsFixed(2)}",
          ),
        ],
      ),
    );
  }

  /// =========================
  /// DETAIL ROW
  /// =========================
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Item Master",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
      ),

      body: Column(
        children: [
          /// ================= SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filter,

              decoration: InputDecoration(
                hintText: "Search item...",

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

          /// ================= TOTAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total: ${filteredItems.length} items",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// ================= LIST
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : displayedItems.isEmpty
                ? const Center(
              child: Text(
                "No items found",
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              controller: _scrollController,

              itemCount: displayedItems.length +
                  (isLoadingMore ? 1 : 0),

              itemBuilder: (context, index) {
                if (index < displayedItems.length) {
                  return itemCard(
                    displayedItems[index],
                  );
                }

                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(),
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