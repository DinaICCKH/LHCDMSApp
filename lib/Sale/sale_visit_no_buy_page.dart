// File: lib/pages/sale_visit_no_buy_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuberadmsdn/Sale/vistit_plan.dart';
import 'package:kuberadmsdn/api/login_api.dart'; // Added to resolve SalesCode via SessionManager
import '../api/save_checkout_api.dart';        // Adjust this import path to match your CheckOutService location
import 'models/customer_visit_model.dart';

class SaleVisitNoBuyPage extends StatefulWidget {
  final CustomerVisit customer;
  final String? initialReason;
  final String? checkInPrimaryKey; // Added to pass the database reference ID from the check-in step

  const SaleVisitNoBuyPage({
    super.key,
    required this.customer,
    this.initialReason,
    this.checkInPrimaryKey, // Received contextually from the parent page
  });

  @override
  State<SaleVisitNoBuyPage> createState() => _SaleVisitNoBuyPageState();
}

class _SaleVisitNoBuyPageState extends State<SaleVisitNoBuyPage> {
  // Checkout Validation States
  bool _isLocating = false;
  Position? _checkoutPosition;
  File? _checkoutPhoto;
  bool _isSubmitting = false;

  // Form Value States
  String? _selectedNoBuyReason;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _noBuyReasons = [
    "Stock is still full",
    "Price too high / No budget",
    "Decision maker not present",
    "Switched to competitor",
    "Store temporarily closed",
    "Other (See notes)"
  ];

  // Instantiate your checkout service dependency
  final CheckOutService _checkOutService = CheckOutService();

  @override
  void initState() {
    super.initState();
    if (widget.initialReason != null && _noBuyReasons.contains(widget.initialReason)) {
      _selectedNoBuyReason = widget.initialReason;
    }
  }

  /// Force Camera Hardware Capture for Checkout Verification
  Future<void> _openHardwareCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
      );

      if (photo == null) return;

      setState(() {
        _checkoutPhoto = File(photo.path);
      });

      _fetchCheckoutGPS();
    } catch (e) {
      _showErrorDialog("Camera access error: ${e.toString()}");
    }
  }

  /// Internal GPS telemetry gatherer
  Future<void> _fetchCheckoutGPS() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _checkoutPosition = position;
        _isLocating = false;
      });
    } catch (e) {
      setState(() => _isLocating = false);
      _showErrorDialog(e.toString());
    }
  }

  /// Final Submissions Logic pipeline integrated with CheckOutService
  Future<void> _submitNoBuyCheckout() async {
    if (_selectedNoBuyReason == null) {
      _showErrorDialog("Please specify a reason why the client is not purchasing.");
      return;
    }
    if (_checkoutPhoto == null || _checkoutPosition == null) {
      _showErrorDialog("Checkout evidence mandatory. Provide a storefront photo verification.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final DateTime executionTime = DateTime.now();

      // Compile reason and optional notes into the remark text field
      final String remarkText = _notesController.text.trim().isEmpty
          ? "No-Buy Reason: $_selectedNoBuyReason"
          : "No-Buy Reason: $_selectedNoBuyReason | Notes: ${_notesController.text.trim()}";

      // Dynamically extract the active session values safely
      final String currentSalesCode = SessionManager.currentUser?.slpCode ?? "";
      final String targetDocEntry = widget.checkInPrimaryKey.toString();

      // Call the endpoint via your service layer mapping strategy
      final responseData = await _checkOutService.submitCheckOut(
        mode: "Add", // Update workflow flags context relative to matching baseline check-ins
        docEntry: targetDocEntry,
        checkOutDate: executionTime,
        checkOutLat: _checkoutPosition!.latitude,
        checkOutLng: _checkoutPosition!.longitude,
        checkOutRemark: remarkText,
        salesCode: currentSalesCode,
        imageFiles: [_checkoutPhoto!], // Wraps single local file target into expected list element
      );

      setState(() => _isSubmitting = false);

      if (responseData != null && responseData['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Checkout completed successfully.'),
              backgroundColor: Colors.green
          ),
        );

        // 🔄 CHANGE THIS: Clear stack completely and rebuild VisitPlanPage fresh
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VisitPlanPage()),
              (route) => route.isFirst, // Keeps your main/home menu screen alive underneath
        );
      } else {
        final errorMessage = responseData != null ? responseData['message'] : "Server failed or validation rejected.";
        throw errorMessage ?? "Unknown response payload schema.";
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog("Submission Error: ${e.toString()}");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Action Required', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        title: Text(
          "No-Buy Checkout: ${widget.customer.cardName}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSummaryCard(),
            const SizedBox(height: 12),
            _buildFormControlsCard(),
            const SizedBox(height: 12),
            _buildEvidenceCard(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSummaryCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.customer.cardCode, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(widget.customer.cardName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                  if (widget.checkInPrimaryKey != null) ...[
                    const SizedBox(height: 2),
                    Text("Check-In Ref ID: ${widget.checkInPrimaryKey}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormControlsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LOG VISIT DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 10),
            const Text("Reason Required *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedNoBuyReason,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              hint: const Text("Select why they aren't buying", style: TextStyle(fontSize: 12)),
              items: _noBuyReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => setState(() => _selectedNoBuyReason = val),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 12),
            const Text("Additional Remarks / Feedback", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Type comments here...",
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MANDATORY CHECK-OUT PROOF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openHardwareCamera,
                    icon: const Icon(Icons.camera_alt, size: 15),
                    label: Text(_checkoutPhoto == null ? "Capture Checkout Photo" : "Retake Photo", style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (_checkoutPhoto != null) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(_checkoutPhoto!, width: 45, height: 45, fit: BoxFit.cover),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 10),
            if (_isLocating)
              const Text("Locking accurate checkout GPS parameters...", style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold))
            else if (_checkoutPosition != null)
              Text("Checkout GPS Recorded [Lat: ${_checkoutPosition!.latitude.toStringAsFixed(5)}, Long: ${_checkoutPosition!.longitude.toStringAsFixed(5)}]",
                  style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600))
            else
              const Text("⚠️ A camera verification snapshot is required to calculate checkout metrics.", style: TextStyle(fontSize: 11, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _selectedNoBuyReason != null && _checkoutPhoto != null && _checkoutPosition != null && !_isLocating;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: (canSubmit && !_isSubmitting) ? _submitNoBuyCheckout : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Finalize Checkout & Exit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}