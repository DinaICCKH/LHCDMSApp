import 'dart:io';
import 'package:dio/dio.dart';

class CheckOutService {
  final Dio _dio = Dio();
  final String _url = "https://www.icckh.com/dms/dev/lhc/api/Marketing/AddOrUpdateCheckOut";

  Future<Map<String, dynamic>?> submitCheckOut({
    required String mode,
    required String docEntry,
    required DateTime checkOutDate,
    required double checkOutLat,
    required double checkOutLng,
    required String checkOutRemark,
    required String salesCode,
    required List<File> imageFiles,
  }) async {
    try {
      // 1. Prepare multiple files for the upload list
      List<MultipartFile> multipartImageList = [];
      for (File file in imageFiles) {
        multipartImageList.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }

      // 2. Map everything into FormData
      FormData formData = FormData.fromMap({
        "Mode": mode,
        "DocEntry": docEntry,
        "CheckOutDate": checkOutDate.toIso8601String().split('.').first,
        "CheckOutGPS": "$checkOutLat,$checkOutLng",
        "CheckOutRemark": checkOutRemark,
        "SalesCode": salesCode,
        "ImageFile": multipartImageList,
      });

      // ==================== DEBUG PRINTING BLOCK ====================
      print("============== 🛑 FORMDATA DEBUG INSPECTION ==============");
      print("🚀 UI SUCCESSFULLY CALLED submitCheckOut()!");
      print("📍 Target URL: $_url");

      for (var element in formData.fields) {
        print("🔑 Key: ${element.key.padRight(15)} ➡️ Value: ${element.value}");
      }

      for (var fileElement in formData.files) {
        final MapEntry<String, MultipartFile> fileMap = fileElement;
        print("📁 File Key: ${fileMap.key.padRight(12)} ➡️ Name: ${fileMap.value.filename} (${fileMap.value.length} bytes)");
      }
      print("==========================================================");
      // ==============================================================

      // 3. Send the request
      Response response = await _dio.post(
        _url,
        data: formData,
        options: Options(headers: {"Accept": "application/json"}),
      );

      if (response.statusCode == 200) {
        print("✅ API Response 200 Success: ${response.data}");
        return response.data;
      }
    } on DioException catch (e) {
      print("❌ Checkout API Error Status: ${e.response?.statusCode}");
      print("❌ Checkout API Error Body: ${e.response?.data ?? e.message}");
    }
    return null;
  }
}