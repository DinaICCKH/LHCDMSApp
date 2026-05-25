// File: lib/pages/visit_plan_page.dart

import 'package:flutter/material.dart';
import '../api/get_visitplan_api.dart';
import 'package:intl/intl.dart';

import 'models/customer_visit_model.dart';
import 'sale_visit_check_in.dart'; // ✅ UPDATED: Imported the new file name

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

  /// ================= LOAD VISIT PLANS
  Future<void> _loadVisitPlans() async {
    setState(() => isLoading = true);

    try {
      final plans = await VisitPlanApi.getLocalVisitPlans();
      final now = DateTime.now();

      bool sameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      setState(() {
        allPlans = plans;

        todayPlans = plans.where((p) => sameDay(p.visitDate, now)).toList();

        tomorrowPlans = plans
            .where((p) => sameDay(p.visitDate, now.add(const Duration(days: 1))))
            .toList();

        yesterdayPlans = plans
            .where((p) => sameDay(p.visitDate, now.subtract(const Duration(days: 1))))
            .toList();

        upcomingPlans = plans.where((p) {
          return p.visitDate.isAfter(now.add(const Duration(days: 1)));
        }).toList();

        previousPlans = plans.where((p) {
          return p.visitDate.isBefore(now.subtract(const Duration(days: 1)));
        }).toList();

        filteredPlans = plans;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading visit plans: $e");
      setState(() => isLoading = false);
    }
  }

  /// ================= SEARCH
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
    });
  }

  /// ================= DETAIL ROW
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label :",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(VisitPlan plan, {bool isToday = false}) {
    final isDone = plan.status.toLowerCase() == "done";
    final isSynced = plan.synced.toLowerCase() == "yes";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isDone ? Colors.green.shade100 : Colors.blue.shade100,
          child: Icon(
            isDone ? Icons.check_circle : Icons.location_on,
            color: isDone ? Colors.green : Colors.blue,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.cardCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.cardName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  dateFormat.format(plan.visitDate),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    plan.tel1.isEmpty ? "-" : plan.tel1,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          _row("Address", plan.fullAddress),
          _row("Remark", plan.remark),
          _row("Status", plan.status),
          _row("Synced", plan.synced),
          _row("Doc No", plan.docNum),
          _row("Doc Year", plan.docYear.toString()),
          _row("Detail Entry", plan.detailEntry.toString()),
          if (isToday)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  icon: Icon(isSynced ? Icons.check_circle : Icons.navigation),
                  label: Text(
                    isSynced ? "Already Visited" : "Start Visit",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSynced ? Colors.grey : const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSynced
                      ? null
                      : () {
                    // ✅ UPDATED: Links smoothly to SaleVisitCheckInPage
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
    );
  }

  /// ================= TAB CONTENT
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
      return const Center(
        child: Text(
          "No visit plans",
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    return Column(
      children: [
        if (searchable)
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: "Search customer, code, phone...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVisitPlans,
            child: ListView.builder(
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

  /// ================= UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Visit Plan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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