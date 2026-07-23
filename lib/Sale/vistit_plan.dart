// File: lib/pages/visit_plan_page.dart

import 'package:flutter/material.dart';
import '../api/get_visitplan_api.dart';
import 'package:intl/intl.dart';

import 'models/customer_visit_model.dart';
import 'sale_visit_check_in.dart';

// 🗺️ Import packages for OpenStreetMap view
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

      int sortByPendingStatus(VisitPlan a, VisitPlan b) {
        final aPending = a.synced.toLowerCase() != "yes" && a.status.toLowerCase() != "done";
        final bPending = b.synced.toLowerCase() != "yes" && b.status.toLowerCase() != "done";

        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
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

            // 🗺️ INDIVIDUAL MAP BUTTON
            if (plan.gpsLocation.isNotEmpty && plan.gpsLocation.contains(',')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.map_rounded, size: 16, color: Color(0xFF1D4ED8)),
                  label: const Text(
                    "View Location Map",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    try {
                      final parts = plan.gpsLocation.split(',');
                      final lat = double.parse(parts[0].trim());
                      final lng = double.parse(parts[1].trim());

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SingleLocationMapScreen(
                            targetLat: lat,
                            targetLng: lng,
                            locationTitle: plan.cardName,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Invalid GPS Coordinate format")),
                      );
                    }
                  },
                ),
              ),
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
  /// TAB DYNAMIC VIEW CONTENT DISPATCHER (WITH LIST / MAP TOGGLE)
  /// =============================================================
  Widget _buildTab(
      List<VisitPlan> plans, {
        bool searchable = false,
        bool isToday = false,
      }) {
    return _TabContentView(
      plans: searchable ? filteredPlans : plans,
      isLoading: isLoading,
      searchable: searchable,
      isToday: isToday,
      onSearchChanged: _filterSearch,
      onRefresh: _loadVisitPlans,
      buildCardCallback: (plan) => _buildCard(plan, isToday: isToday),
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
          _buildTab(todayPlans, isToday: true),
          _buildTab(tomorrowPlans),
          _buildTab(upcomingPlans),
          _buildTab(previousPlans, searchable: true),
        ],
      ),
    );
  }
}

/// =============================================================
/// STATEFUL HELPER TO TOGGLE BETWEEN LIST VIEW & MULTI-PIN MAP VIEW
/// =============================================================
class _TabContentView extends StatefulWidget {
  final List<VisitPlan> plans;
  final bool isLoading;
  final bool searchable;
  final bool isToday;
  final Function(String) onSearchChanged;
  final Future<void> Function() onRefresh;
  final Widget Function(VisitPlan) buildCardCallback;

  const _TabContentView({
    required this.plans,
    required this.isLoading,
    required this.searchable,
    required this.isToday,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.buildCardCallback,
  });

  @override
  State<_TabContentView> createState() => _TabContentViewState();
}

class _TabContentViewState extends State<_TabContentView> {
  bool _isMapView = false; // Toggle state: false = List View, true = Map View

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.plans.isEmpty) {
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
        if (widget.searchable)
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E3A8A),
            child: TextField(
              onChanged: widget.onSearchChanged,
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

        // 🔘 TOP TOGGLE BAR (List View vs Map View Switcher)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                "Showing ${widget.plans.length} locations",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const Spacer(),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isMapView = false),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isMapView ? const Color(0xFF1E3A8A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.list_alt_rounded, size: 14, color: !_isMapView ? Colors.white : Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text("List", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: !_isMapView ? Colors.white : Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isMapView = true),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isMapView ? const Color(0xFF1E3A8A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map_rounded, size: 14, color: _isMapView ? Colors.white : Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text("Map View", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isMapView ? Colors.white : Colors.grey.shade700)),
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
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // 🔄 CONTENT DISPLAY: EITHER LIST OR MULTI-PIN MAP
        Expanded(
          child: _isMapView
              ? _MultiPinMapScreen(plans: widget.plans)
              : RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.plans.length,
              itemBuilder: (context, index) {
                return widget.buildCardCallback(widget.plans[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// =============================================================
/// OPENSTREETMAP MULTI-PIN SCREEN FOR THE TAB
/// =============================================================
class _MultiPinMapScreen extends StatelessWidget {
  final List<VisitPlan> plans;

  const _MultiPinMapScreen({required this.plans});

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final validPlans = plans.where((p) => p.gpsLocation.isNotEmpty && p.gpsLocation.contains(',')).toList();

    if (validPlans.isEmpty) {
      return const Center(
        child: Text("No valid GPS coordinates available for this tab list.", style: TextStyle(color: Colors.grey)),
      );
    }

    LatLng centerPoint = const LatLng(11.5768812, 104.8865285);
    try {
      final firstCoords = validPlans.first.gpsLocation.split(',');
      centerPoint = LatLng(double.parse(firstCoords[0].trim()), double.parse(firstCoords[1].trim()));
    } catch (_) {}

    return FlutterMap(
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: 14.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        // 🛡️ Prevents crashing if gestures push bounds out of bounds
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-90, -180),
            const LatLng(90, 180),
          ),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.lhcdms',
          maxNativeZoom: 18,
          retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
          tileBuilder: (context, widget, tile) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: widget,
            );
          },
        ),
        MarkerLayer(
          markers: validPlans.map((plan) {
            // 🛡️ Safely parse coordinates with fallback to prevent NaN/Infinity crashes
            LatLng markerCoord = centerPoint;
            try {
              final parts = plan.gpsLocation.split(',');
              if (parts.length >= 2) {
                final lat = double.parse(parts[0].trim());
                final lng = double.parse(parts[1].trim());

                // Check if coordinates are finite and valid
                if (lat.isFinite && lng.isFinite && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                  markerCoord = LatLng(lat, lng);
                }
              }
            } catch (_) {
              markerCoord = centerPoint; // Fallback safely
            }

            return Marker(
              point: markerCoord,
              width: 140,
              height: 80,
              alignment: Alignment.topCenter, // Ensures correct anchor point mapping during zoom scales
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(plan.cardName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Code: ${plan.cardCode}", style: const TextStyle(fontSize: 12)),
                          Text("Phone: ${plan.tel1}", style: const TextStyle(fontSize: 12)),
                          Text("Address: ${plan.fullAddress}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openInGoogleMaps(markerCoord.latitude, markerCoord.longitude);
                          },
                          icon: const Icon(Icons.navigation, size: 14),
                          label: const Text("Navigate"),
                        ),
                      ],
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF1E3A8A), width: 0.8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Text(
                        plan.cardName.isNotEmpty ? plan.cardName : plan.cardCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.location_pin, size: 30, color: Colors.red),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// =============================================================
/// SINGLE LOCATION MAP SCREEN FOR INDIVIDUAL CARD BUTTONS
/// =============================================================
class SingleLocationMapScreen extends StatelessWidget {
  final double targetLat;
  final double targetLng;
  final String locationTitle;

  const SingleLocationMapScreen({
    super.key,
    required this.targetLat,
    required this.targetLng,
    required this.locationTitle,
  });

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng pointLocation = LatLng(targetLat, targetLng);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locationTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: pointLocation,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.lhcdms',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: pointLocation,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () => _openInGoogleMaps(targetLat, targetLng),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          "Open G-Maps",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}