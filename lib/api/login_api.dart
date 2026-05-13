import 'dart:convert';
import 'package:http/http.dart' as http;

class UserSession {
  final String userCode;
  final String name;
  final String companyName;
  final String email;
  final String profile;
  final String userType;
  final String manager;
  final String deviceID;

  UserSession({
    required this.userCode,
    required this.name,
    required this.companyName,
    required this.email,
    required this.profile,
    required this.userType,
    required this.manager,
    required this.deviceID,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userCode: json["CodeUser"]?.toString() ?? "",
      name: json["Name"]?.toString() ?? "",
      companyName: json["CompanyName"]?.toString() ?? "",
      email: json["Email"]?.toString() ?? "",
      profile: json["Profile"]?.toString() ?? "",
      userType: json["UserType"]?.toString() ?? "",
      manager: json["Manager"]?.toString() ?? "",
      deviceID: json["DeviceID"]?.toString() ?? "",
    );
  }
}

class SessionManager {
  static UserSession? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static void setUser(UserSession user) {
    currentUser = user;
  }

  static void clear() {
    currentUser = null;
  }
}

class LoginApi {
  static const String baseUrl =
      "https://www.icckh.com/dms/dev/lhc/api/DMS_/Login";

  static Future<Map<String, dynamic>> login({
    required String userCode,
    required String password,
    required String deviceID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "UserCode": userCode,
          "Password": password,
          "DeviceID": deviceID,
        }),
      );

      print("📡 Status: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode != 200) {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}"
        };
      }

      final result = jsonDecode(response.body);

      if (result["success"] == true && result["data"] != null) {
        final user = UserSession.fromJson(result["data"]);

        // 🔥 STORE IN MEMORY SESSION
        SessionManager.setUser(user);

        print("✅ SESSION CREATED");
        print("➡ NAME: ${user.name}");
        print("➡ COMPANY: ${user.companyName}");
        print("➡ TYPE: ${user.userType}");

        return {
          "success": true,
          "message": "Login success",
          "data": result["data"]
        };
      }

      return {
        "success": false,
        "message": result["message"] ?? "Login failed"
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Error: $e"
      };
    }
  }
}