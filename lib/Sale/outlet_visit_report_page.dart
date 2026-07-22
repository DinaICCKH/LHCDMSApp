import 'package:flutter/material.dart';
import '../api/outlet_visit_report_api.dart';

class OutletVisitReportPage extends StatefulWidget {
  const OutletVisitReportPage({super.key});

  @override
  State<OutletVisitReportPage> createState() => _OutletVisitReportPageState();
}

class _OutletVisitReportPageState extends State<OutletVisitReportPage> {
  bool isLoading = true;
  List<OutletVisitItem> reportItems = [];
  List<OutletVisitItem> filteredItems = [];
  DateTime _selectedDate = DateTime.now();

  // Local filter states
  String _selectedSaleFilter = 'All';
  String _typeFilter = 'ALL'; // 'ALL', 'OWN', 'TEAM'
  List<String> _availableSalesNames = ['All'];

  // Custom theme colors matching your deep blue aesthetic
  static const Color primaryBlue = Color(0xFF1D3B73);
  static const Color lightBlueBg = Color(0xFFF2F5FA);

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

    // Fetches the full dataset from the backend API
    final results = await OutletVisitApi.fetchReport(
      passwordHash: "e10adc3949ba59abbe56e057f20f883e", // Replace or pull dynamically from auth session
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

      // Reset filter if the previously selected sale is no longer present in the new dataset
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
      backgroundColor: lightBlueBg,
      appBar: AppBar(
        title: const Text("Outlet Visit Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
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
                            border: Border.all(color: primaryBlue.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(10),
                            color: lightBlueBg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 20, color: primaryBlue),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Date: ${_formatApiDate(_selectedDate)}",
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: primaryBlue),
                                  ),
                                ],
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: primaryBlue),
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
                          backgroundColor: primaryBlue,
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
                    color: lightBlueBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryBlue.withOpacity(0.2)),
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
                    border: Border.all(color: primaryBlue.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                    color: lightBlueBg,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 20, color: primaryBlue),
                      const SizedBox(width: 10),
                      const Text(
                        "Sale:",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: primaryBlue),
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

          // LIST CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : filteredItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 48, color: primaryBlue.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text("No outlet visits found for selected filter", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final bool isOwn = item.type == "Own";
                final bool isVisited = item.visited == "Yes";

                final cardAccentColor = isOwn ? primaryBlue : const Color(0xFF0D9488);
                final badgeBgColor = isOwn ? primaryBlue.withOpacity(0.08) : const Color(0xFFF0FDFA);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isOwn ? primaryBlue.withOpacity(0.4) : primaryBlue.withOpacity(0.15),
                      width: isOwn ? 1.5 : 1,
                    ),
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
                                      isOwn ? "MINE (OWN)" : item.type.toString(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.saleName ?? 'Unknown Sale',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              // Visited Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVisited ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVisited ? Icons.check_circle_rounded : Icons.pending_rounded,
                                      size: 14,
                                      color: isVisited ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVisited ? "Visited" : "Not Visited",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isVisited ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DETAILS BODY
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("OUTLET CODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.cardCode ?? 'N/A',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text("DOC NUMBER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.docNum ?? 'N/A',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (item.reasonType != null && item.reasonType!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reason: ${item.reasonType}",
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                      ),
                                      if (item.remark != null && item.remark!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.remark!,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
            color: isSelected ? primaryBlue : Colors.transparent,
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