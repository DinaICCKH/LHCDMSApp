import 'package:flutter/material.dart';
import '../../api/report03_sale_history_and_syn_status_service.dart';

class Report03SaleHistoryandSynStatusPage extends StatefulWidget {
  const Report03SaleHistoryandSynStatusPage({Key? key}) : super(key: key);

  @override
  State<Report03SaleHistoryandSynStatusPage> createState() =>
      _Report03SaleHistoryandSynStatusPageState();
}

class _Report03SaleHistoryandSynStatusPageState
    extends State<Report03SaleHistoryandSynStatusPage> {
  late Future<Report03SaleHistoryandSynStatusResponse> _futureReport;
  final Report03SaleHistoryandSynStatusService _service =
  Report03SaleHistoryandSynStatusService();

  // Filter state variables
  late String _fromDate;
  late String _toDate;
  String? _selectedSaleName; // For filtering by sales rep
  String _typeFilter = 'ALL'; // 'ALL', 'OWN', 'TEAM'

  // Backing list field reference helper defined properly inside the State class
  List<Report03SaleHistoryandSynStatusRecord> allRecords = [];

  @override
  void initState() {
    super.initState();

    // Default dates: ToDate is Today, FromDate is 7 days ago
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
      _selectedSaleName = null; // Reset filter on fresh data load
      _futureReport = _service.fetchReport(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e", // Replace or pass dynamic passwordHash if needed
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'i':
        return Colors.green.shade700;
      case 'draft':
      case 'n':
        return Colors.amber.shade800;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Sales History & Sync Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter & Summary Header Component
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Picker Button
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

                // Refresh Button
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
            child: FutureBuilder<Report03SaleHistoryandSynStatusResponse>(
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
                      child: Text(
                        'Error loading records:\n${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No sales history records found for this range.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final response = snapshot.data!;
                allRecords = response.data;

                // Extract unique list of Sales Names for the dropdown filter
                final uniqueSaleNames = allRecords
                    .map((e) => e.saleName)
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList();

                // Apply dynamic filters (Sales Rep & Type: Own vs Team)
                final records = allRecords.where((item) {
                  bool matchesRep = _selectedSaleName == null || item.saleName == _selectedSaleName;
                  bool matchesType = true;
                  if (_typeFilter == 'OWN') {
                    matchesType = item.type.toLowerCase() == 'own';
                  } else if (_typeFilter == 'TEAM') {
                    matchesType = item.type.toLowerCase() != 'own';
                  }
                  return matchesRep && matchesType;
                }).toList();

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

                    // Dynamic Sales Rep Filter Dropdown Bar
                    if (uniqueSaleNames.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: Colors.white,
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedSaleName,
                                hint: const Text('All Representatives',
                                    style: TextStyle(fontSize: 12)),
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Representatives',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  ...uniqueSaleNames.map((name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name,
                                          style: const TextStyle(fontSize: 12)),
                                    );
                                  }),
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
                    const SizedBox(height: 6),

                    // Filtered List View
                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                        child: Text(
                          'No records match the selected filter.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isOwn = item.type.toLowerCase() == 'own';

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
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Own/Team Tag, Doc ID and Status Badges
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          // Clearly differentiated Own vs Team Tag
                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOwn
                                                  ? const Color(0xFF1E3A8A)
                                                  : Colors.grey
                                                  .shade600,
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
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '#${item.docEntry}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildBadge(
                                              item.docStatus,
                                              _getStatusColor(
                                                  item.docStatus)),
                                          const SizedBox(width: 6),
                                          _buildBadge(
                                              'API: ${item.apiStatus}',
                                              _getStatusColor(
                                                  item.apiStatus)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Divider(height: 1),
                                  ),
                                  // Customer Information
                                  Text(
                                    '${item.cardCode} - ${item.cardName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rep: ${item.saleName}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        item.docDate,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Bottom Row: Amount & Sync Message Feedback
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${item.docTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669),
                                            fontSize: 15,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 12),
                                            child: Text(
                                              item.sapLastError.isNotEmpty
                                                  ? item.sapLastError
                                                  : (item.apiErrMessage
                                                  .isNotEmpty
                                                  ? item.apiErrMessage
                                                  : 'Synced successfully'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: item.apiStatus ==
                                                    'I'
                                                    ? Colors
                                                    .blue.shade700
                                                    : Colors.orange
                                                    .shade800,
                                              ),
                                              textAlign: TextAlign.end,
                                              overflow:
                                              TextOverflow.ellipsis,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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