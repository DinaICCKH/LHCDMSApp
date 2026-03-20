import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Master/customer_master.dart';
import 'Master/item_master.dart';
import 'Sale/sale_unplan.dart';
import 'api/get_item_api.dart';
import 'login/login.dart';
import 'sync/sync.dart';

void main() {
  runApp(const DMSApp());
}

class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DMS Modern Dashboard",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Roboto",
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const LoginPageWrapper(),
    );
  }
}

/// Wrapper to show Login page first
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
  Timer? sessionTimer;
  final int sessionTimeoutMinutes = 10;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startSessionTimer();
  }

  @override
  void dispose() {
    sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    sessionTimer?.cancel();
    sessionTimer = Timer(Duration(minutes: sessionTimeoutMinutes), () {
      _logout(autoLogout: true);
    });
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("name") ?? "Unknown User";
      companyName = prefs.getString("companyName") ?? "";
    });
  }

  Future<void> _logout({bool autoLogout = false}) async {
    bool shouldLogout = true;

    if (!autoLogout) {
      shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.exit_to_app, size: 50, color: Color(0xFF1976D2)),
                const SizedBox(height: 10),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF90CAF9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Text("Cancel"),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Text("Logout"),
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
      sessionTimer?.cancel();
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

  Widget notificationBar(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF90CAF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _resetSessionTimer,
      onPanDown: (_) => _resetSessionTimer(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    /// TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white70,
                              child: const Icon(Icons.person,
                                  size: 26, color: Colors.blue),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName,
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(companyName,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble, color: Colors.black87),
                            const SizedBox(width: 12),
                            const Icon(Icons.notifications,
                                color: Colors.black87),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _logout(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.exit_to_app,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    notificationBar(
                        "2 Orders Pending Approval, 5 Customers Not Visited Today"),

                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Reports",
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    const ReportSection(),

                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Main Menu",
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    MenuSection(),

                    const SizedBox(height: 20),
                    const AppInfoRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// REPORT SECTION
////////////////////////////////////////////////////////

class ReportSection extends StatelessWidget {
  const ReportSection({super.key});

  Widget reportCard(String title, String value, IconData icon, double trend) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(
                  trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trend >= 0 ? Colors.greenAccent : Colors.redAccent,
                  size: 14,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            reportCard("Total Sale", "120", Icons.shopping_cart, 5),
            reportCard("Total Visit", "35", Icons.map, -2),
            reportCard("Total Item", "80", Icons.inventory, 0),
          ],
        ),
        Row(
          children: [
            reportCard("Pending Orders", "5", Icons.pending_actions, 3),
            reportCard("Pending Visits", "2", Icons.schedule, -1),
            reportCard("Stock Alert", "10", Icons.warning, 0),
          ],
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////
/// MENU SECTION
////////////////////////////////////////////////////////

class MenuSection extends StatelessWidget {
  MenuSection({super.key});

  Widget menuCard(String title, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            menuCard("Sale Order", Icons.add_shopping_cart, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SaleUnplanPage()));
            }),
            menuCard("Visit Plan", Icons.map),
            menuCard("Customer", Icons.people, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerMasterPage()),
              );
            }),
          ],
        ),
        Row(
          children: [
            menuCard("Item", Icons.inventory, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ItemMasterPage()),
              );
            }),

            menuCard("Sync Data", Icons.sync, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SyncDataPage()));
            }),
            menuCard("News / Updates", Icons.article),
          ],
        ),
        Row(
          children: [
            menuCard("Exchange Rate", Icons.currency_exchange),
          ],
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////
/// APP INFO
////////////////////////////////////////////////////////

class AppInfoRow extends StatelessWidget {
  const AppInfoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "ICCKH | Version v1.0.1 | © 2026 ICCKH. All rights reserved.",
      style: TextStyle(color: Colors.black54, fontSize: 12),
      textAlign: TextAlign.center,
    );
  }
}