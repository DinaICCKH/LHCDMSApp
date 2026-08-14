import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuberadmsdn/Sale/VistitPlan/vistit_plan.dart';
import 'package:kuberadmsdn/api/save_itemlogpromotion_api.dart';
import '../../api/get_customer_api.dart' as api;
import '../../api/get_item_api.dart' as itemApi;
import '../../api/get_promotionresult_api.dart';
import '../../api/get_visitplan_api.dart';
import 'sale_unplan_controller.dart';
import '../models/sale_order_model.dart';

// ─────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────
const _kPrimary  = Color(0xFF1565C0);
const _kBg       = Color(0xFFF0F4FA);
const _kCard     = Colors.white;
const _kDanger   = Color(0xFFE53935);
const _kSuccess  = Color(0xFF43A047);
const _kOrange   = Color(0xFFFB8C00);

class SaleUnplanPage extends StatefulWidget {
  final api.Customer? customer;
  final int? detailEntry;           // 🚀 Add this
  final String? checkInPrimaryKey;  // 🚀 Add this

  const SaleUnplanPage({
    super.key,
    this.customer,
    this.detailEntry,               // 🚀 Add this to constructor
    this.checkInPrimaryKey,         // 🚀 Add this to constructor
  });

  @override
  State<SaleUnplanPage> createState() => _SaleUnplanPageState();
}

class _SaleUnplanPageState extends State<SaleUnplanPage>
    with SingleTickerProviderStateMixin {

  // ── Controller (holds all business logic & state) ─────────────────────────
  final SaleController controller = SaleController();

  // ── UI-only state ─────────────────────────────────────────────────────────
  int  _step          = 1;
  String searchCustomer = "";
  String searchItem     = "";
  int?   expandedIndex;
  final Map<String, bool> _expandedMap = {};

  // ── Text controllers (UI concern only) ────────────────────────────────────
  final TextEditingController remarkController     = TextEditingController();
  final TextEditingController searchCustomerCtrl   = TextEditingController();
  final TextEditingController searchItemCtrl       = TextEditingController();
  final TextEditingController _discountPercentCtrl = TextEditingController();
  final TextEditingController _discountAmountCtrl  = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ─────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );

    _animController!.forward();

    if (controller.deliveryTime == null) {
      controller.deliveryTime = TimeOfDay.now();
    }

    controller.addListener(_onControllerChange);
    controller.loadCustomers();
    controller.loadItems();

    // ✅ 2. Add this block to auto-select the customer and skip to Step 2
    if (widget.customer != null) {
      controller.selectCustomer(widget.customer!);
      _step = 2; // Jump directly to item catalog selection
    }
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChange);

    _animController.dispose();

    remarkController.dispose();
    searchCustomerCtrl.dispose();
    searchItemCtrl.dispose();
    _discountPercentCtrl.dispose();
    _discountAmountCtrl.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────
  void _switchStep(int step) {
    _animController.forward(from: 0);

    setState(() {
      _step = step;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: isError ? _kDanger : _kSuccess,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // DELIVERY TIME (UI concern — needs context)
  // ─────────────────────────────────────────────────────
  Future<void> pickDeliveryTime() async {
    final initial = controller.deliveryTime ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      controller.setDeliveryTime(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour   = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // ─────────────────────────────────────────────────────
  // DISCOUNT WRAPPERS
  // Delegate to controller; sync text fields with return value
  // ─────────────────────────────────────────────────────
  void _onDiscountPercentChanged(String value) {
    final newAmount = controller.onDiscountPercentChanged(value);
    _discountAmountCtrl.text = newAmount.toStringAsFixed(2);
  }

  void _onDiscountAmountChanged(String value) {
    final newPercent = controller.onDiscountAmountChanged(value);
    _discountPercentCtrl.text = newPercent.toStringAsFixed(2);
  }

  // ─────────────────────────────────────────────────────
// SAVE ORDER (dialog stays in UI, logic in controller)
// ─────────────────────────────────────────────────────
  Future<void> saveOrder() async {
    if (controller.selectedCustomer == null ||
        controller.selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Confirm Order",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Submit order for ${controller.selectedCustomer?.cardName ?? "this customer"}?",
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Confirm"),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;


    // 🚀 3. Pass widget.detailEntry from the UI straight into the controller!
    final success = await controller.saveOrder(
      remark: remarkController.text.trim(),
      detailEntry: widget.detailEntry, // <-- Handing over the value here
      checkInPrimaryKey: widget.checkInPrimaryKey
    );


    if (!mounted) return;

    if (success) {
      _showSnack("Order saved successfully!");

      // 🚀 1. Clear everything first using your reset function
      _resetUIState();

      // 🚀 2. Conditionally handle where to go next
      bool isVisitPlan = widget.detailEntry != null &&
          widget.detailEntry.toString().trim().isNotEmpty;

      if (isVisitPlan) {

        int entryId = int.tryParse(widget.detailEntry.toString()) ?? 0;

        // Update local storage so 'synced' becomes 'yes' & 'status' becomes 'done'
        await VisitPlanApi.updateSyncedStatus(entryId);

        // If it's a Visit Plan -> Reload and navigate to VisitPlanPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VisitPlanPage()),
        );
      }
      // If it's a Direct Sale Order, it stays on this page since _resetUIState() already reset Step to 1.

    }else {
      // Look at your debug console for the full JSON dump and Server Error response text!
      _showSnack("Failed to save order. Check logs for details.", isError: true);
    }
  }

  // ─────────────────────────────────────────────────────
  // RESET UI STATE after save
  // ─────────────────────────────────────────────────────
  void _resetUIState() {
    controller.resetAll();
    remarkController.clear();
    searchCustomerCtrl.clear();
    searchItemCtrl.clear();
    _discountPercentCtrl.clear();
    _discountAmountCtrl.clear();
    setState(() {
      _step = 1;
      searchCustomer = "";
      searchItem = "";
      expandedIndex = null;
      _expandedMap.clear();
    });
  }

  // ─────────────────────────────────────────────────────
  // EXIT DIALOG
  // ─────────────────────────────────────────────────────
  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        title: const Text(
          "Exit Order?",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: const Text(
          "Your cart items will be lost.",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Stay",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Exit",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ─────────────────────────────────────────────────────
  // ROOT BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step > 1) {
          _switchStep(_step - 1);
          return false;
        }

        if (controller.selectedItems.isNotEmpty) {
          return await _showExitDialog();
        }

        return true;
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      10,
                    ),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_step == 1) return buildCustomerStep();
    if (_step == 2) return buildItemStep();
    return buildSummaryStep();
  }

  // ─────────────────────────────────────────────────────
  // APPBAR
  // ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _kPrimary,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // 🚀 Dynamically switches label depending on detailEntry value
            (widget.detailEntry != null) ? "Sale from Visit Plan" : "Direct Sale Order",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          Text(
            widget.customer?.cardName ??
                controller.selectedCustomer?.cardName ??
                "Select a customer",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),

      actions: [
        if (_step == 2 &&
            controller.selectedItems.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${controller.selectedItems.length} item(s)",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP INDICATOR
  // ─────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        _stepDot(1, "Customer"),
        _stepConnector(1),
        _stepDot(2, "Items"),
        _stepConnector(2),
        _stepDot(3, "Summary"),
      ]),
    );
  }

  Widget _stepDot(int step, String label) {
    final done   = _step > step;
    final active = _step == step;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (step < _step) _switchStep(step);
        },
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? _kSuccess
                  : active
                  ? _kPrimary
                  : Colors.grey.shade200,
              boxShadow: active
                  ? [BoxShadow(
                color: _kPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )]
                  : [],
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(
                "$step",
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: done
                  ? _kSuccess
                  : active
                  ? _kPrimary
                  : Colors.grey,
              fontWeight:
              active ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepConnector(int afterStep) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: _step > afterStep ? _kSuccess : Colors.grey.shade300,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 1 — CUSTOMER SELECTION
  // ─────────────────────────────────────────────────────
  Widget buildCustomerStep() {
    if (controller.isLoadingCustomer) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 12),
            Text("Loading customers...",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    final filtered = controller.customers.where((c) {
      if (searchCustomer.trim().isEmpty || searchCustomer == "*") {
        return true;
      }
      final q = searchCustomer.toLowerCase();
      return c.cardName.toLowerCase().contains(q) ||
          c.cardCode.toLowerCase().contains(q);
    }).toList();

    final customer = controller.selectedCustomer;

    return Column(
      children: [
        if (customer != null) ...[
          _buildSelectedCustomerCard(),
          const SizedBox(height: 8),
          _buildPrimaryButton(
            label: "Proceed to Items",
            icon: Icons.arrow_forward,
            onPressed: () => _switchStep(2),
          ),
        ] else ...[
          _buildSearchField(
            ctrl: searchCustomerCtrl,
            hint: "Search by name or code...",
            onChanged: (v) => setState(() => searchCustomer = v),
            value: searchCustomer,
            onClear: () {
              searchCustomerCtrl.clear();
              setState(() => searchCustomer = "");
            },
          ),
          const SizedBox(height: 6),
          Text(
            "${filtered.length} customer(s) found",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState("No customers found", Icons.people_outline)
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) =>
                  _buildCustomerCard(filtered[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedCustomerCard() {
    final c = controller.selectedCustomer;

    if (c == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.cardCode,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  c.cardName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.fullAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 2),

                Row(
                  children: [
                    const Icon(Icons.phone, size: 11, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      c.tel1.isEmpty ? "-" : c.tel1,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: controller.clearCustomer,
            child: const Text(
              "Change",
              style: TextStyle(
                color: _kOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(api.Customer c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),

        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_outline,
            color: _kPrimary,
            size: 20,
          ),
        ),

        title: Text(
          c.cardName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.cardCode,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),

            Text(
              c.fullAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),

        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chevron_right,
            color: _kPrimary,
            size: 18,
          ),
        ),

        onTap: () {
          controller.selectCustomer(c);
          _switchStep(2);
        },
      ),
    );
  }
  // ─────────────────────────────────────────────────────
  // STEP 2 — ITEM SELECTION
  // ─────────────────────────────────────────────────────
  Widget buildItemStep() {
    if (controller.isLoadingItem) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 12),
            Text("Loading items...",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    final filteredItems = controller.items.where((i) {
      if (searchItem.trim().isEmpty || searchItem == "*") return true;
      final q = searchItem.toLowerCase();
      return i.itemName.toLowerCase().contains(q) ||
          i.itemCode.toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      _buildCustomerChip(),
      const SizedBox(height: 8),
      _buildSearchField(
        ctrl: searchItemCtrl,
        hint: "Search by name or code...",
        onChanged: (v) => setState(() => searchItem = v),
        value: searchItem,
        onClear: () {
          searchItemCtrl.clear();
          setState(() => searchItem = "");
        },
      ),
      const SizedBox(height: 6),
      Row(children: [
        Text("${filteredItems.length} item(s) found",
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const Spacer(),
        if (controller.selectedItems.isNotEmpty)
          Text(
            "${controller.selectedItems.length} selected",
            style: const TextStyle(
              fontSize: 11,
              color: _kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Expanded(
        child: filteredItems.isEmpty
            ? _buildEmptyState(
            "No items found", Icons.inventory_2_outlined)
            : ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: (_, index) {
            final item     = filteredItems[index];
            final selected =
            controller.isItemSelected(item.itemCode);
            final isExp    = expandedIndex == index;
            return _buildItemCard(item, selected, isExp, index);
          },
        ),
      ),
      const SizedBox(height: 8),
      if (controller.selectedItems.isNotEmpty) ...[
        _buildCartBar(),
        const SizedBox(height: 8),
      ],
      _buildNavButtons(
        onBack: () => _switchStep(1),
        onNext: controller.selectedItems.isEmpty
            ? null
            : () => _switchStep(3),
        nextLabel:
        "Proceed to Summary (${controller.selectedItems.length})",
      ),
    ]);
  }

  Widget _buildCustomerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
          const Icon(Icons.store, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(controller.selectedCustomer?.cardCode ?? "",
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
              Text(controller.selectedCustomer?.cardName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.shopping_cart_outlined,
            color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        const Text("Cart Subtotal",
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Text(
          "\$${controller.subTotal.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    );
  }

  Widget _buildItemCard(
      itemApi.Item item,
      bool selected,
      bool isExpanded,
      int index,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? _kPrimary.withOpacity(0.05)
            : _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? _kPrimary
              : Colors.transparent,
          width: 1.2,
        ),
      ),

      child: ExpansionTile(
        initiallyExpanded: isExpanded,

        onExpansionChanged: (exp) =>
            setState(() => expandedIndex = exp ? index : null),

        tilePadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 0,
        ),

        childrenPadding: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          10,
        ),

        dense: true,

        leading: GestureDetector(
          onTap: () => controller.toggleItem(item),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? _kPrimary
                  : Colors.grey.shade100,
            ),

            child: Icon(
              selected ? Icons.check : Icons.add,
              size: 16,
              color:
              selected ? Colors.white : Colors.grey,
            ),
          ),
        ),

        title: Text(
          item.itemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        subtitle: Text(
          "${item.itemCode}  |  \$${item.sellingPrice.toStringAsFixed(2)}  |  ${item.invUoMCode}",
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),

                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  "x${controller.selectedItems.firstWhere((e) => e.itemCode == item.itemCode).qty}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 4),

            const Icon(
              Icons.expand_more,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),

        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _detailChip(
                Icons.inventory,
                "Stock: ${item.onhand}",
              ),

              _detailChip(
                Icons.category,
                item.itemGroupName,
              ),

              if ((item.subGroupDes ?? "").isNotEmpty)
                _detailChip(
                  Icons.label_outline,
                  item.subGroupDes ?? "",
                ),

              if ((item.manufacturerDes ?? "").isNotEmpty)
                _detailChip(
                  Icons.factory,
                  item.manufacturerDes ?? "",
                ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                selected ? _kDanger : _kPrimary,

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),

                elevation: 0,
              ),

              onPressed: () =>
                  controller.toggleItem(item),

              child: Text(
                selected
                    ? "Remove from Cart"
                    : "Add to Cart",

                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.black54)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 3 — SUMMARY
  // ─────────────────────────────────────────────────────
  Widget buildSummaryStep() {
    return Column(children: [
      Expanded(
        child: ListView(children: [
          _buildSectionHeader("Customer", ""),
          const SizedBox(height: 8),
          _buildCustomerChip(),
          const SizedBox(height: 12),

          _buildSectionHeader("Order Details", ""),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _buildDropdownCard(
                label: "Owner",
                value: controller.ownerValue,
                icon: Icons.person_outline,
                items: const ["Admin", "Sale"],
                onChanged: (v) => controller.setOwner(v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdownCard(
                label: "Payment",
                value: controller.paymentMethodValue,
                icon: Icons.payment,
                items: const ["Invoice", "Income"],
                onChanged: (v) => controller.setPaymentMethod(v!),
              ),
            ),
          ]),
          const SizedBox(height: 8),

          _buildTapCard(
            icon: Icons.schedule,
            label: "Delivery Time",
            value: _formatTime(controller.deliveryTime ?? TimeOfDay.now()),
            onTap: pickDeliveryTime,
            hasValue: controller.deliveryTime != null,
          ),
          const SizedBox(height: 12),

          _buildSectionHeader(
              "Items (${controller.selectedItems.length})", ""),
          const SizedBox(height: 6),
// Explicitly pass the arguments required by the updated widget constructor
          ...controller.selectedItems.map((item) => _buildSummaryItem(
            context,
            item,
            setState,
            _expandedMap,
            controller,
          )),
          const SizedBox(height: 8),

          _buildPromotionButton(),
          const SizedBox(height: 10),

          TextField(
            controller: remarkController,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Add a remark (optional)",
              hintStyle:
              const TextStyle(fontSize: 11, color: Colors.grey),
              prefixIcon: const Icon(Icons.edit_note,
                  color: Colors.grey, size: 20),
              filled: true,
              fillColor: _kCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          _buildOrderSummary(),
          const SizedBox(height: 4),
        ]),
      ),
      const SizedBox(height: 8),
      _buildNavButtons(
        onBack: () => _switchStep(2),
        onNext: controller.isSaving ? null : saveOrder,
        nextLabel: "Save Order",
        nextIcon: controller.isSaving ? null : Icons.save_alt_outlined,
        isLoading: controller.isSaving,
      ),
    ]);
  }

  Widget _buildDropdownCard({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle:
          const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(icon, size: 16, color: _kPrimary),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12, color: Colors.black87),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTapCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool hasValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18,
              color: hasValue ? _kPrimary : Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                Text(value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasValue
                          ? Colors.black87
                          : Colors.grey,
                    )),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 16, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _buildPromotionButton() {
    final isDisabled =
        controller.isRunningPromotion || controller.isPromotionLocked;

    return IgnorePointer(
      ignoring: isDisabled,
      child: GestureDetector(
        onTap: () async {
          if (isDisabled) return;
          await controller.saveItemLog();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.grey.shade300, Colors.grey.shade300]
                  : [_kOrange, const Color(0xFFF57C00)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.isRunningPromotion)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.local_offer,
                    color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                controller.isPromotionLocked
                    ? "Already Applied"
                    : controller.isRunningPromotion
                    ? "Running..."
                    : "Run Promotion",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSummaryItem(BuildContext context, SaleItem item, Function(void Function()) setState, dynamic _expandedMap, dynamic controller) {
    final isLocked = controller.isPromotionLocked;
    final itemKey = "${item.itemCode}_summary";
    final isExpanded = _expandedMap[itemKey] ?? false;
    final isFreeItem = item.discPrcnt == 100 || item.uRemarkOther12 == "FREE_ITEM";

    // ── 1. MAP PROMOTIONS MATCHING CONTROLLER STRUCTURE EXACTLY ───────────
    final Map<String, double> activePromos = {};

    if (controller.isPromotionLocked) {
      if (isFreeItem) {
        activePromos["FREE ITEM"] = item.disAmt > 0 ? item.disAmt : (item.price * item.qty);
      } else {
        if (item.uInvDicountAmt > 0) activePromos["DISCOUNT"] = item.uInvDicountAmt;
        if (item.uInvPaymentAmt > 0) activePromos["CASH INVOICE"] = item.uInvPaymentAmt;
        if (item.uPaymentAmt > 0) activePromos["CASH INCOME"] = item.uPaymentAmt;
        if (item.uInvTransportAmt > 0) activePromos["TRANSPORTATION"] = item.uInvTransportAmt;
        if (item.uInvSpecialAmt > 0) activePromos["SPECIAL DISCOUNT"] = item.uInvSpecialAmt;
        if (item.uSpecialTrAmt > 0) activePromos["SPECIAL TRANSP."] = item.uSpecialTrAmt;
        if (item.uSpecialPriceAmt > 0) activePromos["SPECIAL PRICE"] = item.uSpecialPriceAmt;
        if (item.uInvVoucherAmt > 0) activePromos["VOUCHER"] = item.uInvVoucherAmt;

        if (item.uInOther9 > 0) activePromos[item.uRemarkOther9.isNotEmpty ? item.uRemarkOther9 : "OTHER 9"] = item.uInOther9;
        if (item.uInOther10 > 0) activePromos[item.uRemarkOther10.isNotEmpty ? item.uRemarkOther10 : "OTHER 10"] = item.uInOther10;
        if (item.uInOther11 > 0) activePromos[item.uRemarkOther11.isNotEmpty ? item.uRemarkOther11 : "OTHER 11"] = item.uInOther11;
        if (item.uInOther12 > 0 && item.uRemarkOther12 != "FREE_ITEM") {
          activePromos[item.uRemarkOther12.isNotEmpty ? item.uRemarkOther12 : "OTHER 12"] = item.uInOther12;
        }

        if (item.uInvCurrency > 0) activePromos[item.uRemarkCurrency.isNotEmpty ? item.uRemarkCurrency : "CURRENCY"] = item.uInvCurrency;
        if (item.uInvFactory > 0) activePromos[item.uRemarkFactory.isNotEmpty ? item.uRemarkFactory : "FACTORY SUPPORT"] = item.uInvFactory;
        if (item.uInvTransportB7 > 0) activePromos[item.uRemarkTransportB7.isNotEmpty ? item.uRemarkTransportB7 : "BOAT TRANS. 7"] = item.uInvTransportB7;
        if (item.uInvTransportB8 > 0) activePromos[item.uRemarkTransportB8.isNotEmpty ? item.uRemarkTransportB8 : "BOAT TRANS. 8"] = item.uInvTransportB8;

        if (item.uInvEmployeeCom > 0) activePromos[item.uRemarkEmployeeCom.isNotEmpty ? item.uRemarkEmployeeCom : "EMPLOYEE COMM."] = item.uInvEmployeeCom;
        if (item.uInvDepotCom > 0) activePromos[item.uRemarkDepotCom.isNotEmpty ? item.uRemarkDepotCom : "DEPOT COMM."] = item.uInvDepotCom;
        if (item.uInvQuarterCom > 0) activePromos[item.uRemarkQuarterCom.isNotEmpty ? item.uRemarkQuarterCom : "QUARTERLY COMM."] = item.uInvQuarterCom;
        if (item.uInvMarketing > 0) activePromos[item.uRemarkMarketing.isNotEmpty ? item.uRemarkMarketing : "MARKETING EXP."] = item.uInvMarketing;
      }
    }

    final bool hasPromotion = activePromos.isNotEmpty;

    // ── 2. MATHEMATICAL CALCULATIONS (UPDATED FOR DEDUCTION) ───────────────
    final double grossTotal = item.qty * item.price;

    // Sum up all matching row discounts
    final double totalDiscount = isFreeItem ? 0.0 : activePromos.values.fold<double>(0, (sum, val) => sum + val);

    // Calculate final row total by taking out all active promotions/discounts
    final double netTotal = isFreeItem ? 0.0 : (grossTotal - totalDiscount);

    final String qtyDisplayString = item.qty % 1 == 0
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFreeItem ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isFreeItem ? Colors.green.shade200 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP ROW: PROMOTION LABELS / TAGS ─────────────────────────────────
          if (hasPromotion) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: activePromos.keys.map((label) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFreeItem ? Colors.green : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
          ],

          // ── MIDDLE BLOCK: PRODUCT TEXT DESCRIPTION (UP TO 2 LINES) ───────────
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isFreeItem ? Colors.green.shade900 : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${item.itemCode}  •  ${item.uom}",
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                "Unit Price: \$${item.price.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ),

          // ── BOTTOM ROW: QUANTITY ACTIONS & FINAL PRICING ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Side: Quantity Input Group
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey.shade200 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQtyButton(
                      icon: Icons.remove,
                      isDisabled: isLocked || item.qty <= 1,
                      onTap: () {
                        final currentQty = item.qty;
                        if (currentQty <= 1) return;
                        controller.updateItemQtyByValue(item, currentQty - 1);
                      },
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: TextFormField(
                        key: ValueKey("${item.itemCode}_qty_${qtyDisplayString}"),
                        initialValue: qtyDisplayString,
                        enabled: !isLocked,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? Colors.grey.shade600 : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          final qty = double.tryParse(value);
                          if (qty != null && qty > 0) {
                            controller.updateItemQtyByValue(item, qty);
                          }
                        },
                        onFieldSubmitted: (value) {
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) {
                            controller.updateItemQtyByValue(item, item.qty);
                            return;
                          }
                          controller.updateItemQtyByValue(item, qty);
                        },
                      ),
                    ),
                    _buildQtyButton(
                      icon: Icons.add,
                      isDisabled: isLocked,
                      onTap: () {
                        controller.updateItemQtyByValue(item, item.qty + 1);
                      },
                    ),
                  ],
                ),
              ),

              // Right Side: Price Details & Dropdown Trigger Action
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hasPromotion && !isFreeItem
                    ? () {
                  setState(() {
                    _expandedMap[itemKey] = !(_expandedMap[itemKey] ?? false);
                  });
                }
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Only display original price strikethrough if there is an active discount
                        if (hasPromotion && totalDiscount > 0 && !isFreeItem)
                          Text(
                            "\$${grossTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          isFreeItem ? "FREE" : "\$${netTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isFreeItem ? Colors.green.shade700 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (hasPromotion && !isFreeItem) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── EXPANDED AREA: ITEMIZED DISCOUNT LINE BREAKDOWN ──────────────────
          if (hasPromotion && isExpanded && !isFreeItem) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Active Line Reductions:",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const Divider(height: 8, thickness: 0.5),
                  ...activePromos.entries.map((promo) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              promo.key,
                              style: const TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "-\$${promo.value.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 8, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Aggregate Deduction:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        "\$${totalDiscount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required bool isDisabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(
          icon,
          size: 14,
          color: isDisabled ? Colors.grey.shade400 : Colors.black87,
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────
  // ORDER SUMMARY
  // ─────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader("Order Summary", ""),
          const SizedBox(height: 12),
          _buildSubTotal(),
          const SizedBox(height: 10),
          _buildDiscountRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "NET TOTALS",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDocTotal(),
        ],
      ),
    );
  }

  Widget _buildSubTotal() {
    // Dynamically reading total gross line value prior to overall document deductions
    final double currentSubTotal = controller.subTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subtotal",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                "Gross Accumulation",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "\$${currentSubTotal.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: Colors.orange.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Discount",
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Text("edit % or amount",
                style: TextStyle(
                    color: Colors.orange.shade300, fontSize: 10)),
          ]),
          const Spacer(),
          Flexible(
            child: _buildDiscountInput(
              textCtrl: _discountPercentCtrl,
              suffix: "%",
              onChanged: _onDiscountPercentChanged,
              color: Colors.orange,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text("|",
                style: TextStyle(
                    color: Colors.orange.shade200, fontSize: 18)),
          ),
          Flexible(
            child: _buildDiscountInput(
              textCtrl: _discountAmountCtrl,
              prefix: "\$",
              onChanged: _onDiscountAmountChanged,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountInput({
    required TextEditingController textCtrl,
    required Function(String) onChanged,
    required MaterialColor color,
    String prefix = "",
    String suffix = "",
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 84, minWidth: 60),
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200, width: 1.2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (prefix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(prefix,
                style: TextStyle(
                    color: color.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        Expanded(
          child: TextField(
            controller: textCtrl,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color.shade800,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4, vertical: 10,
              ),
              hintText: "0",
            ),
          ),
        ),
        if (suffix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(suffix,
                style: TextStyle(
                    color: color.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildDocTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF0D47A1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Doc Total",
                style: TextStyle(
                    color: Colors.white70, fontSize: 11)),
            Text("subtotal - discount",
                style: TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
        const Spacer(),
        Text(
          "\$${controller.docTotal.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      const Spacer(),
      if (subtitle.isNotEmpty)
        Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey)),
    ]);
  }

  Widget _buildSearchField({
    required TextEditingController ctrl,
    required String hint,
    required ValueChanged<String> onChanged,
    required String value,
    required VoidCallback onClear,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        prefixIcon:
        const Icon(Icons.search, size: 20, color: Colors.grey),
        suffixIcon: value.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close,
              size: 18, color: Colors.grey),
          onPressed: onClear,
        )
            : null,
        filled: true,
        fillColor: _kCard,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 16)
            : const SizedBox.shrink(),
        label: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildNavButtons({
    required VoidCallback? onBack,
    required VoidCallback? onNext,
    required String nextLabel,
    IconData? nextIcon,
    bool isLoading = false,
  }) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onBack,
          child: const Icon(Icons.arrow_back, size: 16),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: onNext,
          child: isLoading
              ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(nextLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (nextIcon != null) ...[
                const SizedBox(width: 6),
                Icon(nextIcon, size: 14),
              ],
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(msg,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
