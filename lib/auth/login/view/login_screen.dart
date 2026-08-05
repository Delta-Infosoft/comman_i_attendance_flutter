import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:waterman_iattandance/auth/login/view/permission_verification_screen.dart';
import 'package:waterman_iattandance/auth/login/view_model/login_controller.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:waterman_iattandance/flavor_config.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginController = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();
  bool showApproval = false;
  String appVersion = "";
  String _localDeviceId = "";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _fetchLocalDeviceId();
    loginController.ipCtrl.clear();
  }

  /// Fetches a stable unique device identifier:
  /// - Android: androidId (stable across app installs)
  /// - iOS: identifierForVendor (stable until app uninstall)
  Future<void> _fetchLocalDeviceId() async {
    try {
      final di = DeviceInfoPlugin();
      String id = '';
      if (Platform.isAndroid) {
        final info = await di.androidInfo;
        id = info.id; // Android ID — stable hardware identifier
      } else if (Platform.isIOS) {
        final info = await di.iosInfo;
        id = info.identifierForVendor ?? ''; // iOS vendor identifier
      }
      if (mounted) {
        setState(() => _localDeviceId = id);
      }
    } catch (e) {
      print('Error fetching device ID: $e');
    }
  }

  Future<void> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platformName =
          Platform.isAndroid ? "Android" : (Platform.isIOS ? "iOS" : "App");
      setState(() {
        appVersion = "$platformName Version ${info.version}";
      });
    } catch (e) {
      print("Error getting version: $e");
    }
  }

  String _cleanRawIp(String input) {
    String clean = input.trim();
    if (clean.startsWith('http://')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('https://')) {
      clean = clean.substring(8);
    }
    final slashIndex = clean.indexOf('/');
    if (slashIndex != -1) {
      clean = clean.substring(0, slashIndex);
    }
    return clean.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Logo Section ---
                Column(
                  children: [
                    SizedBox(height: 40),

                    Image.asset(
                      FlavorConfig.instance.logoAsset,
                      height: 180,
                    ),
                    // Text(
                    //   "WATERMAN",
                    //   style: TextStyle(
                    //     color: Colors.red,
                    //     fontWeight: FontWeight.w900,
                    //     fontSize: 28,
                    //     letterSpacing: 1,
                    //   ),
                    // ),
                    // Text(
                    //   "PUMPSETS",
                    //   style: TextStyle(
                    //     color: Colors.black,
                    //     fontWeight: FontWeight.w600,
                    //     fontSize: 20,
                    //     letterSpacing: 2,
                    //   ),
                    // ),
                    // SizedBox(height: 6),
                    // Text(
                    //   "iAttendance",
                    //   style: TextStyle(
                    //     color: Colors.red,
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 50),

                // --- Login Card ---
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey, // ✅ assign Form key here
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "LOGIN",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone number field
                          TextFormField(
                            controller: loginController.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().length != 10) {
                                return 'Please enter a valid 10-digit number';
                              }
                              return null; // valid input
                            },
                            decoration: InputDecoration(
                              hintText: "Mobile number",
                              prefixIcon: const Icon(Icons.phone_android),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // IP address field
                          TextFormField(
                            controller: loginController.ipCtrl,
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter IP address';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "IP address",
                              prefixIcon: const Icon(Icons.language),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                // ── IP address guard ──────────────────────
                                // final enteredIp =
                                //     loginController.ipCtrl.text.trim();
                                // Only show floating snackbar when user typed
                                // something but it's the wrong IP.
                                // Empty field is handled by the form validator.
                                // if (enteredIp.isNotEmpty &&
                                //     enteredIp != FlavorConfig.instance.serverIp) {
                                //   ScaffoldMessenger.of(context).showSnackBar(
                                //     SnackBar(
                                //       content: const Text(
                                //         '⚠️ Invalid IP address. Please enter the correct server IP',
                                //       ),
                                //       backgroundColor: Colors.red.shade700,
                                //       behavior: SnackBarBehavior.floating,
                                //       margin: const EdgeInsets.all(16),
                                //       shape: RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(10),
                                //       ),
                                //       duration: const Duration(seconds: 4),
                                //     ),
                                //   );
                                //   _formKey.currentState?.validate();
                                //   return;
                                // }
                                // ─────────────────────────────────────────

                                if (_formKey.currentState!.validate()) {
                                  try {
                                    final ip =
                                        loginController.ipCtrl.text.trim();
                                    final rawIp = _cleanRawIp(ip);
                                    final apiFolder =
                                        FlavorConfig.instance.isSingla
                                            ? "DeltaAttendanceAPI"
                                            : "DeltaAttendanceAPIWIPL";
                                    final fullBaseUrl =
                                        'http://$rawIp/$apiFolder/';
                                    ApiUrl.BASE_URL = fullBaseUrl;

                                    final response =
                                        await loginController.userValidLogin(
                                      rawIp,
                                    );

                                    final user = response.result?.first;

                                    if (user != null &&
                                        user.isApproved
                                                .toString()
                                                .toLowerCase() ==
                                            'true') {
                                      // ✅ Fetch FCM token first
                                      await loginController.fetchFCMID();

                                      // Now login with FCM ID
                                      await loginController.loginWithFcmId(
                                        rawIp,
                                      );

                                      setState(() => showApproval = false);
                                      Get.to(() =>
                                          const PermissionVerificationScreen());
                                    } else {
                                      setState(() => showApproval = true);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response.message ??
                                                'Approval pending',
                                          ),
                                          backgroundColor:
                                              Colors.orange.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('❌ Login EXCEPTION: $e');
                                    setState(() => showApproval = true);

                                    String errorMsg = "Please try again.";
                                    if (e.toString().contains("timeout")) {
                                      errorMsg =
                                          "Connection timed out. Please check your IP address and network.";
                                    } else if (e
                                        .toString()
                                        .contains("SocketException")) {
                                      errorMsg =
                                          "Network error. Server unreachable.";
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          errorMsg,
                                        ),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },

                              // onPressed: () async {
                              //   // Get.to(() => HomeScreen());
                              //   FocusScope.of(context).unfocus();
                              //
                              //   if (_formKey.currentState!.validate()) {
                              //     try {
                              //       final response =
                              //           await loginController.userValidLogin(
                              //         loginController.ipCtrl.text.trim(),
                              //       );
                              //
                              //       final resultList = response.result ?? [];
                              //
                              //       if (resultList.isNotEmpty) {
                              //         final user = resultList.first;
                              //
                              //         print(
                              //             "User isApproved TYPE: ${user.isApproved.runtimeType}");
                              //         print(
                              //             "User isApproved VALUE: ${user.isApproved}");
                              //
                              //         if (user.isApproved
                              //                 .toString()
                              //                 .toLowerCase() ==
                              //             "true") {
                              //           print("Calling loginWithFcmId.....");
                              //
                              //           await loginController.loginWithFcmId(
                              //               loginController.ipCtrl.text.trim());
                              //
                              //           setState(() => showApproval = false);
                              //
                              //           Get.to(() => HomeScreen());
                              //         } else {
                              //           setState(() => showApproval = true);
                              //         }
                              //       } else {
                              //         setState(() => showApproval = true);
                              //         Get.snackbar("Login Info",
                              //             response.message.toString());
                              //       }
                              //     } catch (e) {
                              //       print("❌ Login EXCEPTION: $e");
                              //       setState(() => showApproval = true);
                              //
                              //       Get.snackbar(
                              //         "Login Failed",
                              //         "Something went wrong. Try again.",
                              //         backgroundColor: Colors.red.shade100,
                              //         colorText: Colors.black,
                              //       );
                              //     }
                              //   }
                              // },

                              // onPressed: () async {
                              //   FocusScope.of(context).unfocus();
                              //
                              //   if (_formKey.currentState!.validate()) {
                              //     try {
                              //       final response = await loginController.userValidLogin(
                              //         loginController.ipCtrl.text.trim(),
                              //       );
                              //
                              //       final resultList = response.result ?? [];
                              //
                              //       if (resultList.isNotEmpty) {
                              //         final user = resultList.first;
                              //
                              //         print("User isApproved TYPE: ${user.isApproved.runtimeType}");
                              //         print("User isApproved VALUE: ${user.isApproved}");
                              //
                              //         if ((user.isApproved ?? "").toString().toLowerCase() == "true") {
                              //
                              //           print("Calling loginWithFcmId.....");
                              //
                              //           await loginController.loginWithFcmId(
                              //             loginController.ipCtrl.text.trim(),
                              //           );
                              //
                              //           setState(() => showApproval = false);
                              //           Get.to(() => HomeScreen());
                              //
                              //         } else {
                              //           setState(() => showApproval = true);
                              //         }
                              //       } else {
                              //         setState(() => showApproval = true);
                              //         Get.snackbar(
                              //           "Login Info",
                              //           response.message ??
                              //               "Please wait for administrator approval",
                              //         );
                              //       }
                              //
                              //     } catch (e, stack) {
                              //       print("❌ Login EXCEPTION: $e");
                              //       print("❌ STACKTRACE: $stack");
                              //
                              //       setState(() => showApproval = true);
                              //
                              //       // 👉 Show REAL error
                              //       Get.snackbar(
                              //         "Login Failed",
                              //         e.toString(),
                              //         backgroundColor: Colors.red.shade100,
                              //         colorText: Colors.black,
                              //         snackPosition: SnackPosition.BOTTOM,
                              //       );
                              //     }
                              //   }
                              // },

                              // onPressed: () async {
                              //   FocusScope.of(context).unfocus();
                              //
                              //
                              //   if (_formKey.currentState!.validate()) {
                              //     try {
                              //       final response = await loginController.userValidLogin(
                              //         loginController.ipCtrl.text.trim(),
                              //       );
                              //
                              //       final resultList = response.result ?? [];
                              //
                              //       if (resultList.isNotEmpty) {
                              //         final user = resultList.first;
                              //         print("User isApproved TYPE: ${user.isApproved.runtimeType}");
                              //         print("User isApproved VALUE: ${user.isApproved}");
                              //
                              //         if (user.isApproved?.toLowerCase() == true) {
                              //           await loginController.loginWithFcmId(
                              //               loginController.ipCtrl.text.trim());
                              //
                              //           setState(() => showApproval = false);
                              //           Get.to(HomeScreen());
                              //         } else {
                              //           setState(() => showApproval = true);
                              //         }
                              //       } else {
                              //         setState(() => showApproval = true);
                              //         Get.snackbar(
                              //           "Login Info",
                              //           response.message ?? "Please wait for administrator approval",
                              //           backgroundColor: Colors.red.shade100,
                              //           colorText: Colors.black,
                              //           snackPosition: SnackPosition.BOTTOM,
                              //         );
                              //       }
                              //     } catch (e) {
                              //       setState(() => showApproval = true);
                              //       Get.snackbar(
                              //         "Login Failed",
                              //         "Please use registered mobile number to login.",
                              //         backgroundColor: Colors.red.shade100,
                              //         colorText: Colors.black,
                              //         snackPosition: SnackPosition.BOTTOM,
                              //       );
                              //     }
                              //   } else {
                              //     // Validation failed → do nothing or show a message
                              //     print("Validation failed");
                              //   }
                              // },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlavorConfig.instance.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Obx(() => loginController.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Approval Card ---
                // Always shown when showApproval=true.
                // Uses server imeiCode if present, otherwise falls back to
                // the local device unique ID (Android ID / iOS identifierForVendor).
                if (showApproval)
                  Builder(builder: (context) {
                    // Determine the approval code to display
                    String approvalCode = '';

                    // Prefer the server-returned imeiCode
                    final user = loginController.userResponse.value;
                    final serverImei = user?.result?.isNotEmpty == true
                        ? (user!.result!.first.imeiCode ?? '')
                        : '';

                    if (serverImei.isNotEmpty) {
                      approvalCode = serverImei;
                    } else if (_localDeviceId.isNotEmpty) {
                      // Fallback to local device ID when server doesn't return one
                      approvalCode = _localDeviceId;
                    }

                    if (approvalCode.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      child: Card(
                        elevation: 2,
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Approval Pending",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Share this code with your administrator:",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              // Approval code box with copy button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.orange.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        approvalCode,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy code',
                                      icon: const Icon(Icons.copy, size: 20),
                                      color: Colors.orange.shade700,
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: approvalCode),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Approval code copied!',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),
                Text(
                  appVersion.isNotEmpty ? appVersion : "Version ...",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Design by ",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(width: 2),
                    Image.asset('assets/delta_logo.png', height: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
