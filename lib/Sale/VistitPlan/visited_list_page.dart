import 'package:flutter/material.dart';
import 'package:kuberadmsdn/api/get_vistited_planlist_api.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';

/// =============================================================
/// VISITED LIST TRANSACTION LOG ARCHIVE VIEW
/// =============================================================
class VisitedListPage extends StatefulWidget {
  const VisitedListPage({super.key});

  @override
  State<VisitedListPage> createState() => _VisitedListPageState();
}

class _VisitedListPageState extends State<VisitedListPage> {
  List<VisitCheckInResult> allLogs = [];
  List<VisitCheckInResult> filteredLogs = [];
  List<VisitCheckInResult> displayedLogs = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = "";

  final int pageSize = 15;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String _selectedStatus = "All";

  final Map<String, String> _statusOptions = {
    "All": "All Logs",
    "CheckIn": "Checked In Only",
    "CheckOut": "Completed Visited",
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, 1);
    _selectedToDate = now;

    _fetchLiveCheckInLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatApiDate(DateTime? date) {
    if (date == null) return "2000-01-01";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateTimeString(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchLiveCheckInLogs() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final results = await VisitPlanCheckInApi.fetchVisitCheckIns(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e",
        fromDate: _formatApiDate(_selectedFromDate),
        toDate: _formatApiDate(_selectedToDate),
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          allLogs = results;
          filteredLogs = results;
          currentPage = 1;
          displayedLogs = _paginate(filteredLogs);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<VisitCheckInResult> _paginate(List<VisitCheckInResult> items) {
    final end = (pageSize * currentPage);
    if (end >= items.length) return items;
    return items.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoadingMore) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadMoreLogs() async {
    if (displayedLogs.length >= filteredLogs.length) return;

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));
    currentPage++;

    setState(() {
      displayedLogs = _paginate(filteredLogs);
      isLoadingMore = false;
    });
  }

  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allLogs.where((log) {
      final matchCardCode = log.cardCode.toLowerCase().contains(searchQuery);
      final matchUser = (log.userSign ?? "").toLowerCase().contains(searchQuery);
      final matchRemarks = (log.checkInRemark ?? "").toLowerCase().contains(searchQuery) ||
          (log.checkOutRemark ?? "").toLowerCase().contains(searchQuery);

      return matchCardCode || matchUser || matchRemarks;
    }).toList();

    setState(() {
      filteredLogs = filtered;
      currentPage = 1;
      displayedLogs = _paginate(filteredLogs);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? (_selectedFromDate ?? DateTime.now()) : (_selectedToDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = picked;
        } else {
          _selectedToDate = picked;
        }
      });
    }
  }

  /// =============================================================
  /// PREMIUM CHROME LISTING LOG DISPLAY CARD
  /// =============================================================
  Widget checkInLogCard(VisitCheckInResult log) {
    final bool hasCheckedOut = log.checkOutDate != null;

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
            backgroundColor: hasCheckedOut ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
            child: Icon(
              hasCheckedOut ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
              color: hasCheckedOut ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          title: Text(
            log.cardCode.isEmpty ? "-" : log.cardCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Doc ID: ${log.docEntry}  •  Rep Sign: ${log.userSign ?? '-'}",
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: log.checkStatus == "Complete" ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (log.checkStatus ?? "CheckIn").toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: log.checkStatus == "Complete" ? const Color(0xFF1D4ED8) : const Color(0xFFD97706),
              ),
            ),
          ),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            _timelineRow("Check-In", _formatDateTimeString(log.checkInDate), log.checkInRemark, log.checkInGps, log.checkInImage),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 7),
                  SizedBox(
                    height: 16,
                    child: VerticalDivider(color: Colors.grey.shade300, width: 2, thickness: 1.5),
                  ),
                ],
              ),
            ),

            _timelineRow("Check-Out", _formatDateTimeString(log.checkOutDate), log.checkOutRemark, log.checkOutGps, log.checkOutImage),

            if (log.appOrderEntry != null || log.dmsOrderEntry != null) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBlock("App Order Ref", log.appOrderEntry?.toString() ?? "-"),
                  _infoBlock("DMS Order Ref", log.dmsOrderEntry?.toString() ?? "-"),
                ],
              )
            ]
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _timelineRow(String phase, String timestamp, String? remark, String? gps, String? imageUrl) {
    final bool isCheckIn = phase == "Check-In";
    final String fullImageUrl = imageUrl ?? "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
          size: 16,
          color: isCheckIn ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$phase: $timestamp", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.pin_drop_outlined, size: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      gps ?? 'No Coordinates Localized',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                    ),
                  ),
                ],
              ),
              if (remark != null && remark.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "Notes: $remark",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 🔍 Tap thumbnail to view full-screen image
        GestureDetector(
          onTap: () {
            if (fullImageUrl.isNotEmpty) {
              _showFullScreenImage(context, fullImageUrl, phase);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: fullImageUrl.isNotEmpty
                ? Image.network(
              fullImageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.broken_image_rounded, size: 16, color: Colors.grey),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              },
            )
                : Container(
              width: 50,
              height: 50,
              color: const Color(0xFFF1F5F9),
              child: const Icon(Icons.image_not_supported_rounded, size: 16, color: Colors.black26),
            ),
          ),
        )
      ],
    );
  }

  // 🖼️ Full-Screen Image Viewer Dialog with Save Option
  void _showFullScreenImage(BuildContext context, String imageUrl, String phase) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Interactive Viewer lets users pinch-to-zoom the photo
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    "Failed to load image",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            // Top Bar: Title & Close Button
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$phase Image",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Bottom Bar: Save Button
            Positioned(
              bottom: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  try {
                    // Show loading indicator or snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Downloading image..."), duration: Duration(seconds: 1)),
                    );

                    // Fetch bytes using http
                    final response = await http.get(Uri.parse(imageUrl));
                    if (response.statusCode == 200) {
                      // Save using Gal package
                      await Gal.putImageBytes(response.bodyBytes);

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Image saved to photos successfully!"), backgroundColor: Colors.green),
                        );
                      }
                    } else {
                      throw Exception("Failed to download");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to save image: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text("Save to Photos", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// =============================================================
  /// DYNAMIC ROOT BUILD ELEMENT TREE
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Visited Log Listing", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.sync_rounded), onPressed: _fetchLiveCheckInLogs)],
      ),
      body: Column(
        children: [
          // Filter Suite Header
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E3A8A),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedFromDate == null ? "From" : _selectedFromDate!.toIso8601String().split('T')[0],
                                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedToDate == null ? "To" : _selectedToDate!.toIso8601String().split('T')[0],
                                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _selectedStatus = newValue);
                            },
                            items: _statusOptions.entries.map((entry) {
                              return DropdownMenuItem<String>(value: entry.key, child: Text(entry.value));
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _fetchLiveCheckInLogs,
                        icon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF1E3A8A)),
                        label: const Text("Search", style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Local Dynamic Live Search Input Bar
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 4),
            child: TextField(
              onChanged: _filter,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Filter current matching local records...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.manage_search_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Subtext Counter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Historical Verification Feed",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${filteredLogs.length} logs",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),

          // Main Body Content Canvas
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
                : displayedLogs.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 44, color: Colors.black26),
                  SizedBox(height: 8),
                  Text("No tracking logs matching framework specs", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: displayedLogs.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < displayedLogs.length) {
                  return checkInLogCard(displayedLogs[index]);
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}