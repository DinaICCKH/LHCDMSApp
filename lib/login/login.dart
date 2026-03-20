import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ NEW
import 'dart:io';
import '../api/login_api.dart';
import '../main.dart'; // DashboardPage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  String deviceNumber = "Loading...";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getDeviceID();
  }

  Future<void> _getDeviceID() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          deviceNumber = androidInfo.id;
        });
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          deviceNumber = iosInfo.identifierForVendor ?? "Unknown";
        });
      }
    } catch (e) {
      setState(() {
        deviceNumber = "Unknown";
      });
    }
  }

  void _copyDeviceNumber() {
    Clipboard.setData(ClipboardData(text: deviceNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Device number copied")),
    );
  }

  // ✅ UPDATED LOGIN FUNCTION
  void _login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("Error", "Please enter username and password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await LoginApi.login(
      userCode: username,
      password: password,
      deviceID: deviceNumber,
    );

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      final prefs = await SharedPreferences.getInstance();

      final user = result["data"];

      // ✅ SAVE SESSION FLAG
      await prefs.setBool("isLogin", true);

      // ✅ SAVE ALL USER DATA
      await prefs.setString("codeUser", user["codeUser"] ?? "");
      await prefs.setString("name", user["name"] ?? "");
      await prefs.setString("email", user["email"] ?? "");
      await prefs.setString("companyName", user["companyName"] ?? "");
      await prefs.setString("deviceID", user["deviceID"] ?? "");
      await prefs.setString("isWebUser", user["isWebUser"] ?? "");
      await prefs.setString("manager", user["manager"] ?? "");
      await prefs.setString("printerMac", user["printerMac"] ?? "");
      await prefs.setString("printerName", user["printerName"] ?? "");
      await prefs.setString("profile", user["profile"] ?? "");
      await prefs.setInt("slpCode", user["slpCode"] ?? 0);
      await prefs.setString("status", user["status"] ?? "");
      await prefs.setString("userType", user["userType"] ?? "");

      // ✅ SAVE LOGIN TIME (for session timeout later)
      await prefs.setString("loginTime", DateTime.now().toString());

      // ✅ DEBUG (optional)
      print("User saved: ${user["name"]}");

      // ✅ NAVIGATE
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      _showAlert(
        "Login Failed",
        result["message"] ?? "Incorrect username or password",
      );
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset("assets/logo.png"),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "LHC DMS",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0277BD),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Manage your sales & inventory",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),

                      const SizedBox(height: 30),

                      // Device Info
                      Row(
                        children: [
                          const Icon(Icons.phone_android, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Device: $deviceNumber",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: _copyDeviceNumber,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Username
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          hintText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: UnderlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Password
                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                          border: const UnderlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}