import 'package:flutter/material.dart';
import '../api/get_customer_api.dart';

/// =============================================================
/// CUSTOMER MASTER DIRECTORY PAGE
/// =============================================================
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

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await CustomerApi.getLocalCustomers();

      if (mounted) {
        setState(() {
          allCustomers = data;
          filteredCustomers = data;
          currentPage = 1;
          displayedCustomers = _paginate(data);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Customer> _paginate(List<Customer> list) {
    final end = (currentPage * pageSize);
    if (end >= list.length) return list;
    return list.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150 && !isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (displayedCustomers.length >= filteredCustomers.length) return;

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;

    setState(() {
      displayedCustomers = _paginate(filteredCustomers);
      isLoadingMore = false;
    });
  }

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

  /// =============================================================
  /// MODERNIZED CUSTOMER PROFILE DISPLAY CARD
  /// =============================================================
  Widget customerCard(Customer c) {
    // Generate a clean single character profile initial placeholder
    final String clientInitials = c.cardName.isNotEmpty ? c.cardName.trim()[0].toUpperCase() : "C";
    final bool balanceWarning = c.creditLimit <= 500.00;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              clientInitials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
          title: Text(
            c.cardName.isEmpty ? "-" : c.cardName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.cardCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.expand_more_rounded, color: Color(0xFF94A3B8)),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 0),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Main Details Row Matrix Grid
            Row(
              children: [
                Expanded(child: _infoBlock("Contact Manager", c.contactPersonName)),
                Expanded(child: _infoBlock("Price Tier", c.priceList)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoBlock("Phone Regular", c.tel1.isEmpty ? "-" : c.tel1)),
                Expanded(child: _infoBlock("Mobile / WhatsApp", c.mobile.isEmpty ? "-" : c.mobile)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoBlock("Payment Terms", c.paymentTerm)),
                Expanded(
                  child: _infoBlock(
                    "Credit Cap Limit",
                    "\$${c.creditLimit.toStringAsFixed(2)}",
                    textColor: balanceWarning ? Colors.amber.shade900 : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full Structural Address Row block
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Geographic Location Address", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  c.fullAddress.isEmpty ? "No explicit street register address logs found." : c.fullAddress,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
              ],
            ),
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
  /// MAIN WIDGET VIEWPORT BUILDER
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Customer Database Directory",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Styled Search Banner Header matching Item Master Screen Blue
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E3A8A),
            child: TextField(
              onChanged: _filter,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search customer records, code, numbers...",
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

          // Total Items Metadata Counter Widget Row
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Assigned Active Clients",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${filteredCustomers.length} clients",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),

          // Main Client List Viewport Container
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
                : displayedCustomers.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 48, color: Colors.black26),
                  SizedBox(height: 8),
                  Text("No client registry matches found", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: displayedCustomers.length + 1,
              itemBuilder: (context, index) {
                if (index < displayedCustomers.length) {
                  return customerCard(displayedCustomers[index]);
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: isLoadingMore
                        ? const CircularProgressIndicator(strokeWidth: 2.5)
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