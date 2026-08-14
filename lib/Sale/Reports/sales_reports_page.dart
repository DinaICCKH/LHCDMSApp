// File: lib/pages/sales_reports_page.dart

import 'package:flutter/material.dart';
import 'package:kuberadmsdn/Sale/Reports/report03_sale_history_and_syn_status_page.dart';
import 'package:kuberadmsdn/Sale/Reports/report04_product_sell_breakdown_page.dart';

import 'daily_sale_report_page.dart';
import 'opportunity_report_page.dart';
import 'outlet_visit_report_page.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailySaleReportPage(),
                  ),
                );
              },
            ),
            _buildReportCard(
              title: "2. Outlet Visit & Coverage",
              subtitle: "Planned routes vs actual shops visited and success rates.",
              icon: Icons.map_rounded,
              iconColor: const Color(0xFF1D4ED8),
              backgroundColor: const Color(0xFFEFF6FF),
              onTap: () {
                // Navigate directly to the Outlet Visit Report Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OutletVisitReportPage(),
                  ),
                );
              },
            ),
            _buildReportCard(
              title: "3. Sales History & Sync Status",
              subtitle: "All submitted route orders and local sync confirmation logs.",
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFFD97706),
              backgroundColor: const Color(0xFFFFFBEB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Report03SaleHistoryandSynStatusPage(),
                  ),
                );
              },
            ),
            _buildReportCard(
              title: "4. Product Sales Breakdown",
              subtitle: "Top-selling SKUs and category trends.",
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF7C3AED),
              backgroundColor: const Color(0xFFF5F3FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Report04ProductSellBreakdownPage(),
                  ),
                );
              },
            ),
            _buildReportCard(
              title: "5. Opportunity",
              subtitle: "Summarized zero-sale check-out reasons and feedback logs.",
              icon: Icons.block_rounded,
              iconColor: const Color(0xFF475569),
              backgroundColor: const Color(0xFFF1F5F9),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OpportunityReportPage(),
                ),
              ),
            ),
          ],
        ),
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

  /// Placeholder navigation action for individual reports
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
                "Detailed view for '$reportTitle'",
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