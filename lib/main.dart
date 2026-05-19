import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Master/customer_master.dart';
import 'Master/item_master.dart';
import 'Sale/sale_unplan.dart';
import 'Sale/vistit_plan.dart';
import 'api/login_api.dart';
import 'login/login.dart';
import 'sync/sync.dart';
import 'package:permission_handler/permission_handler.dart';

/// ✅ ADDED: Request camera + location on startup
Future<void> _requestAppPermissions() async {
  final statuses = await [
    Permission.camera,
    Permission.location,
  ].request();

  /// Optional: print result for debugging
  statuses.forEach((permission, status) {
    print("Permission $permission => $status");
  });
}

/// ✅ ADDED: call _requestAppPermissions() before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestAppPermissions();
  runApp(const DMSApp());
}

class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Roboto",
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const LoginPageWrapper(),
    );
  }
}

class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

////////////////////////////////////////////////////////
/// DASHBOARD PAGE
////////////////////////////////////////////////////////

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "Loading...";
  String companyName = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = SessionManager.currentUser;
    if (!mounted) return;
    setState(() {
      userName = user?.name ?? "Unknown User";
      companyName = user?.companyName ?? "";
    });
  }

  Future<void> _logout({bool autoLogout = false}) async {
    bool shouldLogout = true;

    if (!autoLogout) {
      shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.exit_to_app,
                    size: 50, color: Color(0xFF1976D2)),
                const SizedBox(height: 12),
                const Text(
                  "Confirm Logout",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Are you sure you want to logout?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF1976D2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text("Cancel",
                            style: TextStyle(
                                color: Color(0xFF1976D2))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
          false;
    }

    if (shouldLogout) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 680;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: _buildNotificationBar(
                    "2 Orders Pending Approval, 5 Customers Not Visited Today"),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      16, 4, 16, isSmallScreen ? 4 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Reports"),
                      const SizedBox(height: 6),
                      ReportSection(isSmallScreen: isSmallScreen),
                      const SizedBox(height: 12),
                      _sectionTitle("Main Menu"),
                      const SizedBox(height: 6),
                      MenuSection(
                        isSmallScreen: isSmallScreen,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const AppInfoRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () async {
                final choice = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(0, 80, 300, 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  items: [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                );
                if (choice == 'logout') _logout();
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.person,
                        size: 26, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        if (companyName.isNotEmpty)
                          Text(
                            companyName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _headerIconBtn(Icons.chat_bubble_outline),
              const SizedBox(width: 8),
              _headerIconBtn(Icons.notifications_none),
              const SizedBox(width: 4),
              _headerIconBtn(Icons.logout, onTap: () => _logout()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildNotificationBar(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3),
    );
  }
}

////////////////////////////////////////////////////////
/// REPORT SECTION  —  FULLY RESPONSIVE
////////////////////////////////////////////////////////

class ReportSection extends StatelessWidget {
  final bool isSmallScreen;
  const ReportSection({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ReportData("Total Sale", "120", Icons.shopping_cart, true),
      _ReportData("Total Visit", "35", Icons.map, false),
      _ReportData("Total Item", "80", Icons.inventory, true),
      _ReportData("Pending Orders", "5", Icons.pending_actions, true),
      _ReportData("Pending Visits", "2", Icons.schedule, false),
      _ReportData("Stock Alert", "10", Icons.warning_amber, true),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: isSmallScreen ? 1.1 : 1.05,
      ),
      itemBuilder: (_, i) => _ReportCard(data: cards[i]),
    );
  }
}

class _ReportData {
  final String title;
  final String value;
  final IconData icon;
  final bool isUp;
  _ReportData(this.title, this.value, this.icon, this.isUp);
}

class _ReportCard extends StatelessWidget {
  final _ReportData data;
  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x331976D2), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(data.icon, color: Colors.white70, size: 20),
          Text(
            data.title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  data.value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                data.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: data.isUp ? Colors.greenAccent : Colors.redAccent,
                size: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// Request camera permission
////////////////////////////////////////////////////////

Future<bool> requestCameraPermission() async {
  var status = await Permission.camera.status;
  if (status.isGranted) {
    return true;
  } else {
    var result = await Permission.camera.request();
    return result.isGranted;
  }
}

/// ✅ ADDED: Request location permission individually
Future<bool> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (status.isGranted) {
    return true;
  } else {
    var result = await Permission.location.request();
    return result.isGranted;
  }
}

////////////////////////////////////////////////////////
/// MENU SECTION  —  FULLY RESPONSIVE
////////////////////////////////////////////////////////

class MenuSection extends StatelessWidget {
  final bool isSmallScreen;

  const MenuSection({
    super.key,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(
        "Sync Data",
        Icons.sync_rounded,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SyncDataPage())),
      ),
      _MenuItem(
        "Sale Order",
        Icons.add_shopping_cart_rounded,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SaleUnplanPage())),
      ),
      _MenuItem(
        "Visit Plan",
        Icons.map_rounded,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VisitPlanPage())),
      ),
      _MenuItem(
        "Customer",
        Icons.people_rounded,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerMasterPage())),
      ),
      _MenuItem(
        "Item",
        Icons.inventory_2_rounded,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ItemMasterPage())),
      ),
      _MenuItem("Sale Listing", Icons.article_rounded),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: isSmallScreen ? 1.0 : 0.95,
          ),
          itemBuilder: (_, i) => _MenuCard(item: menuItems[i]),
        ),
        const SizedBox(height: 6),
        _FullWidthCard(
          title: 'Statistics',
          icon: Icons.bar_chart_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  _MenuItem(this.title, this.icon, {this.onTap});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x221976D2), blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF1976D2),
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullWidthCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _FullWidthCard({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x440D47A1),
                blurRadius: 10,
                offset: Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// APP INFO FOOTER
////////////////////////////////////////////////////////

class AppInfoRow extends StatelessWidget {
  const AppInfoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Color(0xFFBBDEFB), width: 1)),
      ),
      child: const Text(
        "ICCKH | Version v1.0.1 | © 2026 ICCKH. All rights reserved.",
        style: TextStyle(color: Colors.black45, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}