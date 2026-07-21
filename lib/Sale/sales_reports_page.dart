// File: lib/pages/sales_reports_page.dart

import 'package:flutter/material.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  // 📅 Date Range Filter States (Default to Today)
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  /// Helper to format date nicely as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Open Date Picker Dialog
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A), // Header background
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
        if (isFromDate) {
          _fromDate = picked;
          // Ensure To Date is not earlier than From Date
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          // Ensure From Date is not later than To Date
          if (picked.isBefore(_fromDate)) {
            _fromDate = picked;
          }
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text(
          "Sales & Performance Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📅 DATE RANGE FILTER BAR
            _buildDateRangeFilterBar(),
            const SizedBox(height: 16),

            // 📑 REPORT CATEGORIES HEADER
            const Text(
              "AVAILABLE FIELD REPORTS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // 📂 REPORT MODULE LIST CARDS
            _buildReportCard(
              title: "1. Daily Sales Performance",
              subtitle: "Total order amounts, cash vs credit breakdown, and targets.",
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF10B981),
              backgroundColor: const Color(0xFFECFDF5),
              onTap: () => _navigateToReportDetail(context, "Daily Sales Performance"),
            ),
            _buildReportCard(
              title: "2. Outlet Visit & Coverage",
              subtitle: "Planned routes vs actual shops visited and success rates.",
              icon: Icons.map_rounded,
              iconColor: const Color(0xFF1D4ED8),
              backgroundColor: const Color(0xFFEFF6FF),
              onTap: () => _navigateToReportDetail(context, "Outlet Visit & Coverage"),
            ),
            _buildReportCard(
              title: "3. Sales History & Sync Status",
              subtitle: "All submitted route orders and local sync confirmation logs.",
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFFD97706),
              backgroundColor: const Color(0xFFFFFBEB),
              onTap: () => _navigateToReportDetail(context, "Sales History & Sync Status"),
            ),
            _buildReportCard(
              title: "4. Product Sales Breakdown",
              subtitle: "Top-selling SKUs, inventory movement, and category trends.",
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF7C3AED),
              backgroundColor: const Color(0xFFF5F3FF),
              onTap: () => _navigateToReportDetail(context, "Product Sales Breakdown"),
            ),
            _buildReportCard(
              title: "5. Outstanding Collections",
              subtitle: "Customer balances, overdue accounts, and cash collections.",
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFFFEF2F2),
              onTap: () => _navigateToReportDetail(context, "Outstanding Collections"),
            ),
            _buildReportCard(
              title: "6. 'No-Buy' / Lost Opportunity",
              subtitle: "Summarized zero-sale check-out reasons and feedback logs.",
              icon: Icons.block_rounded,
              iconColor: const Color(0xFF475569),
              backgroundColor: const Color(0xFFF1F5F9),
              onTap: () => _navigateToReportDetail(context, "No-Buy & Lost Opportunity"),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Date-to-Date Filter Bar
  Widget _buildDateRangeFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // FROM DATE BUTTON
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("From Date", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Text(_formatDate(_fromDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
          ),
          // TO DATE BUTTON
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("To Date", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Text(_formatDate(_toDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Report Card Builder
  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  /// Placeholder navigation action for individual reports passing active dates
  void _navigateToReportDetail(BuildContext context, String reportTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Text(reportTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Detailed view for '$reportTitle'\n\nQuerying Data Range:\nFrom: ${_formatDate(_fromDate)} To: ${_formatDate(_toDate)}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}