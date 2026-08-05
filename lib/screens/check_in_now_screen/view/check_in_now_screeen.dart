import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/insert_lat_ong/start_latlong.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/view_model/check_in_now_screen_controller.dart';

import '../../../auth/login/view/background_service_permission_info.dart';
import '../../../constant/api_url/api_url.dart';
import '../../../constant/battery_level.dart';
import '../../../constant/permission_handler.dart';
import '../../../service/background_location_service.dart';
import '../../home/view/home_screen.dart';
import '../../home/view_model/home_screen_controller.dart';

import '../../../flavor_config.dart';

class CheckInScreen extends StatefulWidget {
  final bool isEditMode;
  final String? preSelectedStatus;
  final String? attendanceId;
  final String? preSelectedRemarks;

  const CheckInScreen({
    super.key,
    this.isEditMode = false,
    this.preSelectedStatus,
    this.attendanceId,
    this.preSelectedRemarks,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TextEditingController remarksController = TextEditingController();
  CheckInNowScreenController controller = Get.put(CheckInNowScreenController());
  HomeScreenController homeController = Get.find<HomeScreenController>();
  final TextEditingController coffDateController = TextEditingController();

  final Connectivity _connectivity = Connectivity();

  List<String> statusList = [];
  String? selectedStatus;
  bool isLoading = true;

  String _bgEmpId = "";

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.preSelectedRemarks != null) {
      remarksController.text = widget.preSelectedRemarks!;
    }
    fetchAttendanceStatus().then((_) {
      // Pre-fill status from API when in edit mode
      if (widget.isEditMode &&
          widget.preSelectedStatus != null &&
          widget.preSelectedStatus!.isNotEmpty) {
        setState(() {
          final matchingStatus = statusList.firstWhere(
            (element) =>
                element.trim().toLowerCase() ==
                    widget.preSelectedStatus!.trim().toLowerCase() ||
                controller.getStatusCode(element).trim().toLowerCase() ==
                    widget.preSelectedStatus!.trim().toLowerCase(),
            orElse: () => widget.preSelectedStatus!,
          );
          selectedStatus = matchingStatus;
        });
      }
    });
  }

  Future<void> sendBackgroundLocationApi({
    required String fullUrl,
    required String empId,
    required String lat,
    required String long,
    required String batterystatus,
    required String gpsstatus,
    required String netstatus,
    required String appversion,
    required String insertedon,
    required String modelname,
    required String androidversion,
  }) async {
    print("🚀 API: Sending to $fullUrl");
    // print("📦 Payload: EmpId=$empId, Lat=$lat, Long=$long");

    try {
      final dio = Dio();
      // Helper to truncate strings to safe length
      String safeStr(String? val, int maxLength) {
        if (val == null) return "";
        return val.length > maxLength ? val.substring(0, maxLength) : val;
      }

      // Extract digits and append % (e.g., "Charging (58%)" -> "58%")
      String cleanBattery(String val) {
        try {
          final match = RegExp(r'(\d+)').firstMatch(val);
          if (match != null) return "${match.group(1)}%";
        } catch (e) {
          print("⚠️ Error cleaning battery status: $e");
        }
        return "0%";
      }

      final formData = FormData.fromMap({
        "EmpId": empId,
        "Lat": lat,
        "Long": long,
        "BattryStatus": cleanBattery(batterystatus), // Extracts "100%"
        "GPSStatus": safeStr(gpsstatus, 50),
        "NetStatus": safeStr(netstatus, 50),
        "AppVersion": safeStr(appversion, 20),
        "InsertedOn": insertedon,
        "ModelName": safeStr(modelname, 50),
        "AndroidVersion": safeStr(androidversion, 20),
      });

      // Uncommented usage:
      print("📦 Payload first: ${formData.fields}");

      final response = await dio.post(
        fullUrl,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        print("API Success: ${response.data}");
      } else {
        print("⚠️ BAPI Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ API Error: $e");
      if (e is DioException) {
        print(
            "❌ Dio Error Info: ${e.response?.statusCode} | ${e.response?.statusMessage}");
      }
    }
  }

  Future<void> fetchAttendanceStatus() async {
    try {
      final response = await controller.attandanceStatusTextList();

      setState(() {
        // Map 'Text' field from each object in 'result'
        statusList = response.result!.map((e) => e.text.toString()).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching attendance status: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        title: Text(
          widget.isEditMode ? "Edit Attendance" : "Check In",
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
        leading: FlavorConfig.instance.getAppBarLeading(context),

        actions: [

            if (!Platform.isIOS)
              IconButton(
                  onPressed: () {
                    Get.to(BackgroundLocationInfoScreen());
                  },
                  icon: Icon(
                    Icons.warning,
                    color: Colors.amberAccent,
                    size: 25,
                  )),

          if (!Platform.isIOS)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () {
                  Get.to(() => BackgroundLocationInfoScreen());
                },
                child: Text(
                  'Action Required!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FlavorConfig.instance.appBarForegroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],

        // actions: [
        //
        //     // if(!Platform.isIOS)
        //     //   IconButton(
        //     //       onPressed: () {
        //     //         Get.to(BackgroundLocationInfoScreen());
        //     //       },
        //     //       icon: Icon(
        //     //         Icons.warning,
        //     //         color: Colors.amberAccent,
        //     //         size: 25,
        //     //       )),
        //
        //
        //     if(!Platform.isIOS)
        //       InkWell(
        //         onTap: () {
        //           Get.to(BackgroundLocationInfoScreen());
        //         },
        //         child: Text(
        //           'Action Required!',
        //           textAlign: TextAlign.center,
        //           style: TextStyle(
        //             color: Colors.white,
        //             fontSize: 13,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //   SizedBox(width: 12),
        // ],
      ),
      body: Container(
        width: double.infinity,
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage("assets/images/bg_pattern.png"),
        //     fit: BoxFit.cover,
        //   ),

        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            builder: (_) => _buildStatusBottomSheet(context),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Status",
                              border: InputBorder.none,
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            controller: TextEditingController(
                                text: selectedStatus ?? ''),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Remarks Input
                Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          hintText: "Remarks",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 10,
                ),
                Divider(),

                if (selectedStatus == "COFF-Compensatory Off" &&
                    controller.availableCoffDates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.black54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (controller.availableCoffDates.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('No COFF dates available'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                showCloseIcon: true,
                                margin: EdgeInsets.all(12),
                                duration: Duration(seconds: 2),
                              ));

                              return;
                            }

                            final dates = controller.availableCoffDates;

                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dates.first,
                              firstDate: dates.first,
                              lastDate: dates.last,
                              selectableDayPredicate: (DateTime day) {
                                return dates.any(
                                  (d) =>
                                      d.year == day.year &&
                                      d.month == day.month &&
                                      d.day == day.day,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                coffDateController.text =
                                    "${picked.day.toString().padLeft(2, '0')}-"
                                    "${picked.month.toString().padLeft(2, '0')}-"
                                    "${picked.year}";
                              });
                            }
                          },

                          // onTap: () async {
                          //   final DateTime? picked = await showDatePicker(
                          //     context: context,
                          //     initialDate: DateTime.now(),
                          //     firstDate: DateTime(2020),
                          //     lastDate: DateTime(2100),
                          //   );
                          //
                          //   if (picked != null) {
                          //     setState(() {
                          //       coffDateController.text =
                          //       "${picked.day.toString().padLeft(2, '0')}-"
                          //           "${picked.month.toString().padLeft(2, '0')}-"
                          //           "${picked.year}";
                          //     });
                          //   }
                          // },
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: coffDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: "Select Date",
                                border: InputBorder.none,
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],

                // Submit Button
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlavorConfig.instance.buttonColor,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (selectedStatus == null ||
                                selectedStatus!.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select a status before submitting.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  showCloseIcon: true,
                                  margin: EdgeInsets.all(12),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            if (selectedStatus == "COFF-Compensatory Off" &&
                                coffDateController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please Select Date"),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  showCloseIcon: true,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);

                            try {
                              final homeController =
                                  Get.find<HomeScreenController>();

                              debugPrint("Status: $selectedStatus");
                              debugPrint("Remarks: ${remarksController.text}");

                              // ──────────────── EDIT MODE ────────────────
                              if (widget.isEditMode) {
                                await controller.updateAttendanceStatus(
                                    selectedStatusText: selectedStatus ?? '',
                                    remarks: remarksController.text.trim(),
                                    coffDate: coffDateController.text);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Attendance status updated successfully!'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    showCloseIcon: true,
                                    margin: EdgeInsets.all(12),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // Refresh home data and pop back
                                await homeController.fetchLastAttandances();
                                await homeController.fetchCheckinStatus();
                                Get.back();
                                return;
                              }

                              // ──────────────── CHECK-IN MODE ────────────────
                              // 1️⃣ Main Attendance Submit (Gathers metadata internally now)
                              await controller.attandanceInOutSubmit(
                                selectedStatus ?? '',
                                remarksController.text.trim(),
                                coffDateController.text,
                              );

                              // 📱 For the second API, we need info here too
                              final Connectivity _connectivity = Connectivity();
                              Position position =
                                  await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );

                              Map<String, String> deviceInfo =
                                  await getDeviceAndStatusInfo();
                              final connectivityResult =
                                  await _connectivity.checkConnectivity();
                              final bool hasNetwork =
                                  connectivityResult != ConnectivityResult.none;

                              String _cleanBatteryStatus(dynamic status) {
                                if (status == null) return "0%";
                                String s = status.toString().toLowerCase();
                                final match =
                                    RegExp(r'\((\d+%)\)').firstMatch(s);
                                if (match != null) return match.group(1)!;
                                if (RegExp(r'^\d+%$').hasMatch(s)) return s;
                                String cleaned =
                                    s.replaceAll(RegExp(r'[^0-9%]'), '');
                                return cleaned.isEmpty
                                    ? "0%"
                                    : (cleaned.contains('%')
                                        ? cleaned
                                        : "$cleaned%");
                              }

                              final batteryStatus = _cleanBatteryStatus(
                                  deviceInfo["batterystatus"]);

                              // 2️⃣ Start Route API
                              print("----------------------------------------");
                              print("📡 TRACKING API: InsertlatLong");
                              print("----------------------------------------");

                              final battery =
                                  await NativeBattery.getBatteryStatus();

                              if (battery.isNotEmpty) {
                                await LocalDbController.setLastBattery(battery);

                                FlutterBackgroundService()
                                    .invoke("updateBattery", {
                                  "battery": battery,
                                });
                              }

                              print(
                                  "🔋 Battery status stored>>>>>>>>>>>>>>>>>: $battery");

                              await initializeBackgroundService();

                              await Future.delayed(Duration(seconds: 2));

                              FlutterBackgroundService()
                                  .invoke("updateBaseUrl", {
                                "baseUrl": ApiUrl.BASE_URL,
                              });

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final realMobile =
                                  prefs.getString("REAL_MOBILE_NO") ??
                                      LocalDbController.to.mobileNo.toString();

                              print(
                                  "📱 Real Mobile No for background: '$realMobile'");

                              FlutterBackgroundService()
                                  .invoke('updateMobileNo', {
                                'mobileNo': realMobile,
                              });

                              await startMyTimeBackgroundService();
                              debugPrint(
                                  "🚀 Background service started → IsShowLatLong=true");

                              // REFRESH HomeScreen data
                              await homeController.fetchLastAttandances();
                              await homeController.fetchCheckinStatus();

                              // Pop back to HomeScreen
                              Get.back();
                            } catch (e) {
                              debugPrint('Submit error: $e');
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Submission failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  showCloseIcon: true,
                                ),
                              );
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },

                    // onPressed: isLoading
                    //     ? null
                    //     : () async {
                    //   if (selectedStatus == null || selectedStatus!.isEmpty) {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text('Please select a status before submitting.'),
                    //         backgroundColor: Colors.redAccent,
                    //         behavior: SnackBarBehavior.floating,
                    //         margin: EdgeInsets.all(12),
                    //         duration: Duration(seconds: 2),
                    //       ),
                    //     );
                    //     return;
                    //   }
                    //
                    //   setState(() => isLoading = true);
                    //
                    //   try {
                    //     debugPrint("Status: $selectedStatus");
                    //     debugPrint("Remarks: ${remarksController.text}");
                    //
                    //     await controller.attandanceInOutSubmit(
                    //       selectedStatus ?? '',
                    //       remarksController.text.trim(),
                    //     );
                    //
                    //     await homeController.fetchLastAttandances();
                    //
                    //     Get.offAll(() => const HomeScreen());
                    //
                    //
                    //     // await controller.attandanceInOutSubmit(
                    //     //   selectedStatus ?? '',
                    //     //   remarksController.text.trim(),
                    //     // );
                    //     //
                    //     // Get.offAll(() => const HomeScreen());
                    //   } catch (e) {
                    //     debugPrint('Submit error: $e');
                    //
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(
                    //         content: Text('Submission failed: $e'),
                    //         backgroundColor: Colors.redAccent,
                    //       ),
                    //     );
                    //   } finally {
                    //     setState(() => isLoading = false);
                    //   }
                    // },

                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "SUBMIT",
                            style: TextStyle(
                              color: Colors.white,
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
    );
  }

  Widget _buildStatusBottomSheet(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statusList.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final status = statusList[index];
                  return ListTile(
                    title: Text(status),
                    onTap: () async {
                      setState(() {
                        selectedStatus = status;
                      });

                      if (status.contains("COFF-Compensatory Off")) {
                        await controller.getEMPCOFFDate(context);
                      }

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startMyTimeBackgroundService() async {
    debugPrint("🚀 CheckInScreen: Attempting to start background service...");
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      debugPrint("🚀 CheckInScreen: Service running status: $isRunning");
      if (!isRunning) {
        debugPrint("🚀 CheckInScreen: Calling service.startService()...");
        await service.startService();
        debugPrint("🚀 CheckInScreen: service.startService() returned.");
      } else {
        debugPrint("🚀 CheckInScreen: Service already running.");
      }
    } catch (e) {
      debugPrint("❌ CheckInScreen: Error starting service: $e");
    }
  }

  Future<void> stopMyTimeBackgroundService() async {
    try {
      final service = FlutterBackgroundService();

      service.invoke("stop");

      await LocalDbController.setIsBgServiceRunning(false);
      // await LocalDB.setHasCheckedOut(true); // Not found in LocalDbController
      await LocalDbController.setIsLoggedIn(false);

      debugPrint("🛑 Background service stopped + flags reset");
    } catch (e) {
      debugPrint("❌ Error stopping background service: $e");
    }
  }
}
