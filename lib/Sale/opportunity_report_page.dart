// opportunity_report_page.dart

import 'package:flutter/material.dart';
import '../api/opportunity_report_api.dart';

class OpportunityReportPage extends StatefulWidget {
  const OpportunityReportPage({super.key});

  @override
  State<OpportunityReportPage> createState() => _OpportunityReportPageState();
}

class _OpportunityReportPageState extends State<OpportunityReportPage> {
  bool isLoading = true;
  List<OpportunityReportItem> reportItems = [];
  List<OpportunityReportItem> filteredItems = [];
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

    final results = await OpportunityReportApi.fetchReport(
      passwordHash: "e10adc3949ba59abbe56e057f20f883e",
      asDate: _formatApiDate(_selectedDate),
    );

    Set<String> uniqueSales = {'All'};
    for (var item in results) {
      if (item.saleName != null && item.saleName!.isNotEmpty) {
        uniqueSales.add(item.saleName!);
      }
    }

    setState(() {
      reportItems = results;
      _availableSalesNames = uniqueSales.toList();

      if (!_availableSalesNames.contains(_selectedSaleFilter)) {
        _selectedSaleFilter = 'All';
      }

      _applyLocalFilter();
      isLoading = false;
    });
  }

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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Opportunity Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // FILTERS BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
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

                // Segment Filter Bar
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

                // Sales Representative Filter Dropdown
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
                  Text("No opportunity records found", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final bool isOwn = item.type == "Own";

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
                        // HEADER STRIP
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
                              // Total Opportunity Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Total Opp: ${item.totalOpportunity ?? 0}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // METRICS BODY
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      "VISITED",
                                      "${item.totalVisit ?? 0}",
                                      "${item.visitPercent?.toStringAsFixed(1) ?? '0.0'}%",
                                      const Color(0xFF16A34A),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricBox(
                                      "UNVISITED",
                                      "${item.totalUnVisit ?? 0}",
                                      "${item.unVisitPercent?.toStringAsFixed(1) ?? '0.0'}%",
                                      const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      "BUY",
                                      "${item.totalBuy ?? 0}",
                                      "${item.buyPercent?.toStringAsFixed(1) ?? '0.0'}%",
                                      const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricBox(
                                      "NO BUY",
                                      "${item.totalNoBuy ?? 0}",
                                      "${item.noBuyPercent?.toStringAsFixed(1) ?? '0.0'}%",
                                      const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
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

  Widget _buildMetricBox(String title, String count, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                percentage,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
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