import 'package:flutter/material.dart';
import '../api/get_customer_api.dart';

class CustomerMasterPage extends StatefulWidget {
  const CustomerMasterPage({super.key});

  @override
  State<CustomerMasterPage> createState() => _CustomerMasterPageState();
}

class _CustomerMasterPageState extends State<CustomerMasterPage> {
  List<Customer> allCustomers = [];
  List<Customer> filteredCustomers = [];
  List<Customer> displayedCustomers = [];

  bool isLoading = true;
  bool isLoadingMore = false;

  String searchQuery = "";

  final int pageSize = 30;
  int currentPage = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= LOAD
  Future<void> _loadCustomers() async {
    setState(() => isLoading = true);

    try {
      final data = await CustomerApi.getLocalCustomers();

      setState(() {
        allCustomers = data;
        filteredCustomers = data;

        currentPage = 1;
        displayedCustomers = _paginate(data);

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// ================= PAGINATION (FIXED)
  List<Customer> _paginate(List<Customer> list) {
    final end = (currentPage * pageSize);

    if (end >= list.length) return list;

    return list.sublist(0, end);
  }

  /// ================= LOAD MORE
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150 &&
        !isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (displayedCustomers.length >= filteredCustomers.length) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
      displayedCustomers = _paginate(filteredCustomers);
      isLoadingMore = false;
    });
  }

  /// ================= SEARCH (FIXED)
  void _filter(String value) {
    final q = value.toLowerCase().trim();

    final filtered = allCustomers.where((c) {
      return c.cardCode.toLowerCase().contains(q) ||
          c.cardName.toLowerCase().contains(q) ||
          c.groupName.toLowerCase().contains(q) ||
          c.contactPersonName.toLowerCase().contains(q) ||
          c.fullAddress.toLowerCase().contains(q) ||
          c.paymentTerm.toLowerCase().contains(q) ||
          c.priceList.toLowerCase().contains(q);
    }).toList();

    setState(() {
      searchQuery = q;
      filteredCustomers = filtered;

      currentPage = 1;
      displayedCustomers = _paginate(filtered);
    });
  }

  /// ================= CARD UI (MODERN)
  Widget customerCard(Customer c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),

        title: Text(
          c.cardName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          "Code: ${c.cardCode}",
          style: const TextStyle(fontSize: 12),
        ),

        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        children: [
          _row("Group", c.groupName),
          _row("Contact", c.contactPersonName),
          _row("Phone", c.tel1),
          _row("Mobile", c.mobile),
          _row("Address", c.fullAddress),
          _row("Payment", c.paymentTerm),
          _row("Price List", c.priceList),
          _row("Credit", c.creditLimit.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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

  /// ================= UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Customer Master",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: "Search customers...",
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

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedCustomers.isEmpty
                ? const Center(
              child: Text("No customers found"),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: displayedCustomers.length + 1,
              itemBuilder: (context, index) {
                if (index < displayedCustomers.length) {
                  return customerCard(
                    displayedCustomers[index],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: isLoadingMore
                        ? const CircularProgressIndicator()
                        : const SizedBox(),
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