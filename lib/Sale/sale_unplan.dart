import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuberadmsdn/api/save_itemlogpromotion_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_customer_api.dart' as api;
import '../api/get_item_api.dart' as itemApi;
import '../api/get_promotionresult_api.dart';
import 'sale_unplan_controller.dart';
import 'models/sale_order_model.dart';

// ─────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────
const _kPrimary = Color(0xFF1565C0);
const _kBg     = Color(0xFFF0F4FA);
const _kCard   = Colors.white;
const _kAccent = Color(0xFF00ACC1);
const _kDanger = Color(0xFFE53935);
const _kSuccess = Color(0xFF43A047);
const _kOrange  = Color(0xFFFB8C00);

class SaleUnplanPage extends StatefulWidget {
  const SaleUnplanPage({super.key});
  @override
  State<SaleUnplanPage> createState() => _SaleUnplanPageState();
}

class _SaleUnplanPageState extends State<SaleUnplanPage>
    with SingleTickerProviderStateMixin {

  final SaleController controller = SaleController();
  // ─── STATE VARIABLES ─────────────────────────────



  // ── Step & search ─────────────────────────────────────────────────────────
  int _step = 1;
  String searchCustomer = "";
  String searchItem     = "";

  // ── Data ──────────────────────────────────────────────────────────────────
  api.Customer?       selectedCustomer;
  List<api.Customer>  customers        = [];
  bool                isLoadingCustomer = true;
  List<itemApi.Item>  items             = [];
  bool                isLoadingItem     = true;
  bool                isSaving          = false;
  bool                isRunningPromotion = false;
  int?                expandedIndex;
  bool isPromotionLocked = false;
  // ── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController remarkController      = TextEditingController();
  final TextEditingController searchCustomerCtrl    = TextEditingController();
  final TextEditingController searchItemCtrl        = TextEditingController();
  final TextEditingController _discountPercentCtrl  = TextEditingController();
  final TextEditingController _discountAmountCtrl   = TextEditingController();
  final Map<String, bool> _expandedMap = {};

  // ── Discount ──────────────────────────────────────────────────────────────
  double discountPercent    = 0.0;
  double discountAmount     = 0.0;
  bool   _isUpdatingDiscount = false;

  // ── Summary extra fields ──────────────────────────────────────────────────
  String     ownerValue          = "Admin";
  String     paymentMethodValue  = "Invoice";
  TimeOfDay? deliveryTime;

  // ── Animation ─────────────────────────────────────────────────────────────
  AnimationController? _animController;
  Animation<double>?   _fadeAnim;

  // ── Computed ──────────────────────────────────────────────────────────────
  double get subTotal => controller.selectedItems
      .fold(0.0, (sum, i) => sum + i.price * i.qty);
  double get docTotal => subTotal - discountAmount;



  // ─────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(
        parent: _animController!, curve: Curves.easeOut);
    _animController!.forward();
    _loadCustomers();
    _loadItems();
  }

  @override
  void dispose() {
    _animController?.dispose();
    remarkController.dispose();
    searchCustomerCtrl.dispose();
    searchItemCtrl.dispose();
    _discountPercentCtrl.dispose();
    _discountAmountCtrl.dispose();
    super.dispose();
  }


  void _updateItemQty(SaleItem item, int change) {
    setState(() {
      final index = controller.selectedItems
          .indexWhere((e) => e.itemCode == item.itemCode);

      if (index == -1) return;

      final current = controller.selectedItems[index];
      final newQty = current.qty + change;

      // REMOVE ITEM IF QTY <= 0
      if (newQty <= 0) {
        controller.selectedItems.removeAt(index);
      } else {
        controller.selectedItems[index] = SaleItem(
          itemCode: current.itemCode,
          name: current.name,
          price: current.price,
          qty: newQty,
          uom: current.uom,
          itemGroupName: current.itemGroupName,
          subGroupDes: current.subGroupDes,
          subGroup2Des: current.subGroup2Des,

          // ─────────────────────────────
          // PROMOTION FIELDS
          // ─────────────────────────────
          uInvDiscountAmt: current.uInvDiscountAmt,
          uInvDiscountPer: current.uInvDiscountPer,

          uSpecialPriceAmt: current.uSpecialPriceAmt,
          uSpecialPricePercent: current.uSpecialPricePercent,

          uInvVoucherAmt: current.uInvVoucherAmt,

          uMnOther9: current.uMnOther9,
          uMnOther10: current.uMnOther10,
          uMnOther11: current.uMnOther11,
          uMnOther12: current.uMnOther12,

          uRemarkOther9: current.uRemarkOther9,
          uRemarkOther10: current.uRemarkOther10,
          uRemarkOther11: current.uRemarkOther11,
          uRemarkOther12: current.uRemarkOther12,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────
  // DATA LOADERS
  // ─────────────────────────────────────────────────────
  Future<void> _loadCustomers() async {
    setState(() => isLoadingCustomer = true);
    customers = await api.CustomerApi.getLocalCustomers();
    setState(() => isLoadingCustomer = false);
  }

  Future<void> _loadItems() async {
    setState(() => isLoadingItem = true);
    items = await itemApi.ItemApi.getLocalItems();
    setState(() => isLoadingItem = false);
  }

  // ─────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────
  void _switchStep(int step) {
    _animController?.forward(from: 0);
    setState(() => _step = step);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: isError ? _kDanger : _kSuccess,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  bool isItemSelected(String itemCode) =>
      controller.selectedItems.any((e) => e.itemCode == itemCode);

  // ─────────────────────────────────────────────────────
  // DELIVERY TIME
  // ─────────────────────────────────────────────────────
  Future<void> pickDeliveryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: deliveryTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => deliveryTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour   = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // ─────────────────────────────────────────────────────
  // DISCOUNT SYNC
  // ─────────────────────────────────────────────────────
  void _onDiscountPercentChanged(String value) {
    if (_isUpdatingDiscount) return;
    _isUpdatingDiscount = true;
    double percent = double.tryParse(value) ?? 0.0;
    if (percent > 100) {
      percent = 100;
      _discountPercentCtrl.text = "100";
      _discountPercentCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _discountPercentCtrl.text.length));
    } else if (percent < 0) {
      percent = 0;
      _discountPercentCtrl.text = "0";
    }
    final amount = subTotal * percent / 100;
    setState(() {
      discountPercent = percent;
      discountAmount  = amount;
    });
    _discountAmountCtrl.text = amount.toStringAsFixed(2);
    _isUpdatingDiscount = false;
  }

  void _onDiscountAmountChanged(String value) {
    if (_isUpdatingDiscount) return;
    _isUpdatingDiscount = true;
    double amount = double.tryParse(value) ?? 0.0;
    if (amount > subTotal) {
      amount = subTotal;
      _discountAmountCtrl.text = subTotal.toStringAsFixed(2);
      _discountAmountCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _discountAmountCtrl.text.length));
    } else if (amount < 0) {
      amount = 0;
      _discountAmountCtrl.text = "0.00";
    }
    final percent = subTotal > 0 ? (amount / subTotal) * 100 : 0.0;
    setState(() {
      discountAmount  = amount;
      discountPercent = percent;
    });
    _discountPercentCtrl.text = percent.toStringAsFixed(2);
    _isUpdatingDiscount = false;
  }

  // ─────────────────────────────────────────────────────
  // PROMOTION
  // ─────────────────────────────────────────────────────


  void _toggleItem(dynamic item) {
    final idx = controller.selectedItems
        .indexWhere((e) => e.itemCode == item.itemCode);
    setState(() {
      if (idx >= 0) {
        controller.selectedItems.removeAt(idx);
      } else {
        controller.selectedItems.add(SaleItem(
          itemCode: item.itemCode,
          name: item.itemName,
          price: item.sellingPrice,
          qty: 1,
          uom: item.invUoMCode,
          itemGroupName: item.itemGroupName,
          subGroupDes: item.subGroupDes,
          subGroup2Des: item.subGroup2Des,
          manufacturerDes: item.manufacturerDes,
        ));
      }
    });
  }

  // ─────────────────────────────────────────────────────
  // ROOT BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step > 1) { _switchStep(_step - 1); return false; }
        if (controller.selectedItems.isNotEmpty) return await _showExitDialog();
        return true;
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(children: [
            _buildStepIndicator(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim!,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ]),
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
          const Text(
            "Direct Sale Order",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            selectedCustomer?.cardName ?? "Select a customer",
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
        if (_step == 2 && controller.selectedItems.isNotEmpty)
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
        onTap: () { if (step < _step) _switchStep(step); },
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _kSuccess : active ? _kPrimary : Colors.grey.shade200,
              boxShadow: active
                  ? [BoxShadow(
                  color: _kPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))]
                  : [],
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text("$step",
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: done ? _kSuccess : active ? _kPrimary : Colors.grey,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
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
  // STEP 1 — CUSTOMER SELECTION
  // ─────────────────────────────────────────────────────
  Widget buildCustomerStep() {
    if (isLoadingCustomer) {
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

    final filtered = customers.where((c) {
      if (searchCustomer.trim().isEmpty || searchCustomer == "*") return true;
      final q = searchCustomer.toLowerCase();
      return c.cardName.toLowerCase().contains(q) ||
          c.cardCode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // ── Already selected ────────────────────────────────────────────────
        if (selectedCustomer != null) ...[
          _buildSelectedCustomerCard(),
          const SizedBox(height: 8),
          _buildPrimaryButton(
            label: "Proceed to Items",
            icon: Icons.arrow_forward,
            onPressed: () => _switchStep(2),
          ),
        ],
        // ── Search + list ───────────────────────────────────────────────────
        if (selectedCustomer == null) ...[
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
          Row(children: [
            Text("${filtered.length} customer(s) found",
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.store, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedCustomer!.cardCode,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(selectedCustomer!.cardName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 2),
            Text(selectedCustomer!.fullAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone, size: 11, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                selectedCustomer!.tel1.isEmpty ? "-" : selectedCustomer!.tel1,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ]),
          ]),
        ),
        TextButton(
          onPressed: () => setState(() {
            selectedCustomer = null;
            controller.selectedCustomer = null;
          }),
          child: const Text("Change",
              style: TextStyle(
                  color: _kOrange, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
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
          setState(() {
            selectedCustomer = c;
            controller.selectCustomer(c);
            _switchStep(2);
          });
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 2 — ITEM SELECTION
  // ─────────────────────────────────────────────────────
  Widget buildItemStep() {
    if (isLoadingItem) {
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

    final filteredItems = items.where((i) {
      if (searchItem.trim().isEmpty || searchItem == "*") return true;
      final q = searchItem.toLowerCase();
      return i.itemName.toLowerCase().contains(q) ||
          i.itemCode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
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
            Text("${controller.selectedItems.length} selected",
                style: const TextStyle(
                    fontSize: 11,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState("No items found", Icons.inventory_2_outlined)
              : ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (_, index) {
              final item     = filteredItems[index];
              final selected = isItemSelected(item.itemCode);
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
      ],
    );
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
              color: _kPrimary, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.store, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedCustomer?.cardCode ?? "",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(selectedCustomer?.cardName ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.shopping_cart_outlined,
            color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        const Text("Cart Subtotal",
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Text("\$${subTotal.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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
        color: selected ? _kPrimary.withOpacity(0.05) : _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _kPrimary : Colors.transparent,
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
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        dense: true,
        leading: GestureDetector(
          onTap: () => _toggleItem(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _kPrimary : Colors.grey.shade100,
            ),
            child: Icon(
              selected ? Icons.check : Icons.add,
              size: 16,
              color: selected ? Colors.white : Colors.grey,
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
              _detailChip(Icons.inventory, "Stock: ${item.onhand}"),
              _detailChip(Icons.category, item.itemGroupName),
              if ((item.subGroupDes ?? "").isNotEmpty)
                _detailChip(Icons.label_outline, item.subGroupDes!),
              if ((item.manufacturerDes ?? "").isNotEmpty)
                _detailChip(Icons.factory, item.manufacturerDes!),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? _kDanger : _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () => _toggleItem(item),
              child: Text(
                selected ? "Remove from Cart" : "Add to Cart",
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
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 3 — SUMMARY
  // ─────────────────────────────────────────────────────
  Widget buildSummaryStep() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [

              // ── Customer chip ─────────────────────────────────────────────
              _buildSectionHeader("Customer", ""),
              const SizedBox(height: 8),
              _buildCustomerChip(),
              const SizedBox(height: 12),

              // ── Owner & Payment ───────────────────────────────────────────
              _buildSectionHeader("Order Details", ""),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _buildDropdownCard(
                    label: "Owner",
                    value: ownerValue,
                    icon: Icons.person_outline,
                    items: const ["Admin", "Sale"],
                    onChanged: (v) => setState(() => ownerValue = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdownCard(
                    label: "Payment",
                    value: paymentMethodValue,
                    icon: Icons.payment,
                    items: const ["Invoice", "Income"],
                    onChanged: (v) =>
                        setState(() => paymentMethodValue = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              _buildTapCard(
                icon: Icons.schedule,
                label: "Delivery Time",
                value: _formatTime(deliveryTime ?? TimeOfDay.now()),
                onTap: pickDeliveryTime,
                hasValue: deliveryTime != null,
              ),
              const SizedBox(height: 12),

              // ── Items ─────────────────────────────────────────────────────
              _buildSectionHeader(
                  "Items (${controller.selectedItems.length})", ""),
              const SizedBox(height: 6),
              ...controller.selectedItems.map(_buildSummaryItem),
              const SizedBox(height: 8),

              // ── Promotion ─────────────────────────────────────────────────
              _buildPromotionButton(),
              const SizedBox(height: 10),

              // ── Remark ────────────────────────────────────────────────────
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
                      borderSide: BorderSide.none),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),

              // ── Order Summary (subtotal + discount + doc total) ────────────
              _buildOrderSummary(),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildNavButtons(
          onBack: () => _switchStep(2),
          onNext: isSaving ? null : saveOrder,
          nextLabel: "Save Order",
          nextIcon: isSaving ? null : Icons.save_alt_outlined,
          isLoading: isSaving,
        ),
      ],
    );
  }

  // ─── Dropdown card ─────────────────────────────────────────────────────────
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
          color: _kCard, borderRadius: BorderRadius.circular(12)),
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

  // ─── Tap card (delivery time) ──────────────────────────────────────────────
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
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: _kCard, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon,
              size: 18, color: hasValue ? _kPrimary : Colors.grey),
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
                              : Colors.grey)),
                ]),
          ),
          Icon(Icons.chevron_right,
              size: 16, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  // ─── Promotion button ──────────────────────────────────────────────────────
  Widget _buildPromotionButton() {
    final isDisabled = isRunningPromotion || isPromotionLocked;

    return IgnorePointer(
      ignoring: isDisabled,
      child: GestureDetector(
        onTap: () async {
          if (isDisabled) return;

          await saveItemLog(); // ONLY CALL FUNCTION
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
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
              if (isRunningPromotion)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Text(
                isPromotionLocked
                    ? "Already Applied"
                    : isRunningPromotion
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

// ─── SUMMARY ITEM ROW ──────────────────────────────────────
  Widget _buildSummaryItem(SaleItem item) {
    final isLocked = isPromotionLocked;

    final itemKey = "${item.itemCode}_${item.qty}_${item.lineTotal}";
    final isExpanded = _expandedMap[itemKey] ?? false;

    // ─────────────────────────────
    // FREE ITEM CHECK
    // ─────────────────────────────
    final isFreeItem =
        item.uRemarkOther12 == "FREE_ITEM";

    // ─────────────────────────────
    // PROMOTION CHECK
    // ─────────────────────────────
    bool hasPromotion =
        isPromotionLocked &&
            (item.uInvDiscountAmt > 0 ||
                item.uSpecialPriceAmt > 0 ||
                item.uInvVoucherAmt > 0 ||
                item.uMnOther9 > 0 ||
                item.uMnOther10 > 0 ||
                item.uMnOther11 > 0 ||
                item.uMnOther12 > 0 ||
                isFreeItem);

    String? promoLabel;
    double discountAmt = 0;
    double discountPer = 0;

    // ─────────────────────────────
    // PROMOTION LABEL
    // ─────────────────────────────
    if (hasPromotion) {
      // FREE ITEM
      if (isFreeItem) {
        promoLabel = "FREE";
        discountPer = 100;
        discountAmt = item.price * item.qty;
      }

      // NORMAL DISCOUNT
      else if (item.uInvDiscountAmt > 0) {
        promoLabel = "DISCOUNT";
        discountAmt = item.uInvDiscountAmt;
        discountPer = item.uInvDiscountPer;
      }

      // SPECIAL PRICE
      else if (item.uSpecialPriceAmt > 0) {
        promoLabel = "SPECIAL PRICE";
        discountAmt = item.uSpecialPriceAmt;
        discountPer = item.uSpecialPricePercent;
      }

      // VOUCHER
      else if (item.uInvVoucherAmt > 0) {
        promoLabel = "VOUCHER";
        discountAmt = item.uInvVoucherAmt;
      }

      // OTHER 9
      else if (item.uMnOther9 > 0) {
        promoLabel =
        item.uRemarkOther9.isNotEmpty
            ? item.uRemarkOther9
            : "PROMO 9";

        discountAmt = item.uMnOther9;
      }

      // OTHER 10
      else if (item.uMnOther10 > 0) {
        promoLabel =
        item.uRemarkOther10.isNotEmpty
            ? item.uRemarkOther10
            : "PROMO 10";

        discountAmt = item.uMnOther10;
      }

      // OTHER 11
      else if (item.uMnOther11 > 0) {
        promoLabel =
        item.uRemarkOther11.isNotEmpty
            ? item.uRemarkOther11
            : "PROMO 11";

        discountAmt = item.uMnOther11;
      }

      // OTHER 12
      else if (item.uMnOther12 > 0) {
        promoLabel =
        item.uRemarkOther12.isNotEmpty
            ? item.uRemarkOther12
            : "PROMO 12";

        discountAmt = item.uMnOther12;
      }
    }

    final grossTotal = item.qty * item.price;

    final netTotal = isFreeItem
        ? 0
        : hasPromotion
        ? grossTotal - discountAmt
        : grossTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: isFreeItem
            ? Colors.green.shade50
            : _kCard,

        borderRadius: BorderRadius.circular(10),

        border: isFreeItem
            ? Border.all(
          color: Colors.green.shade300,
        )
            : null,
      ),

      child: Column(
        children: [
          Row(
            children: [
              // ─────────────────────────────
              // PROMO BADGE
              // ─────────────────────────────
              if (hasPromotion)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),

                  margin: const EdgeInsets.only(right: 6),

                  decoration: BoxDecoration(
                    color: isFreeItem
                        ? Colors.green
                        : Colors.orange.shade600,

                    borderRadius:
                    BorderRadius.circular(4),
                  ),

                  child: Text(
                    promoLabel ?? "",

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // ─────────────────────────────
              // ITEM INFO
              // ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,

                        color: isFreeItem
                            ? Colors.green.shade800
                            : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      "${item.itemCode}  |  ${item.uom}",

                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "Unit Price: \$${item.price.toStringAsFixed(2)}",

                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),

                    // ─────────────────────────────
                    // FREE ITEM LABEL
                    // ─────────────────────────────
                    if (isFreeItem)
                      Padding(
                        padding:
                        const EdgeInsets.only(top: 4),
                        child: Text(
                          "FREE ITEM PROMOTION",

                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),

                    // ─────────────────────────────
                    // EXPAND DETAILS
                    // ─────────────────────────────
                    if (hasPromotion &&
                        isExpanded) ...[
                      const SizedBox(height: 6),

                      Text(
                        "Type: $promoLabel",

                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.deepOrange,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      if (discountPer > 0)
                        Text(
                          "Discount %: ${discountPer.toStringAsFixed(2)}%",

                          style:
                          const TextStyle(
                            fontSize: 10,
                          ),
                        ),

                      if (discountAmt > 0)
                        Text(
                          "Discount Amt: \$${discountAmt.toStringAsFixed(2)}",

                          style:
                          const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // ─────────────────────────────
              // QTY CONTROL
              // ─────────────────────────────
              Container(
                height: 28,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius:
                  BorderRadius.circular(6),

                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // MINUS
                    InkWell(
                      onTap: isLocked
                          ? null
                          : () {
                        if (item.qty <= 1) {
                          return;
                        }

                        _updateItemQty(
                            item, -1);
                      },

                      child: Padding(
                        padding:
                        const EdgeInsets.all(4),

                        child: Icon(
                          Icons.remove,

                          size: 12,

                          color: isLocked
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),

                    // QTY INPUT
                    SizedBox(
                      width: 32,

                      child: TextFormField(
                        key: ValueKey(
                          "${item.itemCode}_${item.qty}_${item.lineTotal}",
                        ),

                        initialValue:
                        item.qty.toString(),

                        enabled: !isLocked,

                        textAlign:
                        TextAlign.center,

                        keyboardType:
                        TextInputType.number,

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],

                        style:
                        const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                        ),

                        decoration:
                        const InputDecoration(
                          isDense: true,
                          border:
                          InputBorder.none,
                          contentPadding:
                          EdgeInsets.zero,
                        ),

                        onChanged: (value) {
                          final qty =
                          int.tryParse(value);

                          if (qty == null ||
                              qty <= 0) {
                            return;
                          }

                          setState(() {
                            final index =
                            controller
                                .selectedItems
                                .indexWhere(
                                  (e) =>
                              e.itemCode ==
                                  item.itemCode &&
                                  e.lineTotal ==
                                      item
                                          .lineTotal,
                            );

                            if (index == -1) {
                              return;
                            }

                            controller
                                .selectedItems[
                            index] = controller
                                .selectedItems[
                            index]
                                .copyWith(
                              qty: qty,
                            );
                          });
                        },
                      ),
                    ),

                    // PLUS
                    InkWell(
                      onTap: isLocked
                          ? null
                          : () =>
                          _updateItemQty(
                              item, 1),

                      child: Padding(
                        padding:
                        const EdgeInsets.all(4),

                        child: Icon(
                          Icons.add,

                          size: 12,

                          color: isLocked
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ─────────────────────────────
              // TOTAL
              // ─────────────────────────────
              GestureDetector(
                onTap: hasPromotion
                    ? () {
                  setState(() {
                    _expandedMap[itemKey] =
                    !(_expandedMap[
                    itemKey] ??
                        false);
                  });
                }
                    : null,

                child: SizedBox(
                  width: 85,

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,

                    children: [
                      if (hasPromotion)
                        Text(
                          "\$${grossTotal.toStringAsFixed(2)}",

                          style:
                          const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration:
                            TextDecoration
                                .lineThrough,
                          ),
                        ),

                      Text(
                        isFreeItem
                            ? "FREE"
                            : "\$${netTotal.toStringAsFixed(2)}",

                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,

                          color: isFreeItem
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),

                      if (hasPromotion)
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,

                          size: 14,
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
  // ─────────────────────────────────────────────────────
  // ORDER SUMMARY SECTION
  // ─────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildSectionHeader("Order Summary", ""),
        const SizedBox(height: 12),
        _buildSubTotal(),
        const SizedBox(height: 10),
        _buildDiscountRow(),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text("Total",
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 11)),
          ),
          Expanded(
              child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ]),
        const SizedBox(height: 10),
        _buildDocTotal(),
      ]),
    );
  }

  Widget _buildSubTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: _kPrimary.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Subtotal",
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          Text("qty x price",
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 10)),
        ]),
        const Spacer(),
        Text("\$${subTotal.toStringAsFixed(2)}",
            style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildDiscountRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
              style:
              TextStyle(color: Colors.orange.shade200, fontSize: 18)),
        ),
        Flexible(
          child: _buildDiscountInput(
            textCtrl: _discountAmountCtrl,
            prefix: "\$",
            onChanged: _onDiscountAmountChanged,
            color: Colors.orange,
          ),
        ),
      ]),
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
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color.shade800,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Doc Total",
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text("subtotal - discount",
                  style:
                  TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
        const Spacer(),
        Text("\$${docTotal.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
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
            color: _kPrimary, borderRadius: BorderRadius.circular(2)),
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
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
          onPressed: onClear,
        )
            : null,
        filled: true,
        fillColor: _kCard,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
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
              borderRadius: BorderRadius.circular(12)),
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
                borderRadius: BorderRadius.circular(12)),
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
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: onNext,
          child: isLoading
              ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(nextLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
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
                style:
                const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
    );
  }


  // ─────────────────────────────────────────────────────
  // SAVE ORDER
  // ─────────────────────────────────────────────────────
  Future<void> saveOrder() async {
    if (selectedCustomer == null || controller.selectedItems.isEmpty) return;

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
          "Submit order for ${selectedCustomer!.cardName}?",
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

    setState(() => isSaving = true);

    try {
      final now = DateTime.now();

      final invoiceNumber =
          "${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}";

      final order = {
        "invoiceNumber": invoiceNumber,
        "createDate": now.toIso8601String(),
        "createBy": "userLogin",
        "docStatus": "Pending",
        "owner": ownerValue,
        "paymentMethod": paymentMethodValue,
        "deliveryTime": deliveryTime != null
            ? "${deliveryTime!.hour}:${deliveryTime!.minute.toString().padLeft(2, '0')}"
            : "",
        "discountPercent": discountPercent,
        "discountAmount": discountAmount,
        "subTotal": subTotal,
        "docTotal": docTotal,
        "remark": remarkController.text.trim(),
        "customer": {
          "code": selectedCustomer!.cardCode,
          "name": selectedCustomer!.cardName,
          "address": selectedCustomer!.fullAddress,
          "phone": selectedCustomer!.tel1,
        },
        "items": controller.selectedItems
            .map(
              (i) => {
            "itemCode": i.itemCode,
            "name": i.name,
            "price": i.price,
            "qty": i.qty,
            "uom": i.uom,
            "itemGroupName": i.itemGroupName,
            "subGroupDes": i.subGroupDes,
            "subGroup2Des": i.subGroup2Des,
            "manufacturerDes": i.manufacturerDes,
          },
        )
            .toList(),
      };

      final prefs = await SharedPreferences.getInstance();

      List<String> existing =
          prefs.getStringList("localOrders") ?? [];

      existing.add(jsonEncode(order));

      await prefs.setStringList("localOrders", existing);

      if (!mounted) return;

      _showSnack("Order saved successfully!");

      setState(() {
        _step = 1;
        selectedCustomer = null;
        controller.selectedCustomer = null;
        controller.selectedItems.clear();

        remarkController.clear();

        searchCustomer = "";
        searchCustomerCtrl.clear();

        searchItem = "";
        searchItemCtrl.clear();

        expandedIndex = null;

        discountPercent = 0.0;
        discountAmount = 0.0;

        ownerValue = "Admin";
        paymentMethodValue = "Invoice";
        deliveryTime = null;

        _discountPercentCtrl.clear();
        _discountAmountCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        _showSnack(
          "Unexpected error: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> saveItemLog() async {
    if (selectedCustomer == null || controller.selectedItems.isEmpty) {
      return;
    }

    if (isRunningPromotion || isPromotionLocked) return;

    setState(() => isRunningPromotion = true);

    try {
      final now = DateTime.now();
      final logId = "PROMO${now.millisecondsSinceEpoch}";

      final logs = controller.selectedItems.asMap().entries.map((entry) {
        final item = entry.value;

        return UserLogItemPayload(
          id: logId,
          lineNum: entry.key + 1,
          cardCode: selectedCustomer!.cardCode,
          itemCode: item.itemCode,
          qty: item.qty.toDouble(),
          discountPer: discountPercent,
          uom: item.uom,
          price: item.price.toDouble(),
          lineTotal: (item.qty * item.price).toDouble(),
          reason: "PROMO",
          docDate: now.toIso8601String().split("T").first,
          paymentMethod: paymentMethodValue,
        );
      }).toList();

      debugPrint("🔥 PROMOTION REQUEST:");
      debugPrint(jsonEncode(logs.map((e) => e.toJson()).toList()));

      final result = await UserLogItemApi.submitLogs(logs: logs);

      debugPrint("✅ SAVE RESPONSE: ${result.message}");

      if (!result.isSuccess) {
        debugPrint("❌ Save failed → skip promotion");
        return;
      }

      // ─────────────────────────────
      // LOCK AFTER SUCCESS
      // ─────────────────────────────
      setState(() {
        isPromotionLocked = true;
      });

      final promoResult =
      await PromotionService.getPromotionResult(logId);

      debugPrint("🎯 PROMOTION RESULT:");
      debugPrint("Total: ${promoResult.total}");
      debugPrint("Items: ${promoResult.data.length}");

      // ─────────────────────────────
      // APPLY PROMOTION (THIS IS KEY)
      // ─────────────────────────────
      applyPromotionResult(promoResult.data);

      // ─────────────────────────────
      // OPTIONAL UI CLEAN UPDATE
      // ─────────────────────────────
      if (mounted) {
        setState(() {
          // forces full rebuild AFTER promotion applied
          isPromotionLocked = true;
        });
      }

    } catch (e) {
      debugPrint("❌ ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isRunningPromotion = false);
      }
    }
  }

  void applyPromotionResult(List<PromotionResult> promoList) {
    for (final promo in promoList) {
      final index = controller.selectedItems.indexWhere(
            (e) => e.itemCode == promo.itemCode,
      );

      if (index == -1) continue;

      final item = controller.selectedItems[index];

      // ─────────────────────────────
      // FREE QUANTITY PROMOTION
      // ─────────────────────────────
      if (promo.promotionType == "FreeQuantity") {
        final freeQty = promo.match1.toInt();

        // AVOID DUPLICATE FREE ITEM
        final alreadyExists = controller.selectedItems.any(
              (e) =>
          e.itemCode == promo.itemCode &&
              e.uRemarkOther12 == "FREE_ITEM",
        );

        if (alreadyExists) continue;

        controller.selectedItems.insert(
          index + 1,
          SaleItem(
            itemCode: item.itemCode,

            // OPTIONAL DISPLAY NAME
            name: "${item.name} (FREE)",

            price: item.price,

            // FREE QTY
            qty: freeQty,

            uom: item.uom,

            itemGroupName: item.itemGroupName,
            subGroupDes: item.subGroupDes,
            subGroup2Des: item.subGroup2Des,

            // ─────────────────────────────
            // 100% DISCOUNT
            // ─────────────────────────────
            uInvDiscountPer: 100,

            // FULL AMOUNT DISCOUNT
            uInvDiscountAmt: item.price * freeQty,

            // FINAL TOTAL = 0
            lineTotal: 0,

            // MARK FREE ITEM
            uRemarkOther12: "FREE_ITEM",
          ),
        );

        continue;
      }

      // ─────────────────────────────
      // NORMAL PROMOTION
      // ─────────────────────────────
      double discountPer = item.uInvDiscountPer;
      double discountAmt = item.uInvDiscountAmt;

      double other9Per = item.uInOther9;
      double other9Amt = item.uMnOther9;

      double other10Per = item.uInOther10;
      double other10Amt = item.uMnOther10;

      double other11Per = item.uInOther11;
      double other11Amt = item.uMnOther11;

      double other12Per = item.uInOther12;
      double other12Amt = item.uMnOther12;

      double specialAmt = item.uSpecialPriceAmt;
      double specialPer = item.uSpecialPricePercent;

      double voucherAmt = item.uInvVoucherAmt;

      String remark9 = item.uRemarkOther9;
      String remark10 = item.uRemarkOther10;
      String remark11 = item.uRemarkOther11;
      String remark12 = item.uRemarkOther12;

      switch (promo.promotionType) {
        case "Discount":
          discountPer = promo.match;
          discountAmt = promo.match1;
          break;

        case "Other9":
          other9Per = promo.match;
          other9Amt = promo.match1;
          remark9 = promo.remark ?? "";
          break;

        case "Other10":
          other10Per = promo.match;
          other10Amt = promo.match1;
          remark10 = promo.remark ?? "";
          break;

        case "Other11":
          other11Per = promo.match;
          other11Amt = promo.match1;
          remark11 = promo.remark ?? "";
          break;

        case "Other12":
          other12Per = promo.match;
          other12Amt = promo.match1;
          remark12 = promo.remark ?? "";
          break;

        case "SpecialPrice":
          specialPer = promo.match;
          specialAmt = promo.match1;
          break;

        case "Voucher":
          voucherAmt = promo.match1;
          break;
      }

      final grossTotal = item.qty * item.price;

      final totalDiscount =
          discountAmt +
              other9Amt +
              other10Amt +
              other11Amt +
              other12Amt +
              specialAmt +
              voucherAmt;

      final netLineTotal = grossTotal - totalDiscount;

      controller.selectedItems[index] = SaleItem(
        itemCode: item.itemCode,
        name: item.name,
        price: item.price,
        qty: item.qty,
        uom: item.uom,
        itemGroupName: item.itemGroupName,
        subGroupDes: item.subGroupDes,
        subGroup2Des: item.subGroup2Des,

        // ─────────────────────────────
        // PROMOTION FIELDS
        // ─────────────────────────────
        uInvDiscountPer: discountPer,
        uInvDiscountAmt: discountAmt,

        uSpecialPriceAmt: specialAmt,
        uSpecialPricePercent: specialPer,

        uInvVoucherAmt: voucherAmt,

        uInOther9: other9Per,
        uMnOther9: other9Amt,
        uRemarkOther9: remark9,

        uInOther10: other10Per,
        uMnOther10: other10Amt,
        uRemarkOther10: remark10,

        uInOther11: other11Per,
        uMnOther11: other11Amt,
        uRemarkOther11: remark11,

        uInOther12: other12Per,
        uMnOther12: other12Amt,
        uRemarkOther12: remark12,

        // FINAL LINE TOTAL
        lineTotal: netLineTotal,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }
}
