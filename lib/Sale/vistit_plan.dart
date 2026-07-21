// File: lib/pages/visit_plan_page.dart

import 'package:flutter/material.dart';
import '../api/get_visitplan_api.dart';
import 'package:intl/intl.dart';

import 'models/customer_visit_model.dart';
import 'sale_visit_check_in.dart';

/// =============================================================
/// ROUTINE VISITATION STRATEGY & SCHEDULING MANAGEMENT VIEW
/// =============================================================
class VisitPlanPage extends StatefulWidget {
  const VisitPlanPage({super.key});

  @override
  State<VisitPlanPage> createState() => _VisitPlanPageState();
}

class _VisitPlanPageState extends State<VisitPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;

  List<VisitPlan> allPlans = [];
  List<VisitPlan> todayPlans = [];
  List<VisitPlan> tomorrowPlans = [];
  List<VisitPlan> yesterdayPlans = [];
  List<VisitPlan> upcomingPlans = [];
  List<VisitPlan> previousPlans = [];

  List<VisitPlan> filteredPlans = [];
  String searchQuery = "";

  final DateFormat dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: 1,
    );

    _loadVisitPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// =============================================================
  /// LOAD VISIT PLANS & MAP STRATIFIED TIMELINES
  /// =============================================================
  Future<void> _loadVisitPlans() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final plans = await VisitPlanApi.getLocalVisitPlans();
      final now = DateTime.now();

      bool sameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      // 🚀 SORTING HELPER: PENDING comes first, SYNCED/DONE goes bottom
      int sortByPendingStatus(VisitPlan a, VisitPlan b) {
        final aPending = a.synced.toLowerCase() != "yes" && a.status.toLowerCase() != "done";
        final bPending = b.synced.toLowerCase() != "yes" && b.status.toLowerCase() != "done";

        if (aPending && !bPending) return -1; // a comes first
        if (!aPending && bPending) return 1;  // b comes first
        return 0;
      }

      if (mounted) {
        setState(() {
          allPlans = plans..sort(sortByPendingStatus);

          todayPlans = plans.where((p) => sameDay(p.visitDate, now)).toList()..sort(sortByPendingStatus);
          tomorrowPlans = plans.where((p) => sameDay(p.visitDate, now.add(const Duration(days: 1)))).toList()..sort(sortByPendingStatus);
          yesterdayPlans = plans.where((p) => sameDay(p.visitDate, now.subtract(const Duration(days: 1)))).toList()..sort(sortByPendingStatus);

          upcomingPlans = plans.where((p) {
            return p.visitDate.isAfter(now.add(const Duration(days: 1))) && !sameDay(p.visitDate, now.add(const Duration(days: 1)));
          }).toList()..sort(sortByPendingStatus);

          previousPlans = plans.where((p) {
            return p.visitDate.isBefore(now.subtract(const Duration(days: 1))) && !sameDay(p.visitDate, now.subtract(const Duration(days: 1)));
          }).toList()..sort(sortByPendingStatus);

          filteredPlans = plans..sort(sortByPendingStatus);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading visit plans: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// =============================================================
  /// SEARCH ROUTINE TEXT QUERY FILTERING
  /// =============================================================
  void _filterSearch(String query) {
    final q = query.toLowerCase().trim();

    setState(() {
      searchQuery = q;
      filteredPlans = allPlans.where((p) {
        return p.cardCode.toLowerCase().contains(q) ||
            p.cardName.toLowerCase().contains(q) ||
            p.remark.toLowerCase().contains(q) ||
            p.docNum.toLowerCase().contains(q) ||
            p.tel1.toLowerCase().contains(q);
      }).toList();

      // 🚀 Keep sorted by PENDING first even when searching
      filteredPlans.sort((a, b) {
        final aPending = a.synced.toLowerCase() != "yes" && a.status.toLowerCase() != "done";
        final bPending = b.synced.toLowerCase() != "yes" && b.status.toLowerCase() != "done";
        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
        return 0;
      });
    });
  }

  /// =============================================================
  /// MODERNIZED VISITATION CARD SPECIFICATION RENDERING
  /// =============================================================
  Widget _buildCard(VisitPlan plan, {bool isToday = false}) {
    final isDone = plan.status.toLowerCase() == "done";
    final isSynced = plan.synced.toLowerCase() == "yes";

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
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 0),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: isDone ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.directions_run_rounded,
              color: isDone ? const Color(0xFF10B981) : const Color(0xFF1D4ED8),
              size: 22,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      plan.cardCode,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSynced ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSynced ? "SYNCED" : "PENDING",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSynced ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.cardName.isEmpty ? "-" : plan.cardName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(plan.visitDate),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.phone_iphone_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    plan.tel1.isEmpty ? "-" : plan.tel1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.expand_more_rounded, color: Color(0xFF94A3B8)),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Two-Column Grid for Plan Details
            Row(
              children: [
                Expanded(child: _infoBlock("Document No", plan.docNum)),
                Expanded(child: _infoBlock("Doc Fiscal Year", plan.docYear.toString())),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoBlock("Visitation Status", plan.status.toUpperCase())),
                Expanded(child: _infoBlock("Detail Key Entry", plan.detailEntry.toString())),
              ],
            ),
            const SizedBox(height: 10),
            _infoBlock("Geographic Location Address", plan.fullAddress.isEmpty ? "No direct registration address reported." : plan.fullAddress),
            if (plan.remark.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoBlock("Scheduler Special Remarks", plan.remark),
            ],

            if (isToday)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: Icon(isSynced ? Icons.verified_rounded : Icons.near_me_rounded, size: 18),
                    label: Text(
                      isSynced ? "Already Visited" : "Start Visit",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSynced ? const Color(0xFF94A3B8) : const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isSynced
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleVisitCheckInPage(
                            customer: CustomerVisit(
                              cardCode: plan.cardCode,
                              cardName: plan.cardName,
                              phone: plan.tel1,
                              fullAddress: plan.fullAddress,
                              detailEntry: plan.detailEntry,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? "-" : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  /// =============================================================
  /// TAB DYNAMIC VIEW CONTENT DISPATCHER
  /// =============================================================
  Widget _buildTab(
      List<VisitPlan> plans, {
        bool searchable = false,
        bool isToday = false,
      }) {
    final data = searchable ? filteredPlans : plans;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              "No structural visit plans listed",
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (searchable)
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E3A8A),
            child: TextField(
              onChanged: _filterSearch,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search customer, code, phone query...",
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVisitPlans,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return _buildCard(
                  data[index],
                  isToday: isToday,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// =============================================================
  /// MAIN ROUTINE TREE BUILDER
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Visit Plan Manager",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: "Yesterday (${yesterdayPlans.length})"),
            Tab(text: "Today (${todayPlans.length})"),
            Tab(text: "Tomorrow (${tomorrowPlans.length})"),
            Tab(text: "Upcoming (${upcomingPlans.length})"),
            Tab(text: "Previous (${previousPlans.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(yesterdayPlans),
          _buildTab(
            todayPlans,
            isToday: true,
          ),
          _buildTab(tomorrowPlans),
          _buildTab(upcomingPlans),
          _buildTab(
            previousPlans,
            searchable: true,
          ),
        ],
      ),
    );
  }
}