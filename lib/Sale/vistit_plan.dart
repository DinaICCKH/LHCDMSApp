import 'package:flutter/material.dart';
import 'package:kuberadmsdn/Sale/sale_visit_page.dart';
import '../api/get_visitplan_api.dart';
import 'package:intl/intl.dart';

import 'models/customer_visit_model.dart';

class VisitPlanPage extends StatefulWidget {
  const VisitPlanPage({super.key});

  @override
  State<VisitPlanPage> createState() => _VisitPlanPageState();
}

class _VisitPlanPageState extends State<VisitPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  List<VisitPlan> todayPlans = [];
  List<VisitPlan> tomorrowPlans = [];
  List<VisitPlan> yesterdayPlans = [];
  List<VisitPlan> upcomingPlans = [];
  List<VisitPlan> previousPlans = [];

  List<VisitPlan> allPlans = [];
  List<VisitPlan> filteredPlans = [];
  String searchQuery = "";

  final DateFormat dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _loadVisitPlans();
  }

  Future<void> _loadVisitPlans() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<VisitPlan> plans = await VisitPlanApi.getLocalVisitPlans();
      DateTime now = DateTime.now();

      todayPlans = plans.where((v) {
        final d = v.visitDate;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      tomorrowPlans = plans.where((v) {
        final d = v.visitDate;
        final tomorrow = now.add(const Duration(days: 1));
        return d.year == tomorrow.year &&
            d.month == tomorrow.month &&
            d.day == tomorrow.day;
      }).toList();

      yesterdayPlans = plans.where((v) {
        final d = v.visitDate;
        final yesterday = now.subtract(const Duration(days: 1));
        return d.year == yesterday.year &&
            d.month == yesterday.month &&
            d.day == yesterday.day;
      }).toList();

      upcomingPlans = plans.where((v) => v.visitDate.isAfter(now.add(const Duration(days: 1)))).toList();

      previousPlans = plans.where((v) =>
      !todayPlans.contains(v) &&
          !tomorrowPlans.contains(v) &&
          !yesterdayPlans.contains(v) &&
          !upcomingPlans.contains(v)).toList();

      allPlans = plans;
      filteredPlans = previousPlans;
    } catch (e) {
      print("Error loading visit plans: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredPlans = previousPlans.where((plan) {
        return plan.cardCode.toLowerCase().contains(query.toLowerCase()) ||
            plan.cardName.toLowerCase().contains(query.toLowerCase()) ||
            plan.remark.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildExpandableCard(VisitPlan plan, {bool isToday = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: Icon(
          plan.status == 'Done' ? Icons.check_circle : Icons.location_on,
          color: plan.status == 'Done' ? Colors.green : Colors.blue,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${plan.cardCode.isNotEmpty ? plan.cardCode : 'Unknown'} - ${plan.cardName.isNotEmpty ? plan.cardName : '-'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    dateFormat.format(plan.visitDate),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    "Phone: ${plan.tel1.isNotEmpty ? plan.tel1 : '-'}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DocYear: ${plan.docYear}", style: const TextStyle(fontSize: 12)),
                Text("Remark: ${plan.remark.isNotEmpty ? plan.remark : '-'}", style: const TextStyle(fontSize: 12)),
                Text("Synced: ${plan.synced}", style: const TextStyle(fontSize: 12)),
                Text("DetailEntry: ${plan.detailEntry}", style: const TextStyle(fontSize: 12)),
                Text("ReasonType: ${plan.reasonType.isNotEmpty ? plan.reasonType : '-'}", style: const TextStyle(fontSize: 12)),
                if (isToday)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaleFromVisitPage(
                              customer: CustomerVisit(
                                cardCode: plan.cardCode,
                                cardName: plan.cardName,
                                phone: plan.tel1,
                                fullAddress: plan.fullAddress,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text("Visit"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<VisitPlan> plans, {bool isSearchable = false, bool isTodayTab = false}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    List<VisitPlan> displayList = isSearchable ? filteredPlans : plans;
    if (displayList.isEmpty) {
      return const Center(child: Text("No visit plans", style: TextStyle(fontSize: 14)));
    }
    return Column(
      children: [
        if (isSearchable)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search by Customer, Code, or Remark",
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVisitPlans,
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) => _buildExpandableCard(displayList[index], isToday: isTodayTab),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text("Visit Plan", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: "Yesterday"),
            Tab(text: "Today"),
            Tab(text: "Tomorrow"),
            Tab(text: "Upcoming"),
            Tab(text: "Previous Data"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(yesterdayPlans),
          _buildTabContent(todayPlans, isTodayTab: true),
          _buildTabContent(tomorrowPlans),
          _buildTabContent(upcomingPlans),
          _buildTabContent(previousPlans, isSearchable: true),
        ],
      ),
    );
  }
}