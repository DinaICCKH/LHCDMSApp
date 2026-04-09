import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginApi {
  // Replace with your actual API URL or IP if testing on device
  static const String baseUrl = "http://192.168.88.254:7242/api/DMS";

  /// Login function
  /// Returns a Map containing {success, message, data}
  static Future<Map<String, dynamic>> login({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    final url = Uri.parse("$baseUrl/Login");
    final body = jsonEncode({
      "UserCode": userCode,
      "Password": password,
      "DeviceID": deviceID,
    });

    // DEBUG: Print request data
    print("Login API Request: $body");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // DEBUG: Print raw response
      print("Login API Response Code: ${response.statusCode}");
      print("Login API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // DEBUG: Print parsed response
        print("Login API Parsed Data: $data");

        return data; // {success, message, data}
      } else {
        return {
          "success": false,
          "message": "Server Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
}