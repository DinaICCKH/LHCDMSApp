// File: lib/pages/sale_visit_check_in.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuberadmsdn/Sale/Sale/sale_unplan.dart';
import 'package:kuberadmsdn/api/login_api.dart';
import 'package:kuberadmsdn/api/save_checkin_api.dart';
import '../../api/get_customer_api.dart' as api;
import '../models/customer_visit_model.dart';
import 'sale_visit_no_buy_page.dart';

class SaleVisitCheckInPage extends StatefulWidget {
  final CustomerVisit customer;
  final int? detailEntry;

  const SaleVisitCheckInPage({
    super.key,
    required this.customer,
    this.detailEntry,
  });

  @override
  State<SaleVisitCheckInPage> createState() => _SaleVisitCheckInPageState();
}

class _SaleVisitCheckInPageState extends State<SaleVisitCheckInPage> {
  // Check-in Step Variables
  bool _isLocating = false;
  Position? _currentPosition;
  File? _capturedPhoto;

  // Workflow Control States
  bool _hasSubmittedCheckIn = false;
  bool _isSubmittingApi = false;

  // Variable to hold the primary key from the API response
  String? _checkInPrimaryKey;

  // Visit Outcome States
  String? _visitOutcome;
  String? _selectedNoBuyReason;

  // Controllers
  final TextEditingController _checkInRemarkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _noBuyReasons = [
    "Stock is still full",
    "Price too high / No budget",
    "Decision maker not present",
    "Switched to competitor",
    "Store temporarily closed",
    "Other (See notes)"
  ];

  // Initialize your exact service
  final CheckInService _checkInService = CheckInService();

  api.Customer _convertToApiCustomer(CustomerVisit visitData) {
    return api.Customer(
      cardCode: visitData.cardCode,
      cardName: visitData.cardName,
      tel1: visitData.phone ?? '',
      fullAddress: visitData.fullAddress ?? '',
      code: 0,
      message: '',
      cardFName: '',
      groupCode: 0,
      groupName: '',
      id: '',
      tel2: '',
      mobile: '',
      contactPerson: '',
      contactPersonName: '',
      paymentTerm: '',
      priceList: '',
      creditLimit: 0.0,
    );
  }

  Future<void> _openHardwareCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
      );

      if (photo == null) return;

      setState(() {
        _capturedPhoto = File(photo.path);
      });

      _fetchGPSLocation();
    } catch (e) {
      _showErrorDialog("Camera access error: ${e.toString()}");
    }
  }

  Future<void> _fetchGPSLocation() async {
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
        _currentPosition = position;
        _isLocating = false;
      });
    } catch (e) {
      setState(() => _isLocating = false);
      _showErrorDialog(e.toString());
    }
  }

  /// Maps UI inputs to fulfill your unmodified CheckInService signature requirements
  Future<void> _submitArrivalTelemetry() async {
    if (_capturedPhoto == null || _currentPosition == null) {
      _showErrorDialog("Incomplete records. Ensure camera snap and GPS signals are solid.");
      return;
    }

    setState(() {
      _isSubmittingApi = true;
    });

    try {
      final DateTime now = DateTime.now();

      // Fallback fallback string if the text field is empty
      final String remarkText = _checkInRemarkController.text.trim().isEmpty
          ? "Storefront open"
          : _checkInRemarkController.text.trim();
      final currentUserCode = SessionManager.currentUser?.userCode ?? "Admin";
      final currentSalesCode = SessionManager.currentUser?.slpCode ?? "";

      // Calling your service with all its original parameters mapped correctly
      final responseData = await _checkInService.submitCheckIn(
        mode: "Add",
        docEntry: "1",
        detailEntry: widget.customer.detailEntry.toString(),
        cardCode: widget.customer.cardCode,
        checkInDate: now,                                    // Passes current DateTime object
        checkOutDate: now.add(const Duration(minutes: 15)),   // Placeholder checkout time
        checkInLat: _currentPosition!.latitude,
        checkInLng: _currentPosition!.longitude,
        checkOutLat: _currentPosition!.latitude,              // Reusing check-in lat for checkout field
        checkOutLng: _currentPosition!.longitude,              // Reusing check-in lng for checkout field
        checkInRemark: remarkText,
        checkOutRemark: "No orders today",                    // Consistent fallback string
        checkStatus: "CheckIn",                               // Defaulted as requested
        appOrderEntry: "null",                                // Transmits literal string "null"
        dmsOrderEntry: "null",
        salesCode: currentSalesCode,
        userSign: currentUserCode,
        imageFile: _capturedPhoto!,
      );

      if (responseData != null) {
        if (responseData['success'] == true) {
          setState(() {
            _checkInPrimaryKey = responseData['primaryKey']?.toString();
            _hasSubmittedCheckIn = true;
            _notesController.text = "";
            _isSubmittingApi = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('✅ Check-In Recorded! ID: $_checkInPrimaryKey'),
                backgroundColor: Colors.green
            ),
          );
        } else {
          throw responseData['message'] ?? "API failed validation backend side.";
        }
      } else {
        throw "No response returned from the check-in network service.";
      }
    } catch (err) {
      setState(() => _isSubmittingApi = false);
      _showErrorDialog("Error occurred: $err");
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

  /// Displays confirmation layout dialog box before leaving an active submission session
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Discard Check-In?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You have already verified your check-in entry status (ID: $_checkInPrimaryKey).\n\nLeaving this screen without recording a "Buy" or "No Buy" outcome will disrupt form sync workflows. Proceed anyway?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // User stays on form page
            child: const Text('Stay & Finish', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Confirms and pops screen structure back
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Discard Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _checkInRemarkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasSubmittedCheckIn, // Allow normal popping only if check-in hasn't happened yet
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Triggers dialog if system back key/gesture is triggered
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          title: Text(
            "Check-In: ${widget.customer.cardName}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasSubmittedCheckIn) {
                final shouldPop = await _showExitConfirmationDialog();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerHeader(),
              const SizedBox(height: 12),
              _buildCheckInCard(),

              if (_hasSubmittedCheckIn) ...[
                const SizedBox(height: 12),
                _buildVisitOutcomeCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
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
            Text(widget.customer.cardCode, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(widget.customer.cardName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
            const Divider(height: 16, color: Colors.black12),
            Row(
              children: [
                const Icon(Icons.phone, size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Text(widget.customer.phone.toString(), style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.customer.fullAddress.toString(), style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
              ],
            ),
            if (widget.detailEntry != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.assignment, size: 13, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("Entry ID: ${widget.detailEntry}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCard() {
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
            const Text("STEP 1: VISIT CHECK-IN (PHOTO & GPS)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 10),

            if (!_hasSubmittedCheckIn) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingApi ? null : _openHardwareCamera,
                      icon: const Icon(Icons.camera_alt, size: 15),
                      label: Text(_capturedPhoto == null ? "Open Camera & Capture" : "Retake Store Photo", style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  if (_capturedPhoto != null) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_capturedPhoto!, width: 45, height: 45, fit: BoxFit.cover),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 10),

              if (_isLocating)
                const Text("Tracking secure GPS telemetry coordinates...", style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold))
              else if (_currentPosition != null)
                Text("GPS Confirmed [Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Long: ${_currentPosition!.longitude.toStringAsFixed(5)}]",
                    style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600))
              else
                const Text("⚠️ Photo and GPS tracking required before submission.", style: TextStyle(fontSize: 11, color: Colors.black38)),

              const SizedBox(height: 12),

              // Check-In Remark User Field
              const Text("Check-In Remark", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: _checkInRemarkController,
                maxLines: 1,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: "e.g., Storefront open / Customer waiting...",
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),

              const Divider(height: 24),

              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: (_capturedPhoto == null || _currentPosition == null || _isLocating || _isSubmittingApi) ? null : _submitArrivalTelemetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmittingApi
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Submit Check-In Metrics", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(_capturedPhoto!, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text("Check-In Submitted & Locked", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Remark: ${_checkInRemarkController.text.isEmpty ? 'Storefront open' : _checkInRemarkController.text}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        Text("Lat: ${_currentPosition?.latitude.toStringAsFixed(6)} / Long: ${_currentPosition?.longitude.toStringAsFixed(6)}",
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        if (_checkInPrimaryKey != null) ...[
                          const SizedBox(height: 2),
                          Text("Database Reference ID: $_checkInPrimaryKey", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitOutcomeCard() {
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
            const Text("STEP 2: VISIT OUTCOME DISCUSSION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11)),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Buy (SO)", style: TextStyle(fontSize: 12)),
                    value: "buy",
                    groupValue: _visitOutcome,
                    onChanged: (val) => setState(() => _visitOutcome = val),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("No Buy", style: TextStyle(fontSize: 12)),
                    value: "no_buy",
                    groupValue: _visitOutcome,
                    onChanged: (val) {
                      setState(() {
                        _visitOutcome = val;
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleVisitNoBuyPage(
                            customer: widget.customer,
                            initialReason: _selectedNoBuyReason,
                            // 🚀 PASS THE PRIMARY KEY VALUE HERE
                            detailEntry: widget.customer.detailEntry,
                            checkInPrimaryKey: _checkInPrimaryKey,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _visitOutcome = null;
                        });
                      });
                    },
                  ),
                ),
              ],
            ),

            const Divider(height: 16, color: Colors.black12),

            if (_visitOutcome == "buy") ...[
              Text("Check-in requirements fulfilled. Advance to inventory distribution page.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final apiCustomer = _convertToApiCustomer(widget.customer);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SaleUnplanPage(
                          customer: apiCustomer,
                          detailEntry: widget.customer.detailEntry,       // 🚀 Pass detailEntry here
                          checkInPrimaryKey: _checkInPrimaryKey,          // 🚀 Pass Check-In Ref ID here
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text("Create Sales Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            if (_visitOutcome == "no_buy") ...[
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
              const Text("Additional Remarks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Type notes here...",
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: _selectedNoBuyReason == null ? null : () {
                    // Action for checkout submission
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Submit & Finish Visit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}