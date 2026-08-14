import 'package:flutter/material.dart';
import '../../api/report04_product_sell_breakdown_service.dart';

class Report04ProductSellBreakdownPage extends StatefulWidget {
  const Report04ProductSellBreakdownPage({Key? key}) : super(key: key);

  @override
  State<Report04ProductSellBreakdownPage> createState() =>
      _Report04ProductSellBreakdownPageState();
}

class _Report04ProductSellBreakdownPageState
    extends State<Report04ProductSellBreakdownPage> {
  late Future<Report04ProductSellBreakdownResponse> _futureReport;
  final Report04ProductSellBreakdownService _service =
  Report04ProductSellBreakdownService();

  late String _fromDate;
  late String _toDate;

  String? _selectedSaleName;
  String _sortBy = 'revenue'; // 'revenue' or 'qty'
  String _typeFilter = 'ALL'; // 'ALL', 'OWN', 'TEAM'

  @override
  void initState() {
    super.initState();

    // Set default dates: ToDate is Today, FromDate is 7 days ago
    final DateTime now = DateTime.now();
    _toDate = _formatDate(now);
    _fromDate = _formatDate(now.subtract(const Duration(days: 7)));

    _loadReport();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _loadReport() {
    setState(() {
      _selectedSaleName = null;
      _futureReport = _service.fetchReport(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e", // Matches integrated Service signature
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(_fromDate),
        end: DateTime.parse(_toDate),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = _formatDate(picked.start);
        _toDate = _formatDate(picked.end);
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Product Sales Breakdown',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter & Date Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade100),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFEFF6FF),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_fromDate  →  $_toDate',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: const Color(0xFF1E3A8A),
                  tooltip: 'Reload Data',
                  onPressed: _loadReport,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main Body Content
          Expanded(
            child: FutureBuilder<Report04ProductSellBreakdownResponse>(
              future: _futureReport,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E3A8A),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load breakdown records',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadReport,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final response = snapshot.data;

                // Handle service-level error or API failure state gracefully
                if (response == null || !response.success) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 48, color: Colors.amber.shade700),
                          const SizedBox(height: 12),
                          const Text(
                            'Notice',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            response?.message ?? 'Unknown response error occurred.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadReport,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allRecords = response.data;

                if (allRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No breakdown records found for this range.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Sort records based on chosen sorting state
                if (_sortBy == 'revenue') {
                  allRecords.sort((a, b) => b.lineTotal.compareTo(a.lineTotal));
                } else {
                  allRecords.sort((a, b) => b.quantity.compareTo(a.quantity));
                }

                // Unique Sale Names for filter
                final uniqueSaleNames = allRecords
                    .map((e) => e.saleName)
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList();

                // Apply filters (Sales Rep & Type: Own vs Team)
                var records = allRecords.where((item) {
                  bool matchesRep = _selectedSaleName == null || item.saleName == _selectedSaleName;
                  bool matchesType = true;
                  if (_typeFilter == 'OWN') {
                    matchesType = item.type.toLowerCase() == 'own';
                  } else if (_typeFilter == 'TEAM') {
                    matchesType = item.type.toLowerCase() != 'own';
                  }
                  return matchesRep && matchesType;
                }).toList();

                // Calculate summary metrics for filtered view
                double totalRevenue =
                records.fold(0.0, (sum, item) => sum + item.lineTotal);
                double totalQty =
                records.fold(0.0, (sum, item) => sum + item.quantity);
                final topItem = records.isNotEmpty ? records.first : null;

                return Column(
                  children: [
                    // Own vs Team Quick Segment Filter Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  _buildSegmentButton('All', 'ALL'),
                                  _buildSegmentButton('Mine (Own)', 'OWN'),
                                  _buildSegmentButton('Team', 'TEAM'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // Filter & Sorting Control Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  'Rep:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedSaleName,
                                    hint: const Text('All Reps',
                                        style: TextStyle(fontSize: 12)),
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('All Reps',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      ...uniqueSaleNames.map((name) {
                                        return DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(name,
                                              style: const TextStyle(fontSize: 12)),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSaleName = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
                          // Sort Selector
                          Row(
                            children: [
                              const Text(
                                'Sort:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              DropdownButton<String>(
                                value: _sortBy,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'revenue',
                                      child: Text('By Value (\$)',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'qty',
                                      child: Text('By Quantity',
                                          style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _sortBy = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Top 1 Best-Seller Hero Banner
                    if (topItem != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amberAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '#1 TOP BEST-SELLING PRODUCT',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    topItem.description,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rep: ${topItem.saleName} • Qty Sold: ${topItem.quantity.toStringAsFixed(0)} ${topItem.uomCode}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${topItem.lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'Revenue',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Quick Totals Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ranked Items (${records.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Qty: ${totalQty.toStringAsFixed(0)}  •  ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Total: \$${totalRevenue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Ranked Product Cards List
                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                        child: Text(
                          'No items found matching filter.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isTop3 = index < 3;
                          final isOwn = item.type.toLowerCase() == 'own';

                          // Medals/Badge styling for top ranks
                          Color badgeColor;
                          if (index == 0) {
                            badgeColor = const Color(0xFFD97706); // Gold
                          } else if (index == 1) {
                            badgeColor = const Color(0xFF64748B); // Silver
                          } else if (index == 2) {
                            badgeColor = const Color(0xFFB45309); // Bronze
                          } else {
                            badgeColor = Colors.grey.shade300;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              border: Border.all(
                                color: isOwn
                                    ? const Color(0xFF93C5FD)
                                    : Colors.grey.shade200,
                                width: isOwn ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Rank Badge Indicator
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isTop3
                                          ? badgeColor
                                          : Colors.grey.shade100,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          color: isTop3
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Item Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.itemCode,
                                              style: const TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                fontSize: 12,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOwn
                                                    ? const Color(
                                                    0xFFEFF6FF)
                                                    : Colors
                                                    .grey.shade200,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    4),
                                                border: isOwn
                                                    ? Border.all(
                                                    color: const Color(
                                                        0xFF1E3A8A),
                                                    width: 0.5)
                                                    : null,
                                              ),
                                              child: Text(
                                                isOwn
                                                    ? 'MINE (OWN)'
                                                    : item.type
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: isOwn
                                                      ? const Color(
                                                      0xFF1E3A8A)
                                                      : Colors
                                                      .grey.shade700,
                                                  fontSize: 9,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Qty: ${item.quantity.toStringAsFixed(0)} ${item.uomCode} • Rep: ${item.saleName}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Line Total Amount
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${item.lineTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}