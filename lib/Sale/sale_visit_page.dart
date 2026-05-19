import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/get_item_api.dart' as itemApi;
import 'models/customer_visit_model.dart';
import 'sale_visit_controller.dart';
import 'models/sale_order_model.dart';
import '../api/sale_order_api.dart'; // Adjust path if necessary


// ─────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────
const _kPrimary = Color(0xFF1565C0);
const _kBg = Color(0xFFF0F4FA);
const _kCard = Colors.white;
const _kAccent = Color(0xFF00ACC1);
const _kDanger = Color(0xFFE53935);
const _kSuccess = Color(0xFF43A047);
const _kOrange = Color(0xFFFB8C00);

class SaleFromVisitPage extends StatefulWidget {
  final CustomerVisit customer;

  const SaleFromVisitPage({
    super.key,
    required this.customer,
  });

  @override
  State<SaleFromVisitPage> createState() => _SaleFromVisitPageState();
}

class _SaleFromVisitPageState extends State<SaleFromVisitPage>
    with SingleTickerProviderStateMixin {
  final SaleVisitController controller = SaleVisitController();

  int _step = 1;
  String searchItem = "";
  List<dynamic> items = [];
  bool isLoadingItem = true;
  bool isSaving = false;
  bool isRunningPromotion = false;

  final TextEditingController remarkController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String ownerValue = "Admin";
  String paymentMethodValue = "Invoice";
  TimeOfDay? deliveryTime;
  File? imageFile;
  Position? currentPosition;

  AnimationController? _animController;
  Animation<double>? _fadeAnim;

  // ── FIX #3: All discount fields declared at the TOP of state ──────────────
  double discountPercent = 0.0;
  double discountAmount = 0.0;
  final TextEditingController _discountPercentCtrl = TextEditingController();
  final TextEditingController _discountAmountCtrl = TextEditingController();
  bool _isUpdatingDiscount = false;

  // ─── Getters ───────────────────────────────────────────────────────────────
  double get subTotal => controller.selectedItems
      .fold(0.0, (sum, item) => sum + item.price * item.qty);

  double get docTotal => subTotal - discountAmount;

  @override
  void initState() {
    super.initState();
    controller.selectCustomer(widget.customer);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );
    _animController!.forward();

    _initialize();
  }

  @override
  void dispose() {
    _animController?.dispose();
    remarkController.dispose();
    searchController.dispose();
    _discountPercentCtrl.dispose();
    _discountAmountCtrl.dispose();
    super.dispose();
  }

  void _switchStep(int step) {
    _animController?.forward(from: 0);
    setState(() => _step = step);
  }

  Widget _buildCurrentStep() {
    return _step == 1
        ? buildItemStep()
        : _step == 2
        ? buildCartPreviewStep()
        : buildSummaryStep();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    await _loadItems();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _loadItems() async {
    setState(() => isLoadingItem = true);
    items = await itemApi.ItemApi.getLocalItems();
    setState(() => isLoadingItem = false);
  }

  Future<void> takePhoto() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showSnack("Camera permission denied", isError: true);
        return;
      }
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        _showSnack("Location permission denied", isError: true);
        return;
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
      );
      if (picked != null) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          imageFile = File(picked.path);
          currentPosition = position;
        });
        _showSnack("Photo captured successfully");
      }
    } catch (e) {
      _showSnack("Camera error: $e", isError: true);
    }
  }

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
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  Future<void> runPromotion() async {
    setState(() => isRunningPromotion = true);
    await Future.delayed(const Duration(seconds: 1));
    List<SaleItem> freeItems = [];
    for (var item in controller.selectedItems) {
      if (item.qty >= 5) {
        freeItems.add(SaleItem(
          itemCode: "${item.itemCode}-FREE",
          name: "${item.name} (FREE)",
          price: 0,
          qty: 1,
          uom: item.uom,
          itemGroupName: item.itemGroupName,
          subGroupDes: item.subGroupDes,
          subGroup2Des: item.subGroup2Des,
          manufacturerDes: item.manufacturerDes,
        ));
      }
    }
    controller.selectedItems.addAll(freeItems);
    setState(() => isRunningPromotion = false);
    _showSnack("Promotion applied! Buy 5 Get 1 Free");
  }

  // ── FIX #3: Discount sync logic uses the correctly scoped fields ──────────

  void _onDiscountPercentChanged(String value) {
    if (_isUpdatingDiscount) return;
    _isUpdatingDiscount = true;

    double percent = double.tryParse(value) ?? 0.0;

    // ── Prevent percent exceeding 100 ──────────────────────────────────────
    if (percent > 100) {
      percent = 100;
      _discountPercentCtrl.text = "100";
      _discountPercentCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountPercentCtrl.text.length),
      );
    } else if (percent < 0) {
      percent = 0;
      _discountPercentCtrl.text = "0";
      _discountPercentCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountPercentCtrl.text.length),
      );
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

    // ── Prevent amount exceeding SubTotal (which equals 100%) ──────────────
    if (amount > subTotal) {
      amount = subTotal;
      _discountAmountCtrl.text = subTotal.toStringAsFixed(2);
      _discountAmountCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountAmountCtrl.text.length),
      );
    } else if (amount < 0) {
      amount = 0;
      _discountAmountCtrl.text = "0.00";
      _discountAmountCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountAmountCtrl.text.length),
      );
    }

    final percent = subTotal > 0 ? (amount / subTotal) * 100 : 0.0;

    setState(() {
      discountAmount  = amount;
      discountPercent = percent;
    });

    _discountPercentCtrl.text = percent.toStringAsFixed(2);
    _isUpdatingDiscount = false;
  }



  bool isItemSelected(String itemCode) =>
      controller.selectedItems.any((e) => e.itemCode == itemCode);

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: isError ? _kDanger : _kSuccess,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
                child: _fadeAnim == null
                    ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: _buildCurrentStep(),
                )
                    : FadeTransition(
                  opacity: _fadeAnim!,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
            "Sale From Visit",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            widget.customer.cardName,
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
        if (_step == 1 && controller.selectedItems.isNotEmpty)
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
      child: Row(
        children: [
          _stepDot(1, "Items"),
          _stepConnector(1),
          _stepDot(2, "Cart"),
          _stepConnector(2),
          _stepDot(3, "Summary"),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final done = _step > step;
    final active = _step == step;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (step < _step) _switchStep(step);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? _kSuccess
                    : active
                    ? _kPrimary
                    : Colors.grey.shade200,
                boxShadow: active
                    ? [
                  BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
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
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepConnector(int afterStep) {
    final passed = _step > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: passed ? _kSuccess : Colors.grey.shade300,
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
  // STEP 1 — ITEM SELECTION
  // ─────────────────────────────────────────────────────
  Widget buildItemStep() {
    if (isLoadingItem) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 12),
            Text(
              "Loading items...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final filteredItems = items.where((i) {
      final q = searchItem.toLowerCase();
      return i.itemName.toLowerCase().contains(q) ||
          i.itemCode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildCustomerChip(),
        const SizedBox(height: 8),
        _buildSearchField(),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              "${filteredItems.length} item(s) found",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Spacer(),
            if (controller.selectedItems.isNotEmpty)
              Text(
                "${controller.selectedItems.length} selected",
                style: const TextStyle(
                    fontSize: 11,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState(
              "No items found", Icons.inventory_2_outlined)
              : ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final selected = isItemSelected(item.itemCode);
              return _buildItemCard(item, selected);
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPrimaryButton(
          label:
          "Go to Cart  (${controller.selectedItems.length} item(s))",
          icon: Icons.shopping_cart_outlined,
          onPressed: controller.selectedItems.isEmpty
              ? null
              : () => _switchStep(2),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.cardCode,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  widget.customer.cardName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      style: const TextStyle(fontSize: 13),
      onChanged: (v) => setState(() => searchItem = v),
      decoration: InputDecoration(
        hintText: "Search by name or code...",
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        prefixIcon:
        const Icon(Icons.search, size: 20, color: Colors.grey),
        suffixIcon: searchItem.isNotEmpty
            ? IconButton(
          icon:
          const Icon(Icons.close, size: 18, color: Colors.grey),
          onPressed: () {
            searchController.clear();
            setState(() => searchItem = "");
          },
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

  Widget _buildItemCard(dynamic item, bool selected) {
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
          onTap: () => _toggleItem(item),
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
              color: selected
                  ? Colors.white
                  : Colors.grey,
            ),
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

              if ((item.itemBrandDes ?? "").isNotEmpty)
                _detailChip(
                  Icons.branding_watermark,
                  item.itemBrandDes!,
                ),

              if ((item.manufacturerDes ?? "").isNotEmpty)
                _detailChip(
                  Icons.factory,
                  item.manufacturerDes!,
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

              onPressed: () => _toggleItem(item),

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _toggleItem(dynamic item) {
    final existingIndex = controller.selectedItems
        .indexWhere((e) => e.itemCode == item.itemCode);
    setState(() {
      if (existingIndex >= 0) {
        controller.selectedItems.removeAt(existingIndex);
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
  // STEP 2 — CART PREVIEW
  // ─────────────────────────────────────────────────────
  Widget buildCartPreviewStep() {
    return Column(
      children: [
        // ─── Header ──────────────────────────────────────────────────────────
        _buildSectionHeader(
          "Cart Review",
          "${controller.selectedItems.length} item(s)",
        ),
        const SizedBox(height: 8),

        // ─── Item List Only ───────────────────────────────────────────────────
        Expanded(
          child: controller.selectedItems.isEmpty
              ? _buildEmptyState(
              "Cart is empty", Icons.shopping_cart_outlined)
              : ListView.builder(
            itemCount: controller.selectedItems.length,
            itemBuilder: (_, index) {
              final item = controller.selectedItems[index];
              return _buildCartItem(item, index);
            },
          ),
        ),

        // ─── Simple SubTotal Bar ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text(
                "Subtotal",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "\$${subTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ─── Nav Buttons ──────────────────────────────────────────────────────
        _buildNavButtons(
          onBack: () => _switchStep(1),
          onNext: controller.selectedItems.isEmpty
              ? null
              : () => _switchStep(3),
          nextLabel: "Proceed to Summary",
        ),
      ],
    );
  }


  Widget _buildCartItem(SaleItem item, int index) {
    final qtyController =
    TextEditingController(text: item.qty.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.itemCode,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.uom,
                        style: const TextStyle(
                          fontSize: 9,
                          color: _kAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${(item.price * item.qty).toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Row(
                children: [
                  _qtyBtn(
                    icon: Icons.remove,
                    color: item.qty <= 1
                        ? Colors.grey.shade300
                        : _kDanger,
                    onTap: item.qty <= 1
                        ? null
                        : () => setState(() => item.qty--),
                  ),
                  SizedBox(
                    width: 42,
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                          const BorderSide(color: _kPrimary),
                        ),
                      ),
                      onSubmitted: (v) {
                        final qty = double.tryParse(v);
                        if (qty != null && qty >= 1) {
                          setState(() => item.qty = qty);
                        }
                      },
                    ),
                  ),
                  _qtyBtn(
                    icon: Icons.add,
                    color: _kSuccess,
                    onTap: () => setState(() => item.qty++),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "@\$${item.price.toStringAsFixed(2)}",
                style:
                const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.delete_outline,
              color: _kDanger,
              size: 20,
            ),
            onPressed: () =>
                setState(() => controller.removeItem(item)),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
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
              _buildSectionHeader("Order Details", "Fill in order info"),
              const SizedBox(height: 8),

              // ── Owner & Payment ─────────────────────────────────────────────
              Row(
                children: [
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
                ],
              ),
              const SizedBox(height: 8),

              // ── Delivery Time ───────────────────────────────────────────────
              _buildTapCard(
                icon: Icons.schedule,
                label: "Delivery Time",
                value: deliveryTime == null
                    ? "Tap to set time"
                    : _formatTime(deliveryTime!),
                onTap: pickDeliveryTime,
                hasValue: deliveryTime != null,
              ),
              const SizedBox(height: 10),

              // ── Promotion ───────────────────────────────────────────────────
              _buildPromotionButton(),
              const SizedBox(height: 10),

              // ── Items List ──────────────────────────────────────────────────
              _buildSectionHeader(
                "Items (${controller.selectedItems.length})",
                "",
              ),
              const SizedBox(height: 6),
              ...controller.selectedItems.map(_buildSummaryItem),
              const SizedBox(height: 8),

              // ── Remark ──────────────────────────────────────────────────────
              TextField(
                controller: remarkController,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Add a remark (optional)",
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note,
                    color: Colors.grey,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: _kCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),

              // ── Photo ───────────────────────────────────────────────────────
              _buildPhotoSection(),
              const SizedBox(height: 14),

              // ── Order Summary Card (Discount lives here ONLY) ───────────────
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
        style:
        const TextStyle(fontSize: 12, color: Colors.black87),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: hasValue ? _kPrimary : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionButton() {
    return GestureDetector(
      onTap: isRunningPromotion ? null : runPromotion,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRunningPromotion
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
                    color: Colors.white, strokeWidth: 2),
              )
            else
              const Icon(Icons.local_offer, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              isRunningPromotion
                  ? "Applying..."
                  : "Run Promotion  (Buy 5 Get 1 Free)",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(SaleItem item) {
    final isFree = item.price == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFree ? _kSuccess.withOpacity(0.06) : _kCard,
        borderRadius: BorderRadius.circular(10),
        border: isFree
            ? Border.all(color: _kSuccess.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          if (isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _kSuccess,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "FREE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "${item.itemCode}  x${item.qty}  ${item.uom}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            isFree
                ? "FREE"
                : "\$${(item.qty * item.price).toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isFree ? _kSuccess : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFile != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => imageFile = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (currentPosition != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Lat: ${currentPosition!.latitude.toStringAsFixed(5)}, "
                        "Lng: ${currentPosition!.longitude.toStringAsFixed(5)}",
                    style:
                    const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kPrimary),
            foregroundColor: _kPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            minimumSize: const Size(double.infinity, 0),
          ),
          onPressed: takePhoto,
          icon: const Icon(Icons.camera_alt_outlined, size: 16),
          label: Text(
            imageFile == null ? "Capture Photo" : "Retake Photo",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ─── 1. SubTotal ──────────────────────────────────────────────────────────
  Widget _buildSubTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subtotal",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "qty x price",
                style:
                TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "\$${subTotal.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Discount Row ──────────────────────────────────────────────────────
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Label ──────────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discount",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "edit % or amount",
                style: TextStyle(color: Colors.orange.shade300, fontSize: 10),
              ),
            ],
          ),

          const Spacer(),

          // ── Percent Input ───────────────────────────────────────────────────
          // FIX: wrap each input in Flexible to prevent overflow
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
            child: Text(
              "|",
              style: TextStyle(color: Colors.orange.shade200, fontSize: 18),
            ),
          ),

          // ── Amount Input ────────────────────────────────────────────────────
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

  // ── FIX #2: Renamed `controller` param → `textCtrl` to prevent shadowing ──
  Widget _buildDiscountInput({
    required TextEditingController textCtrl,
    required Function(String) onChanged,
    required MaterialColor color,
    String prefix = "",
    String suffix = "",
  }) {
    return Container(
      // FIX: replaced fixed width: 88 with constraints
      constraints: const BoxConstraints(maxWidth: 84, minWidth: 60),
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                prefix,
                style: TextStyle(
                  color: color.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                hintText: "0",
              ),
            ),
          ),
          if (suffix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                suffix,
                style: TextStyle(
                  color: color.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }


  // ─── 3. DocTotal ──────────────────────────────────────────────────────────
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Doc Total",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                "subtotal - discount",
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "\$${docTotal.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Master Summary Section ────────────────────────────────────────────────
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
          // ── Section Label ─────────────────────────────────────────────────
          _buildSectionHeader("Order Summary", ""),
          const SizedBox(height: 12),

          // ── 1. SubTotal ───────────────────────────────────────────────────
          _buildSubTotal(),
          const SizedBox(height: 10),

          // ── 2. Discount ───────────────────────────────────────────────────
          _buildDiscountRow(),
          const SizedBox(height: 10),

          // ── Divider ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Total",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 3. DocTotal ───────────────────────────────────────────────────
          _buildDocTotal(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
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
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    return Row(
      children: [
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
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nextLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (nextIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(nextIcon, size: 14),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            msg,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // SAVE ORDER
  // ─────────────────────────────────────────────────────
  Future<void> saveOrder() async {
    if (controller.selectedItems.isEmpty) return;

    // 1. Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Order", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text("Submit order for ${widget.customer.cardName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => isSaving = true);

    try {
      final now = DateTime.now();
      final String dateStr = now.toIso8601String().substring(0, 10); // YYYY-MM-DD

      // 2. Map UI Items to your SaleOrderLine Model
      // This uses the constructor you provided.
      // The "Fixed" values (OcrCode2, U_InvPaymentAmt, etc.) are handled inside the model's toJson().
      List<SaleOrderLine> so1Lines = [];
      for (int i = 0; i < controller.selectedItems.length; i++) {
        final item = controller.selectedItems[i];

        so1Lines.add(SaleOrderLine(
          docEntry: 1,
          lineNum: i,
          itemCode: item.itemCode,
          dscription: item.name,
          quantity: item.qty.toDouble(),
          uomCode: item.uom,
          price: item.price,
          lineTotal: item.qty * item.price,
          // The following will use the default values from your class (e.g., WhsCode: "WH001")
          // and your toJson() will add all the 0s and nulls you requested.
        ));
      }

      // 3. Construct the Payload
      final payload = SaleOrderPayload(
        docDate: dateStr,
        docDueDate: dateStr,
        uDeliveryTime: deliveryTime != null
            ? "${deliveryTime!.hour}:${deliveryTime!.minute}"
            : "",
        cardCode: widget.customer.cardCode,
        ref2: widget.customer.detailEntry.toString(),
        cardName: widget.customer.cardName,
        address: widget.customer.fullAddress.toString(),
        discPrcnt: discountPercent,
        discSum: discountAmount,
        subTotal: subTotal,
        docTotal: docTotal,
        comments: remarkController.text.trim(),
        uPaymentMethod: paymentMethodValue,
        uOwner: ownerValue,
        createDate: now.toIso8601String().split('.').first,
        checkInDate: now.toIso8601String().split('.').first,
        checkOutDate: now.toIso8601String().split('.').first,
        imageUrl: imageFile?.path ?? "",
        checkInLateLong: currentPosition?.latitude ?? 0.0,
        so1Lines: so1Lines,
      );

      // 4. Submit to API
      // This calls your SaleOrderApi.submitOrder which uses payload.toJson()
      // payload.toJson() calls so1Lines[i].toJson()
      // -> That's where all your fixed columns (OcrCode2: null, etc.) are added!


      final String prettyJson = const JsonEncoder.withIndent('  ').convert(payload.toJson());
      print("─────── DEBUG: SALE ORDER PAYLOAD ───────");
      print(prettyJson);
      print("──────────────────────────────────────────");
      final result = await SaleOrderApi.submitOrder(payload: payload);

      if (!mounted) return;

      if (result.isSuccess) {
        _showSnack("Order saved and submitted successfully!");

        // Also save locally for history
        final prefs = await SharedPreferences.getInstance();
        List<String> existing = prefs.getStringList("localOrders") ?? [];
        existing.add(jsonEncode(payload.toJson()));
        await prefs.setStringList("localOrders", existing);

        Navigator.pop(context);
      } else {
        _showSnack(result.message ?? "Error submitting order", isError: true);
      }

    } catch (e) {
      if (mounted) _showSnack("Unexpected error: $e", isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

}
