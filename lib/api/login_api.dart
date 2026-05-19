import 'dart:convert';
import 'package:http/http.dart' as http;

class UserSession {
  final String userCode;      // Maps to CodeUser ("Dina")
  final String slpCode;       // Maps to SlpCode (1)
  final String name;          // Maps to Name ("Dina")
  final String companyName;   // Maps to CompanyName ("My Company Ltd")
  final String email;         // Maps to Email (null handled safely)
  final String profile;       // Maps to Profile ("Admin")
  final String userType;      // Maps to UserType ("Admin")
  final String manager;       // Maps to Manager ("Manager")
  final String deviceID;      // Maps to DeviceID ("AP3A.240905.015.A2")
  final String isWebUser;     // Maps to IsWebUser ("App")
  final String printerName;   // Maps to PrinterName ("HP LaserJet M404")
  final String printerMac;    // Maps to PrinterMac ("00-14-22-01-23-45")
  final String status;        // Maps to Status ("Active")

  UserSession({
    required this.userCode,
    required this.slpCode,
    required this.name,
    required this.companyName,
    required this.email,
    required this.profile,
    required this.userType,
    required this.manager,
    required this.deviceID,
    required this.isWebUser,
    required this.printerName,
    required this.printerMac,
    required this.status,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userCode: json["CodeUser"]?.toString() ?? "",
      slpCode: json["SlpCode"]?.toString() ?? "", // Handles int or String cleanly
      name: json["Name"]?.toString() ?? "",
      companyName: json["CompanyName"]?.toString() ?? "",
      email: json["Email"]?.toString() ?? "",
      profile: json["Profile"]?.toString() ?? "",
      userType: json["UserType"]?.toString() ?? "",
      manager: json["Manager"]?.toString() ?? "",
      deviceID: json["DeviceID"]?.toString() ?? "",
      isWebUser: json["IsWebUser"]?.toString() ?? "",
      printerName: json["PrinterName"]?.toString() ?? "",
      printerMac: json["PrinterMac"]?.toString() ?? "",
      status: json["Status"]?.toString() ?? "",
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
        print("➡ CODE USER: ${user.userCode}");
        print("➡ SLP CODE: ${user.slpCode}");
        print("➡ COMPANY: ${user.companyName}");

        return {
          "success": true,
          "message": result["message"] ?? "Login success",
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