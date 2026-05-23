import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_api.dart'; // Points correctly to your session file

/// =============================================================
/// SALE LISTING RESULT MODEL CLASS (Raw Data Model with DocEntry)
/// =============================================================
class SaleListingResult {
  // HEADER FIELDS (From Table T1: SO)
  final int code;
  final String? message;
  final int? docEntry; // Added DocEntry Field
  final String? bplId;
  final String? bplName;
  final String? docStatus;
  final DateTime? docDate;
  final String? uDeliveryTime;
  final String? uPaymentMethod;
  final String? uOwner;
  final String? cardCode;
  final String? cardName;
  final String? address;
  final String? numAtCard;
  final double subTotal;
  final double discPrcnt;
  final double discSum;
  final double docTotal;
  final String? comments;
  final String? userSign;
  final String? salesCode;
  final String? apiStatus;
  final String? apiErrMessage;
  final String? sapDocEntry;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? checkOutLateLong;
  final String? checkOutRemark;
  final String? sapSyncStatus;
  final String? appStatus;
  final String? dataSource;

  // LINE FIELDS (From Table T2: SO1)
  final int? lineNum;
  final String? itemCode;
  final String? dscription;
  final double? quantity;
  final String uomCode;
  final double? price;
  final double? discountAmt;
  final double? lineTotal;
  final String? whsCode;
  final String? ocrCode;
  final String? ocrCode2;
  final String? ocrCode3;
  final String? ocrCode4;

  SaleListingResult({
    required this.code,
    this.message,
    this.docEntry, // Included in Constructor
    this.bplId,
    this.bplName,
    this.docStatus,
    this.docDate,
    this.uDeliveryTime,
    this.uPaymentMethod,
    this.uOwner,
    this.cardCode,
    this.cardName,
    this.address,
    this.numAtCard,
    required this.subTotal,
    required this.discPrcnt,
    required this.discSum,
    required this.docTotal,
    this.comments,
    this.userSign,
    this.salesCode,
    this.apiStatus,
    this.apiErrMessage,
    this.sapDocEntry,
    this.checkInDate,
    this.checkOutDate,
    this.checkOutLateLong,
    this.checkOutRemark,
    this.sapSyncStatus,
    this.appStatus,
    this.dataSource,
    this.lineNum,
    this.itemCode,
    this.dscription,
    this.quantity,
    required this.uomCode,
    this.price,
    this.discountAmt,
    this.lineTotal,
    this.whsCode,
    this.ocrCode,
    this.ocrCode2,
    this.ocrCode3,
    this.ocrCode4,
  });

  factory SaleListingResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    String? toNullableStr(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    String toStr(dynamic value) {
      return value?.toString() ?? '';
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return SaleListingResult(
      code: toInt(json['Code']),
      message: toNullableStr(json['Message']),
      docEntry: toNullableInt(json['DocEntry']), // Safely Parsed
      bplId: toNullableStr(json['BPLId']),
      bplName: toNullableStr(json['BPLName']),
      docStatus: toNullableStr(json['DocStatus']),
      docDate: parseDate(json['DocDate']),
      uDeliveryTime: toNullableStr(json['U_DeliveryTime']),
      uPaymentMethod: toNullableStr(json['U_PaymentMethod']),
      uOwner: toNullableStr(json['U_Owner']),
      cardCode: toNullableStr(json['CardCode']),
      cardName: toNullableStr(json['CardName']),
      address: toNullableStr(json['Address']),
      numAtCard: toNullableStr(json['NumAtCard']),
      subTotal: toDouble(json['SubTotal']),
      discPrcnt: toDouble(json['DiscPrcnt']),
      discSum: toDouble(json['DiscSum']),
      docTotal: toDouble(json['DocTotal']),
      comments: toNullableStr(json['Comments']),
      userSign: toNullableStr(json['UserSign']),
      salesCode: toNullableStr(json['SalesCode']),
      apiStatus: toNullableStr(json['APIStatus']),
      apiErrMessage: toNullableStr(json['APIErrMessage']),
      sapDocEntry: toNullableStr(json['SAPDocEntry']),
      checkInDate: parseDate(json['CheckInDate']),
      checkOutDate: parseDate(json['CheckOutDate']),
      checkOutLateLong: toNullableStr(json['CheckOutLateLong']),
      checkOutRemark: toNullableStr(json['CheckOutRemark']),
      sapSyncStatus: toNullableStr(json['SAPSyncStatus']),
      appStatus: toNullableStr(json['AppStatus']),
      dataSource: toNullableStr(json['DataSource']),
      lineNum: toNullableInt(json['LineNum']),
      itemCode: toNullableStr(json['ItemCode']),
      dscription: toNullableStr(json['Dscription']),
      quantity: toNullableDouble(json['Quantity']),
      uomCode: toStr(json['UomCode']),
      price: toNullableDouble(json['Price']),
      discountAmt: toNullableDouble(json['DiscountAmt']),
      lineTotal: toNullableDouble(json['LineTotal']),
      whsCode: toNullableStr(json['WhsCode']),
      ocrCode: toNullableStr(json['OcrCode']),
      ocrCode2: toNullableStr(json['OcrCode2']),
      ocrCode3: toNullableStr(json['OcrCode3']),
      ocrCode4: toNullableStr(json['OcrCode4']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'Message': message,
      'DocEntry': docEntry, // Included in Serializer
      'BPLId': bplId,
      'BPLName': bplName,
      'DocStatus': docStatus,
      'DocDate': docDate?.toIso8601String(),
      'U_DeliveryTime': uDeliveryTime,
      'U_PaymentMethod': uPaymentMethod,
      'U_Owner': uOwner,
      'CardCode': cardCode,
      'CardName': cardName,
      'Address': address,
      'NumAtCard': numAtCard,
      'SubTotal': subTotal,
      'DiscPrcnt': discPrcnt,
      'DiscSum': discSum,
      'DocTotal': docTotal,
      'Comments': comments,
      'UserSign': userSign,
      'SalesCode': salesCode,
      'APIStatus': apiStatus,
      'APIErrMessage': apiErrMessage,
      'SAPDocEntry': sapDocEntry,
      'CheckInDate': checkInDate?.toIso8601String(),
      'CheckOutDate': checkOutDate?.toIso8601String(),
      'CheckOutLateLong': checkOutLateLong,
      'CheckOutRemark': checkOutRemark,
      'SAPSyncStatus': sapSyncStatus,
      'AppStatus': appStatus,
      'DataSource': dataSource,
      'LineNum': lineNum,
      'ItemCode': itemCode,
      'Dscription': dscription,
      'Quantity': quantity,
      'UomCode': uomCode,
      'Price': price,
      'DiscountAmt': discountAmt,
      'LineTotal': lineTotal,
      'WhsCode': whsCode,
      'OcrCode': ocrCode,
      'OcrCode2': ocrCode2,
      'OcrCode3': ocrCode3,
      'OcrCode4': ocrCode4,
    };
  }
}

/// =============================================================
/// GROUPED ORDER WRAPPER MODEL (Tracks parent code via unique DocEntry)
/// =============================================================
class GroupedSaleOrder {
  final int docEntry; // Tracked via DocEntry now
  final SaleListingResult header;
  final List<SaleListingResult> items;

  GroupedSaleOrder({
    required this.docEntry,
    required this.header,
    required this.items,
  });
}

/// =============================================================
/// SALE LISTING API SERVICE
/// =============================================================
class SaleOrderApi {
  static const String baseUrl = "https://www.icckh.com/dms/dev/lhc/api/Marketing/";

  static Future<List<SaleListingResult>> fetchSaleOrders({
    required String passwordHash,
    required String fromDate,
    required String toDate,
    String status = "All",
  }) async {
    final user = SessionManager.currentUser;

    if (user == null) {
      print("❌ No user session found. Please login first.");
      return [];
    }

    final url = Uri.parse("${baseUrl}GetSaleOrderListing");

    final Map<String, dynamic> requestMap = {
      "UserCode": user.userCode,
      "Password": passwordHash,
      "DeviceID": user.deviceID,
      "FromDate": fromDate,
      "ToDate": toDate,
      "Status": status,
    };

    print("=================== API REQUEST BODY ===================");
    print(const JsonEncoder.withIndent('  ').convert(requestMap));
    print("========================================================");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestMap),
      ).timeout(const Duration(seconds: 15));

      print("📡 [Network Response Status]: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] is List) {
          final List<dynamic> rawList = result['data'];
          print("📥 [Data Loaded]: Successfully received ${rawList.length} rows from API.");
          return rawList.map((e) => SaleListingResult.fromJson(e)).toList();
        } else {
          print("⚠️ [API Warning]: Success flag false or structure invalid. Body: ${response.body}");
        }
      } else {
        print("❌ [Server Error]: HTTP status code ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("❌ Error fetching sale orders from server context: $e");
      return [];
    }
  }
}

/// =============================================================
/// MAIN APPLICATION LIST VIEW
/// =============================================================
class SaleOrderListingPage extends StatefulWidget {
  const SaleOrderListingPage({super.key});

  @override
  State<SaleOrderListingPage> createState() => _SaleOrderListingPageState();
}

class _SaleOrderListingPageState extends State<SaleOrderListingPage> {
  List<GroupedSaleOrder> allOrders = [];
  List<GroupedSaleOrder> filteredOrders = [];
  List<GroupedSaleOrder> displayedOrders = [];

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
    "All": "All Statuses",
    "D": "Draft",
    "O": "Official",
    "C": "Closed",
    "L": "Cancelled",
  };

  @override
  void initState() {
    super.initState();
    // Pre-populate date selection window dynamically to current calendar month
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, 1);
    _selectedToDate = now;

    _fetchLiveSaleOrders();
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

  /// Groups items by unique DocEntry instead of structural Code status
  List<GroupedSaleOrder> _groupFlatRows(List<SaleListingResult> flatRows) {
    final Map<int, List<SaleListingResult>> map = {};
    final Map<int, SaleListingResult> headers = {};

    for (var row in flatRows) {
      // Use DocEntry as key, fallback safely to an artificial negative index if null
      final int orderKey = row.docEntry ?? -(row.hashCode);

      if (!map.containsKey(orderKey)) {
        map[orderKey] = [];
        headers[orderKey] = row;
      }
      map[orderKey]!.add(row);
    }

    return map.entries.map((entry) {
      return GroupedSaleOrder(
        docEntry: entry.key,
        header: headers[entry.key]!,
        items: entry.value,
      );
    }).toList();
  }

  Future<void> _fetchLiveSaleOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      final flatResults = await SaleOrderApi.fetchSaleOrders(
        passwordHash: "e10adc3949ba59abbe56e057f20f883e",
        fromDate: _formatApiDate(_selectedFromDate),
        toDate: _formatApiDate(_selectedToDate),
        status: _selectedStatus,
      );

      final groupedResults = _groupFlatRows(flatResults);

      setState(() {
        allOrders = groupedResults;
        filteredOrders = groupedResults;
        currentPage = 1;
        displayedOrders = _paginate(filteredOrders);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<GroupedSaleOrder> _paginate(List<GroupedSaleOrder> items) {
    final end = (pageSize * currentPage);
    if (end >= items.length) return items;
    return items.sublist(0, end);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoadingMore) {
      _loadMoreRows();
    }
  }

  Future<void> _loadMoreRows() async {
    if (displayedOrders.length >= filteredOrders.length) return;

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));
    currentPage++;

    setState(() {
      displayedOrders = _paginate(filteredOrders);
      isLoadingMore = false;
    });
  }

  void _filter(String value) {
    searchQuery = value.toLowerCase().trim();

    final filtered = allOrders.where((order) {
      final h = order.header;
      final matchHeader = (h.cardCode ?? "").toLowerCase().contains(searchQuery) ||
          (h.cardName ?? "").toLowerCase().contains(searchQuery) ||
          (h.numAtCard ?? "").toLowerCase().contains(searchQuery);

      final matchItems = order.items.any((item) =>
      (item.itemCode ?? "").toLowerCase().contains(searchQuery) ||
          (item.dscription ?? "").toLowerCase().contains(searchQuery));

      return matchHeader || matchItems;
    }).toList();

    setState(() {
      filteredOrders = filtered;
      currentPage = 1;
      displayedOrders = _paginate(filteredOrders);
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
  /// ACCORDION DESIGN CARD COMPONENT (Shows details neatly when tapped)
  /// =============================================================
  Widget orderGroupCard(GroupedSaleOrder order) {
    final h = order.header;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Text(
            "${order.items.length}",
            style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(
          h.cardName ?? "Unknown Customer",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "DocEntry: ${h.docEntry ?? '-'} | PO/Ref: ${h.numAtCard ?? '-'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${h.docTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              h.docDate != null ? h.docDate!.toIso8601String().split('T')[0] : "-",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          const Divider(),
          _detailRow("Status/App", "${h.docStatus ?? '-'} / ${h.appStatus ?? '-'}"),
          _detailRow("Card Code", h.cardCode ?? "-"),
          _detailRow("Sub Total", "\$${h.subTotal.toStringAsFixed(2)}"),
          _detailRow("Discount", "\$${h.discSum.toStringAsFixed(2)} (${h.discPrcnt}%)"),
          if (h.comments != null && h.comments!.isNotEmpty) _detailRow("Comments", h.comments!),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Line Items", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2), fontSize: 13)),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, idx) {
              final item = order.items[idx];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item.itemCode} - ${item.dscription ?? 'No Description'}",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "Line #${item.lineNum ?? idx}",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Qty: ${item.quantity?.toStringAsFixed(2) ?? '0.00'} ${item.uomCode}", style: const TextStyle(fontSize: 12)),
                        Text("Price: \$${item.price?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontSize: 12)),
                        Text("Total: \$${item.lineTotal?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Order Listing", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLiveSaleOrders)],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
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
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedFromDate == null ? "" : _selectedFromDate!.toIso8601String().split('T')[0], style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.calendar_month, size: 18, color: Colors.blueGrey),
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
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedToDate == null ? "" : _selectedToDate!.toIso8601String().split('T')[0], style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.calendar_month, size: 18, color: Colors.blueGrey),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
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
                    ElevatedButton.icon(
                      onPressed: _fetchLiveSaleOrders,
                      icon: const Icon(Icons.search, size: 18, color: Colors.white),
                      label: const Text("Search", style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: "Search local orders or items...",
                prefixIcon: const Icon(Icons.find_in_page),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Unique Orders: ${filteredOrders.length}",
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedOrders.isEmpty
                ? const Center(child: Text("No records found", style: TextStyle(fontSize: 15)))
                : ListView.builder(
              controller: _scrollController,
              itemCount: displayedOrders.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < displayedOrders.length) {
                  return orderGroupCard(displayedOrders[index]);
                }
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}