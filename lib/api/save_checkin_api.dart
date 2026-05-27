import 'dart:io';
import 'package:dio/dio.dart';

class CheckInService {
  final Dio _dio = Dio();
  final String _url = "https://www.icckh.com/dms/dev/lhc/api/Marketing/AddOrUpdateCheckIn";

  Future<Map<String, dynamic>?> submitCheckIn({
    required String mode,
    required String docEntry,
    required String detailEntry,
    required String cardCode,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required double checkInLat,
    required double checkInLng,
    required double checkOutLat,
    required double checkOutLng,
    required String checkInRemark,
    required String checkOutRemark,
    required String checkStatus,
    required String appOrderEntry,
    required String dmsOrderEntry,
    required String salesCode,
    required String userSign,
    required File imageFile,
  }) async {
    print("🚀 [API START] Initiating Check-In Request...");

    try {
      FormData formData = FormData.fromMap({
        "Mode": mode,
        "DocEntry": docEntry,
        "DetailEntry": detailEntry,
        "CardCode": cardCode,
        // To this:
        "CheckInDate": checkInDate.toIso8601String().split('.').first,
        "CheckOutDate": checkOutDate.toIso8601String().split('.').first,
        "CheckInGPS": "$checkInLat,$checkInLng",
        "CheckOutGPS": (checkOutLat == 0.0 && checkOutLng == 0.0) ? "" : "$checkOutLat,$checkOutLng",
        "CheckInRemark": checkInRemark,
        "CheckOutRemark": checkOutRemark,
        "CheckStatus": checkStatus,
        "AppOrderEntry": (appOrderEntry == "null" || appOrderEntry.isEmpty) ? "" : appOrderEntry, // Fixed
        "DMSOrderEntry": (dmsOrderEntry == "null" || dmsOrderEntry.isEmpty) ? "" : dmsOrderEntry,
        "SalesCode": salesCode,
        "UserSign": userSign,
        "ImageFile": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // 🔥 [FormData Inspector] Iterating fields & files to display payload
      print("📝 --- [FormData Inspector] ---");
      for (var field in formData.fields) {
        print("   Key: ${field.key.padRight(15)} -> Value: ${field.value}");
      }
      for (var file in formData.files) {
        print("   Key: ${file.key.padRight(15)} -> File: ${file.value.filename} (${file.value.length} bytes)");
      }
      print("--------------------------------");

      print("📡 [Network] Sending POST request to: $_url");

      Response response = await _dio.post(
        _url,
        data: formData,
        options: Options(headers: {"Accept": "application/json"}),
      );

      print("🟢 [Response Received] HTTP Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ [API Success Response Body]: ${response.data}");
        return response.data;
      } else {
        print("⚠️ [API Warning] Unexpected status code received: ${response.statusCode}");
      }

    } on DioException catch (e) {
      print("❌ [DioException Caught] Call failed!");
      if (e.response != null) {
        print("   • Server Error Status: ${e.response?.statusCode}");
        print("   • Server Error Headers: ${e.response?.headers}");
        print("   • Server Error Body Data: ${e.response?.data}");
      } else {
        print("   • Request Options Path: ${e.requestOptions.path}");
        print("   • Error Config Message: ${e.message}");
        print("   • Error Type Details: ${e.type}");
      }
    } catch (e) {
      print("💥 [Unexpected Local Error]: $e");
    }

    print("🛑 [API END] Process terminated without a verified 200 success object.");
    return null;
  }
}