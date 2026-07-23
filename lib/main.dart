import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Master/customer_master.dart';
import 'Master/item_master.dart';
import 'Sale/sale_unplan.dart';
import 'Sale/saleorder_listing.dart';
import 'Sale/sales_reports_page.dart';
import 'Sale/visited_list_page.dart';
import 'Sale/vistit_plan.dart';
import 'api/login_api.dart';
import 'login/login.dart';
import 'sync/sync.dart';
import 'api/get_saleorder_summary_api.dart';
import 'api/get_customer_api.dart';
import 'api/get_item_api.dart';
import 'api/get_visitplan_api.dart';

Future<void> _requestAppPermissions() async {
  final statuses = await [Permission.camera, Permission.location].request();
  statuses.forEach((permission, status) {
    debugPrint("Permission $permission => $status");
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestAppPermissions();
  runApp(const DMSApp());
}

// ─── App Root ────────────────────────────────────────────────────────────────

class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "Roboto",
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          background: const Color(0xFFF1F5F9),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ─── Design Tokens ───────────────────────────────────────────────────────────

abstract class _T {
  static const navy      = Color(0xFF0D1B3E);
  static const navyMid   = Color(0xFF1A2D5A);
  static const blue      = Color(0xFF1565C0);
  static const blueLight = Color(0xFF1E88E5);
  static const blueTint  = Color(0xFFE3F0FF);
  static const bg        = Color(0xFFF1F5F9);
  static const card      = Colors.white;
  static const divider   = Color(0xFFE8EDF4);
  static const textPrimary   = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);
  static const amber   = Color(0xFFF59E0B);
  static const teal    = Color(0xFF0D9488);
  static const violet  = Color(0xFF7C3AED);
  static const rose    = Color(0xFFE11D48);
  static const emerald = Color(0xFF059669);
  static const cyan    = Color(0xFF0891B2);
  static const orange  = Color(0xFFEA580C);
}

// ─── Dashboard Page ───────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String userName    = "Loading...";
  String companyName = "";
  bool _isReloading  = false;

  int    itemCount        = 0;
  int    customerCount    = 0;
  int    visitPlanCount   = 0;
  double totalSaleAmount  = 0.0;
  int    totalQtyInvoice  = 0;
  int    pendingSyncCount = 0;

  AnimationController? _fadeCtrl;
  Animation<double>?   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl!,
      curve: Curves.easeOut,
    );
    _loadUser();
    _loadSyncMetrics().then((_) {
      if (mounted) _fadeCtrl?.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = SessionManager.currentUser;
    if (!mounted) return;
    setState(() {
      userName    = user?.name        ?? "Unknown User";
      companyName = user?.companyName ?? "";
    });
  }

  Future<void> _loadSyncMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    int localItems = 0, localCustomers = 0, localVisitPlans = 0;

    try { localItems      = (await ItemApi.getLocalItems()).length;        } catch (_) {}
    try { localCustomers  = (await CustomerApi.getLocalCustomers()).length; } catch (_) {}
    try { localVisitPlans = (await VisitPlanApi.getLocalVisitPlans()).length; } catch (_) {}

    double amt = 0.0;
    int qty = 0, pending = 0;
    final jsonStr = prefs.getString(SaleSummaryApi.localKey);
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        if (list.isNotEmpty) {
          final obj = SaleSummary.fromJson(list.first as Map<String, dynamic>);
          amt     = obj.totalAmt;
          qty     = obj.total;
          pending = obj.pendingSync;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      itemCount        = localItems;
      customerCount    = localCustomers;
      visitPlanCount   = localVisitPlans;
      totalSaleAmount  = amt;
      totalQtyInvoice  = qty;
      pendingSyncCount = pending;
    });
  }

  Future<void> _handleRefresh() async {
    if (_isReloading) return;
    setState(() => _isReloading = true);
    try {
      await SaleSummaryApi.fetchAndStoreSaleSummary(password: "123456");
    } catch (_) {}
    await _loadSyncMetrics();
    if (!mounted) return;
    setState(() => _isReloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text("Dashboard synced",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _T.emerald,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout({bool autoLogout = false}) async {
    bool should = true;
    if (!autoLogout) {
      should = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _LogoutDialog(
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel:  () => Navigator.pop(ctx, false),
        ),
      ) ?? false;
    }
    if (should) {
      final p = await SharedPreferences.getInstance();
      await p.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  String _formattedDate() {
    const months = ["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"];
    const days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    final now = DateTime.now();
    return "${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}";
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final anim = _fadeAnim ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _HeroHeader(
            userName:    userName,
            companyName: companyName,
            greeting:    _greeting(),
            date:        _formattedDate(),
            isReloading: _isReloading,
            onSync: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SyncDataPage(
                    initialCounts: {
                      "Item":         itemCount,
                      "Customer":     customerCount,
                      "Visit Plan":   visitPlanCount,
                      "Sale Summary": totalQtyInvoice,
                    },
                  ),
                ),
              );
              _loadSyncMetrics();
            },
            onNotification: () {},
            onAvatarTap: () async {
              final choice = await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(16, 120, 200, 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 10,
                items: [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(children: const [
                      Icon(Icons.logout_rounded, color: _T.rose, size: 17),
                      SizedBox(width: 10),
                      Text('Log Out',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _T.textPrimary)),
                    ]),
                  ),
                ],
              );
              if (choice == 'logout') _logout();
            },
          ),
          Expanded(
            child: FadeTransition(
              opacity: anim,
              child: RefreshIndicator(
                color: _T.blue,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Overview section label ──
                      _SectionLabel(
                        label: "Overview",
                        trailing: _isReloading
                            ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _T.blue),
                        )
                            : GestureDetector(
                          onTap: _handleRefresh,
                          child: const Icon(Icons.refresh_rounded,
                              color: _T.blue, size: 18),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // ── Sale hero card (shorter) ──
                      _SaleHeroCard(
                        amount:     totalSaleAmount,
                        qtyInvoice: totalQtyInvoice,
                        onTap: () => _push(const SaleOrderListingPage()),
                      ),
                      const SizedBox(height: 5),

                      // ── Metrics grid — 1 row of 4 ──
                      _MetricsGrid(
                        itemCount:        itemCount,
                        customerCount:    customerCount,
                        visitPlanCount:   visitPlanCount,
                        pendingSyncCount: pendingSyncCount,
                        onItemTap: () => _push(const ItemMasterPage()),
                        onCustomerTap: () => _push(const CustomerMasterPage()),
                        onVisitPlanTap: () => _push(const VisitPlanPage()),
                        onPendingSyncTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SyncDataPage(
                                initialCounts: {
                                  "Item":         itemCount,
                                  "Customer":     customerCount,
                                  "Visit Plan":   visitPlanCount,
                                  "Sale Summary": totalQtyInvoice,
                                },
                              ),
                            ),
                          );
                          _loadSyncMetrics();
                        },
                      ),

                      const SizedBox(height: 5),
                      const _SectionLabel(label: "Operations"),
                      const SizedBox(height: 5),

                      _OperationsGrid(
                        itemCount:       itemCount,
                        customerCount:   customerCount,
                        visitPlanCount:  visitPlanCount,
                        totalQtyInvoice: totalQtyInvoice,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const _AppFooter(),
        ],
      ),
    );
  }
}

// ─── Hero Header  (CHANGED: bright blue gradient) ─────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String userName;
  final String companyName;
  final String greeting;
  final String date;
  final bool isReloading;
  final VoidCallback onSync;
  final VoidCallback onNotification;
  final VoidCallback onAvatarTap;

  const _HeroHeader({
    required this.userName,
    required this.companyName,
    required this.greeting,
    required this.date,
    required this.isReloading,
    required this.onSync,
    required this.onNotification,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ CHANGED: bright vivid blue gradient instead of dark navy
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -30, right: -20,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -40, left: 40,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              // ✅ Slightly reduced bottom padding to keep header compact
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                Colors.white.withOpacity(0.18),
                                child: const Icon(Icons.person_rounded,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.80),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    )),
                                const SizedBox(height: 1),
                                Text(userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _HdrBtn(
                            icon: isReloading
                                ? Icons.hourglass_empty_rounded
                                : Icons.sync_rounded,
                            onTap: onSync,
                            highlighted: true,
                          ),
                          const SizedBox(width: 8),
                          _HdrBtn(
                            icon: Icons.notifications_none_rounded,
                            onTap: onNotification,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (companyName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              )),
                        ),
                      const Spacer(),
                      Text(date,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HdrBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  const _HdrBtn(
      {required this.icon, required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: highlighted
              ? Colors.white.withOpacity(0.20)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Sale Hero Card  (CHANGED: shorter vertical padding & smaller font) ────────

class _SaleHeroCard extends StatefulWidget {
  final double amount;
  final int qtyInvoice;
  final VoidCallback onTap;
  const _SaleHeroCard(
      {required this.amount, required this.qtyInvoice, required this.onTap});

  @override
  State<_SaleHeroCard> createState() => _SaleHeroCardState();
}

class _SaleHeroCardState extends State<_SaleHeroCard> {
  bool _pressed = false;
  bool _isAmountHidden = false; // Add this inside your State class

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 30, bottom: -25,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // ✅ CHANGED: reduced vertical padding from 18 → 12 (shorter card)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "TOTAL SALES",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 👁️ Banking-style Hide/Show Icon Button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAmountHidden = !_isAmountHidden;
                                });
                              },
                              child: Icon(
                                _isAmountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // ✅ Conditional masking based on state
                        Text(
                          _isAmountHidden ? "\$ ••••••" : "\$${widget.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.qtyInvoice} invoiced qty",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("View",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 9,
                                color: Colors.white.withOpacity(0.5)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Metrics Grid  (CHANGED: 4 columns → 1 row) ───────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final int itemCount;
  final int customerCount;
  final int visitPlanCount;
  final int pendingSyncCount;
  final VoidCallback onItemTap;
  final VoidCallback onCustomerTap;
  final VoidCallback onVisitPlanTap;
  final VoidCallback onPendingSyncTap;

  const _MetricsGrid({
    required this.itemCount,
    required this.customerCount,
    required this.visitPlanCount,
    required this.pendingSyncCount,
    required this.onItemTap,
    required this.onCustomerTap,
    required this.onVisitPlanTap,
    required this.onPendingSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData("Items",        "$itemCount",
          Icons.inventory_2_rounded,             _T.amber,  const Color(0xFFFFFBEB), onItemTap),
      _MetricData("Customers",    "$customerCount",
          Icons.supervised_user_circle_rounded,  _T.teal,   const Color(0xFFECFDF5), onCustomerTap),
      _MetricData("Visit Plans",  "$visitPlanCount",
          Icons.explore_rounded,                 _T.violet, const Color(0xFFF5F3FF), onVisitPlanTap),
      _MetricData("Pending Sync", "$pendingSyncCount",
          Icons.cloud_upload_rounded,            _T.rose,   const Color(0xFFFFF1F2), onPendingSyncTap),
    ];

    // ✅ CHANGED: crossAxisCount 2 → 4  (single row), compact aspect ratio
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82, // tall-ish cards fit icon + label + value
      ),
      itemBuilder: (_, i) => _MetricCard(data: metrics[i]),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;
  const _MetricData(
      this.label, this.value, this.icon, this.accent, this.bg, this.onTap);
}

class _MetricCard extends StatefulWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.data.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(14),
            // ✅ CHANGED: top accent border instead of left (fits portrait card)
            border: Border(
              top: BorderSide(color: widget.data.accent, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.data.bg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.data.icon,
                      color: widget.data.accent, size: 16),
                ),
                const SizedBox(height: 6),
                Text(widget.data.value,
                    style: const TextStyle(
                      color: _T.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    )),
                const SizedBox(height: 2),
                Text(widget.data.label,
                    style: const TextStyle(
                      color: _T.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Operations Grid ──────────────────────────────────────────────────────────

class _OperationsGrid extends StatelessWidget {
  final int itemCount;
  final int customerCount;
  final int visitPlanCount;
  final int totalQtyInvoice;

  const _OperationsGrid({
    required this.itemCount,
    required this.customerCount,
    required this.visitPlanCount,
    required this.totalQtyInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final ops = [
      _OpItem("Sale Order",   Icons.add_shopping_cart_rounded,
          const Color(0xFFDBEAFE), _T.blue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SaleUnplanPage()))),
      _OpItem("Sale Listing", Icons.description_rounded,
          const Color(0xFFFEF3C7), _T.orange,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SaleOrderListingPage()))),
      _OpItem("Visit Plan",   Icons.map_rounded,
          const Color(0xFFDCFCE7), _T.emerald,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VisitPlanPage()))),
      _OpItem("Visited List", Icons.fact_check_rounded,
          const Color(0xFFF5F3FF), _T.violet,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VisitedListPage()))),
      _OpItem("Customers",    Icons.supervised_user_circle_rounded,
          const Color(0xFFCCFBF1), _T.cyan,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CustomerMasterPage()))),
      _OpItem("Item Master",  Icons.category_rounded,
          const Color(0xFFFFE4E6), _T.rose,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ItemMasterPage()))),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ops.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) => _OpCard(item: ops[i]),
        ),
        const SizedBox(height: 12),
        _ReportBanner(
          onTap: () {
            // 🚀 Navigate directly to your SalesReportsPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SalesReportsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OpItem {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;
  const _OpItem(this.title, this.icon, this.iconBg, this.iconColor,
      {this.onTap});
}

class _OpCard extends StatefulWidget {
  final _OpItem item;
  const _OpCard({required this.item});

  @override
  State<_OpCard> createState() => _OpCardState();
}

class _OpCardState extends State<_OpCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.item.onTap?.call(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: widget.item.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.item.icon,
                    color: widget.item.iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(widget.item.title,
                    style: const TextStyle(
                      color: _T.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _ReportBanner({required this.onTap});

  @override
  State<_ReportBanner> createState() => _ReportBannerState();
}

class _ReportBannerState extends State<_ReportBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: _T.navy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _T.navy.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Reports",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        )),
                    SizedBox(height: 2),
                    Text("Analytics & insights",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white.withOpacity(0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3.5, height: 16,
              decoration: BoxDecoration(
                color: _T.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  color: _T.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                )),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Logout Dialog ────────────────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _LogoutDialog(
      {required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.rose.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 36, color: _T.rose),
            ),
            const SizedBox(height: 16),
            const Text("Sign Out?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _T.textPrimary,
                )),
            const SizedBox(height: 6),
            const Text("You will be returned to the login screen.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: _T.textSecondary,
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: _T.divider, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onCancel,
                    child: const Text("Cancel",
                        style: TextStyle(
                            color: _T.textSecondary,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onConfirm,
                    child: const Text("Sign Out",
                        style:
                        TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Footer ───────────────────────────────────────────────────────────────

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _T.divider, width: 1)),
      ),
      child: const Text(
        "ICCKH  |  v1.0.1  |  2026",
        style: TextStyle(
          color: _T.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
