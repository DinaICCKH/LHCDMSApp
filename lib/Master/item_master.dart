import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_item_api.dart';

class ItemMasterPage extends StatefulWidget {
  const ItemMasterPage({super.key});

  @override
  State<ItemMasterPage> createState() => _ItemMasterPageState();
}

class _ItemMasterPageState extends State<ItemMasterPage> {
  List<Item> allItems = [];
  List<Item> displayedItems = [];
  bool isLoading = true;
  String searchQuery = "";

  // Pagination
  final int pageSize = 30;
  int currentPage = 1;
  bool isLoadingMore = false;
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
    setState(() {
      isLoading = true;
    });

    try {
      final localItems = await ItemApi.getLocalItems();
      setState(() {
        allItems = localItems;
        displayedItems = _paginateItems(localItems, currentPage, pageSize);
        isLoading = false;
      });
    } catch (e) {
      print("Error loading items: $e");
      setState(() {
        allItems = [];
        displayedItems = [];
        isLoading = false;
      });
    }
  }

  List<Item> _paginateItems(List<Item> items, int page, int size) {
    int start = (page - 1) * size;
    int end = start + size;
    if (start >= items.length) return [];
    if (end > items.length) end = items.length;
    return items.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMore) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (displayedItems.length >= allItems.length) return;
    setState(() {
      isLoadingMore = true;
      currentPage += 1;
      displayedItems = _paginateItems(allItems, currentPage, pageSize);
      isLoadingMore = false;
    });
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      final filtered = allItems.where((item) {
        return (item.itemCode.toLowerCase().contains(searchQuery)) ||
            (item.itemName.toLowerCase().contains(searchQuery)) ||
            (item.itemGroupName.toLowerCase().contains(searchQuery)) ||
            ((item.manufacturerDes ?? "").toLowerCase().contains(searchQuery)) ||
            ((item.subGroupDes ?? "").toLowerCase().contains(searchQuery)) ||
            ((item.itemBrandDes ?? "").toLowerCase().contains(searchQuery)) ||
            ((item.subGroup2Des ?? "").toLowerCase().contains(searchQuery));
      }).toList();

      currentPage = 1;
      displayedItems = _paginateItems(filtered, currentPage, pageSize);
    });
  }

  Widget itemCard(Item item) {
    return ExpansionTile(
      leading: item.imageUrlLocal != null
          ? Image.network(item.imageUrlLocal!, width: 40, height: 40, fit: BoxFit.cover)
          : const Icon(Icons.inventory, size: 40, color: Colors.grey),
      title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Code: ${item.itemCode}"),
      trailing: const Icon(Icons.keyboard_arrow_down),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildDetailRow("Item Group", item.itemGroupName),
        _buildDetailRow("UGP Entry", item.ugpEntry.toString()),
        _buildDetailRow("On Hand", item.onhand.toString()),
        _buildDetailRow("On Order", item.onOrder.toString()),
        _buildDetailRow("Committed", item.isCommited.toString()),
        _buildDetailRow("Available", item.available.toString()),
        _buildDetailRow("Min Level", item.minLevel.toString()),
        _buildDetailRow("Max Level", item.maxLevel.toString()),
        _buildDetailRow("Status", item.status),
        _buildDetailRow("Foreign Name", item.frgnName),
        _buildDetailRow("UoM Code", item.invUoMCode),
        _buildDetailRow("Updated Date", item.updatedDate.toString()),
        _buildDetailRow("OCR Codes", "${item.ocrCode}, ${item.ocrCode2}, ${item.ocrCode3}, ${item.ocrCode4}"),
        _buildDetailRow("Manufacturer", item.manufacturer),
        _buildDetailRow("Sub Group", item.subGroup),
        _buildDetailRow("Item Brand", item.itemBrand),
        _buildDetailRow("Item Type", item.itemType),
        _buildDetailRow("Protein Type", item.proteinType),
        _buildDetailRow("Factory", item.factory),
        _buildDetailRow("Bar Code", item.barCode),
        _buildDetailRow("Def Entry", item.defEntry.toString()),
        _buildDetailRow("Alt Qty", item.altQty.toString()),
        _buildDetailRow("Selling Price", item.sellingPrice.toString()),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Item Master",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ Back arrow color
        ),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by anything",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterItems,
            ),
          ),
          // Item list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedItems.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.separated(
              controller: _scrollController,
              itemCount: displayedItems.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index < displayedItems.length) {
                  return itemCard(displayedItems[index]);
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}