import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_customer_api.dart';

class CustomerMasterPage extends StatefulWidget {
  const CustomerMasterPage({super.key});

  @override
  State<CustomerMasterPage> createState() => _CustomerMasterPageState();
}

class _CustomerMasterPageState extends State<CustomerMasterPage> {
  List<Customer> allCustomers = [];
  List<Customer> displayedCustomers = [];
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
    _loadCustomers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final localCustomers = await CustomerApi.getLocalCustomers();
      setState(() {
        allCustomers = localCustomers;
        displayedCustomers = _paginateCustomers(localCustomers, currentPage, pageSize);
        isLoading = false;
      });
    } catch (e) {
      print("Error loading customers: $e");
      setState(() {
        allCustomers = [];
        displayedCustomers = [];
        isLoading = false;
      });
    }
  }

  List<Customer> _paginateCustomers(List<Customer> customers, int page, int size) {
    int start = (page - 1) * size;
    int end = start + size;
    if (start >= customers.length) return [];
    if (end > customers.length) end = customers.length;
    return customers.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMore) {
      _loadMoreCustomers();
    }
  }

  void _loadMoreCustomers() {
    if (displayedCustomers.length >= allCustomers.length) return;
    setState(() {
      isLoadingMore = true;
      currentPage += 1;
      displayedCustomers = _paginateCustomers(allCustomers, currentPage, pageSize);
      isLoadingMore = false;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      final filtered = allCustomers.where((c) {
        return (c.cardCode.toLowerCase().contains(searchQuery)) ||
            (c.cardName.toLowerCase().contains(searchQuery)) ||
            (c.groupName.toLowerCase().contains(searchQuery)) ||
            ((c.contactPersonName ?? "").toLowerCase().contains(searchQuery)) ||
            ((c.fullAddress ?? "").toLowerCase().contains(searchQuery)) ||
            ((c.paymentTerm ?? "").toLowerCase().contains(searchQuery)) ||
            ((c.priceList ?? "").toLowerCase().contains(searchQuery));
      }).toList();

      currentPage = 1;
      displayedCustomers = _paginateCustomers(filtered, currentPage, pageSize);
    });
  }

  Widget customerCard(Customer customer) {
    return ExpansionTile(
      leading: const Icon(Icons.person, size: 40, color: Colors.grey),
      title: Text(customer.cardName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Code: ${customer.cardCode}"),
      trailing: const Icon(Icons.keyboard_arrow_down),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildDetailRow("Group", customer.groupName),
        _buildDetailRow("Contact Person", customer.contactPersonName ?? ""),
        _buildDetailRow("Tel1", customer.tel1 ?? ""),
        _buildDetailRow("Tel2", customer.tel2 ?? ""),
        _buildDetailRow("Mobile", customer.mobile ?? ""),
        _buildDetailRow("Full Address", customer.fullAddress ?? ""),
        _buildDetailRow("Payment Term", customer.paymentTerm ?? ""),
        _buildDetailRow("Price List", customer.priceList ?? ""),
        _buildDetailRow("Credit Limit", customer.creditLimit.toStringAsFixed(2)),
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
          "Customer Master",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow color
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
                hintText: "Search by code, name, group, etc.",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterCustomers,
            ),
          ),
          // Customer list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedCustomers.isEmpty
                ? const Center(child: Text("No customers found"))
                : ListView.separated(
              controller: _scrollController,
              itemCount: displayedCustomers.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index < displayedCustomers.length) {
                  return customerCard(displayedCustomers[index]);
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