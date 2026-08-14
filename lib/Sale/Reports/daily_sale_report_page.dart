import 'package:flutter/material.dart';
import '../../api/daily_sale_report_api.dart';

class DailySaleReportPage extends StatefulWidget {
  const DailySaleReportPage({super.key});

  @override
  State<DailySaleReportPage> createState() => _DailySaleReportPageState();
}

class _DailySaleReportPageState extends State<DailySaleReportPage> {
  bool isLoading = true;
  List<DailySaleReportItem> reportItems = [];
  List<DailySaleReportItem> filteredItems = [];
  DateTime _selectedDate = DateTime.now();

  // Local filter states
  String _selectedSaleFilter = 'All';
  String _typeFilter = 'ALL'; // 'ALL', 'OWN', 'TEAM'
  List<String> _availableSalesNames = ['All'];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  String _formatApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadReportData() async {
    setState(() => isLoading = true);

    final results = await DailySaleReportApi.fetchReport(
      passwordHash: "e10adc3949ba59abbe56e057f20f883e", // Securely pull or pass from session if needed
      asDate: _formatApiDate(_selectedDate),
    );

    // Extract unique sale names dynamically from the fetched list for the filter dropdown
    Set<String> uniqueSales = {'All'};
    for (var item in results) {
      if (item.saleName != null && item.saleName!.isNotEmpty) {
        uniqueSales.add(item.saleName!);
      }
    }

    setState(() {
      reportItems = results;
      _availableSalesNames = uniqueSales.toList();

      // Reset filter if previously selected sale is no longer present
      if (!_availableSalesNames.contains(_selectedSaleFilter)) {
        _selectedSaleFilter = 'All';
      }

      _applyLocalFilter();
      isLoading = false;
    });
  }

  // Client-side local filtering (Instant sorting without hitting the backend API)
  void _applyLocalFilter() {
    filteredItems = reportItems.where((item) {
      bool matchesRep = _selectedSaleFilter == 'All' || item.saleName == _selectedSaleFilter;
      bool matchesType = true;

      if (_typeFilter == 'OWN') {
        matchesType = item.type == 'Own';
      } else if (_typeFilter == 'TEAM') {
        matchesType = item.type != 'Own';
      }

      return matchesRep && matchesType;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Modern soft background
      appBar: AppBar(
        title: const Text("Daily Sales Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A), // Blue Sea Header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // FILTERS BAR (Date Selector + Segmented Type Filter + Sales Dropdown)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Row 1: Date Picker & Refresh Button
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Date: ${_formatApiDate(_selectedDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: _loadReportData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.refresh_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Own vs Team Segment Filter Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildSegmentButton('All', 'ALL'),
                      _buildSegmentButton('Mine (Own)', 'OWN'),
                      _buildSegmentButton('Team', 'TEAM'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Row 3: Instant Local Sales Representative Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      const Text(
                        "Sale:",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSaleFilter,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                            items: _availableSalesNames.map((String name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name == 'All' ? 'All Sales Representatives' : name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSaleFilter = newValue;
                                  _applyLocalFilter();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // CONTENT LIST VIEW
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : filteredItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("No performance records found", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final bool isOwn = item.type == "Own";
                final bool isUp = item.amountStatus == "UP";

                // Theme coloring based on Own vs Team
                final cardAccentColor = isOwn ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6);
                final badgeBgColor = isOwn ? const Color(0xFFEFF6FF) : const Color(0xFFF3E8FF);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER STRIP (Type & Sales Name)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: badgeBgColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cardAccentColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOwn ? "Personal Report" : "Team Overview",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.saleName ?? 'Unknown User',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                              // Status Up/Down Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUp ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                      size: 14,
                                      color: isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${item.amountStatus ?? 'NO CHANGE'} (${item.amountRateChangePercent?.toStringAsFixed(1) ?? '0.0'}%)",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // METRICS BODY
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // TODAY METRIC BOX
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("TODAY'S SALE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Text(
                                        "\$${item.totalAmtAsDate?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item.totalInvoiceAsDate ?? 0} Invoices",
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // YESTERDAY METRIC BOX
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("YESTERDAY'S SALE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Text(
                                        "\$${item.totalAmtYesterday?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item.totalInvoiceYesterday ?? 0} Invoices",
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, String value) {
    bool isSelected = _typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeFilter = value;
            _applyLocalFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}