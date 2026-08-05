import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/view/check_in_now_screeen.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/view_model/check_in_now_screen_controller.dart';
import 'package:waterman_iattandance/screens/home/widget/drawer.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';

import '../../../constant/permission_handler.dart';
import '../../../flavor_config.dart';
import '../model/follow_ups_response_model.dart';
import '../view_model/home_screen_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Added import for connectivity
import 'dart:async'; //
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final HomeScreenController controller = Get.put(HomeScreenController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CheckInNowScreenController checkOutController =
      Get.put(CheckInNowScreenController());
  var userName = ''.obs;
  bool _followUpDialogShown = false;
  String appVersion = "";

  late StreamSubscription<ConnectivityResult>
      _connectivitySubscription; // Use singular for older versions, or dynamic if unsure
  bool _isNoInternetDialogShown = false;

  // GPS monitoring
  StreamSubscription<ServiceStatus>? _gpsSubscription;
  Timer? _gpsPollingTimer;
  bool _isGpsDialogShown = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _gpsSubscription?.cancel();
    _gpsPollingTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    loadUserName();
    _checkFollowUps();
    _initConnectivity();
    _initGpsCheck();
    _getAppVersion();
    super.initState();
  }

  Future<void> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platformName = Platform.isAndroid ? "Android" : (Platform.isIOS ? "iOS" : "App");
      setState(() {
        appVersion = "$platformName Version ${info.version}";
      });
    } catch (e) {
      print("Error getting version: $e");
    }
  }

  Future<void> _checkFollowUps() async {
    if (_followUpDialogShown) return;

    try {
      final model = await controller.followUps();

      if (model.result != null && model.result!.isNotEmpty) {
        _followUpDialogShown = true;

        _showFollowUpDialog(model);
      }
    } catch (e) {
      debugPrint("FollowUp Error: $e");
    }
  }

  Future<void> _initConnectivity() async {
    // Initial check
    var result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(dynamic result) {
    // 'result' can be ConnectivityResult or List<ConnectivityResult> in newer versions
    // We handle both or assume standard setup.
    // For safety with newer packages:
    bool hasConnection = false;

    if (result is List) {
      hasConnection = result.any((r) => r != ConnectivityResult.none);
    } else {
      hasConnection = result != ConnectivityResult.none;
    }

    if (!hasConnection) {
      // Offline
      if (!_isNoInternetDialogShown) {
        _isNoInternetDialogShown = true;
        Get.bottomSheet(
          _buildNoInternetSheet(),
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: false,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ).then((_) {
          // Reset flag when closed (if closed programmatically or by code)
          _isNoInternetDialogShown = false;
        });
      }
    } else {
      // Online
      if (_isNoInternetDialogShown) {
        if (Get.isBottomSheetOpen == true) {
          Get.back(); // Close the bottom sheet
        }
        _isNoInternetDialogShown = false;
      }
    }
  }

  Widget _buildNoInternetSheet() {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button close
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please check your internet settings and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //      // Manual retry logic could go here
            //      final result = await Connectivity().checkConnectivity();
            //      _updateConnectionStatus(result);
            //   },
            //   child: const Text("Retry"),
            // )
          ],
        ),
      ),
    );
  }

  // ────────────── GPS Monitoring ──────────────

  /// Called when app goes to background / foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-check GPS every time the app comes back to the foreground
      // (covers: user closes notification shade, returns from settings, etc.)
      _checkGpsStatus();
    }
  }

  Future<void> _initGpsCheck() async {
    // 1️⃣ Immediate check on launch
    await _checkGpsStatus();

    // 2️⃣ Geolocator stream – works on some devices for instant notification
    _gpsSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) async {
        if (status == ServiceStatus.disabled) {
          await _checkGpsStatus();
        } else {
          // GPS turned back on → close dialog
          _dismissGpsDialog();
        }
      },
    );

    // 3️⃣ Polling every 3 s – reliable fallback for status-bar toggle
    _gpsPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await _checkGpsStatus();
      } else {
        _dismissGpsDialog();
      }
    });
  }

  Future<void> _checkGpsStatus() async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && !_isGpsDialogShown) {
      _isGpsDialogShown = true;
      _showGpsDisabledDialog();
    }
  }

  void _dismissGpsDialog() {
    if (_isGpsDialogShown) {
      _isGpsDialogShown = false;
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  void _showGpsDisabledDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'GPS is not Enabled!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            "You have to turn on GPS Location in order to use application.\n"
            "Please select 'High accuracy' location mode in your device.",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: const Text(
                'YES',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // When dialog is dismissed (GPS was turned on from settings),
      // re-check immediately
      _isGpsDialogShown = false;
      _checkGpsStatus();
    });
  }

  // ─────────────────────────────────────────────

  Future<void> loadUserName() async {
    userName.value = LocalDbController.to.usersName;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeScreenController>();
    final now = DateTime.now();
    final formattedDate = DateFormat("dd-MM-yyyy").format(now);
    final user = LocalDbController.to.usersName;

    return WillPopScope(
      onWillPop: () async => false,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: FlavorConfig.instance.appBarColor,
            bottom: FlavorConfig.instance.getAppBarBottom(),
            title: Text(
              FlavorConfig.instance.appName,
              style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
            ),
            leading: IconButton(
              icon: Icon(Icons.menu, color: FlavorConfig.instance.appBarForegroundColor),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Row(
                  children: [
                    // Icon(Icons.signal_cellular_alt, color: Colors.white),
                    // SizedBox(width: 5),
                    // Icon(Icons.wifi, color: Colors.white),
                    // SizedBox(width: 5),
                    // Icon(Icons.battery_full, color: Colors.white),

                  ],
                ),
              )
            ],
          ),
          drawer: AttendanceDrawer(),
          body: Platform.isIOS
              ? CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Cupertino pull-to-refresh
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await controller.fetchLastAttandances();
                        await controller.fetchCheckinStatus();
                      },
                    ),

                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          // Employee Name and Date

                          _buildSinglaEmployeeCard(user, formattedDate),

                          // Note Box
                          _buildSinglaNoteCard(),

                          // Check In Now Button
                          Obx(() {
                            final controller = Get.find<HomeScreenController>();
                            final isSingla = FlavorConfig.instance.isSingla;

                            if (isSingla) {
                              return _buildSinglaCheckInSection(controller);
                            }

                            return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    FlavorConfig.instance.buttonLightColor,
                                    FlavorConfig.instance.buttonColor,
                                  ]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: MaterialButton(
                                  elevation: 5,
                                  onPressed: controller.hasCheckedIn.value
                                      ? null
                                      : () async {
                                          await PermissionHandler
                                              .showPermissionsBottomSheet(
                                                  context);

                                          await Get.to(CheckInScreen())
                                              ?.then((_) async {
                                            await controller
                                                .fetchCheckinStatus();
                                            await controller
                                                .fetchLastAttandances();
                                          });
                                        },
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: controller.hasCheckedIn.value
                                      ? Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.person,
                                                    color: Colors.white,
                                                    size: 40),
                                                SizedBox(width: 10),
                                                Text(
                                                  "Check In",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            const Text(
                                              "Thank you for Check in : 'Have a good day!'",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "Your in time is: ${controller.checkInTime.value}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.person,
                                                color: Colors.white, size: 40),
                                            SizedBox(width: 10),
                                            Text(
                                              "Check In Now",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                ));
                          }),

                          // Keep all your commented Obx and Container code here
                          // ...

                          // Last 5 Days Record
                          _buildSinglaSectionHeader("Last 5 Days Record"),

                          // Table (iOS)
                          _buildSinglaAttendanceList(controller, userName),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchLastAttandances();
                    await controller.fetchCheckinStatus();
                  },
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Employee Name and Date
                        // SizedBox(
                        //   height: 20,
                        // ),
                        _buildSinglaEmployeeCard(user, formattedDate),

                        // Note Box
                        _buildSinglaNoteCard(),

                        // Check In Now Button

                        Obx(() {
                          final controller = Get.find<HomeScreenController>();
                          final isSingla = FlavorConfig.instance.isSingla;

                          if (isSingla) {
                            return _buildSinglaCheckInSection(controller);
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                FlavorConfig.instance.buttonLightColor,
                                FlavorConfig.instance.buttonColor,
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: MaterialButton(
                              elevation: 5,
                              onPressed: controller.hasCheckedIn.value
                                  ? null
                                  : () async {
                                      if (controller.isPermissionFlowRunning
                                          .value) return;

                                      controller.isPermissionFlowRunning.value =
                                          true;

                                      try {
                                        await PermissionHandler
                                            .showPermissionsBottomSheet(
                                                context);

                                        await Get.to(CheckInScreen())
                                            ?.then((_) async {
                                          await controller.fetchCheckinStatus();
                                          await controller
                                              .fetchLastAttandances();
                                        });
                                      } finally {
                                        controller.isPermissionFlowRunning
                                            .value = false;
                                      }
                                    },
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: controller.hasCheckedIn.value
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.person,
                                                color: Colors.white, size: 40),
                                            SizedBox(width: 10),
                                            Text(
                                              "Check In",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          "Thank you for Check in : 'Have a good day!'",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Your in time is: ${controller.checkInTime.value}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.person,
                                            color: Colors.white, size: 40),
                                        SizedBox(width: 10),
                                        Text(
                                          "Check In Now",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }),

                        // Last 5 Days Record
                        _buildSinglaSectionHeaderWithEdit(controller),

                        // Table (Android)
                        _buildSinglaAttendanceList(controller, userName)
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────── Singla Premium UI Helpers ───────────

  Widget _buildSinglaEmployeeCard(String user, String formattedDate) {
    final isSingla = FlavorConfig.instance.isSingla;
    if (!isSingla) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: FlavorConfig.instance.primaryColor,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Employee Name : $user",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Today Date : $formattedDate",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    // Singla premium card
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FlavorConfig.instance.primaryColor,
            FlavorConfig.instance.primaryLightColor,
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FlavorConfig.instance.primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Employee",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Date",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglaNoteCard() {
    final isSingla = FlavorConfig.instance.isSingla;
    if (isSingla) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.black87,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: const Text(
          "Note : PJC Fill Current Month 1 To 4 Date Inside\nAfter 4 Date Current Month PJC Not Fill Up.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSinglaSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: FlavorConfig.instance.primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglaSectionHeaderWithEdit(HomeScreenController ctrl) {
    return Padding(
      padding:  EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Last 5 Days Record",
              style: TextStyle(
                color: FlavorConfig.instance.primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if(FlavorConfig.instance.isWaterman)
          Obx(() {
            if (!ctrl.hasCheckedIn.value) return const SizedBox.shrink();
            return InkWell(
              onTap: () async {
                try {
                  Get.dialog(
                    Center(
                      child: CircularProgressIndicator(
                          color: FlavorConfig.instance.tableColor),
                    ),
                    barrierDismissible: false,
                  );
                  final attendanceResult =
                      await ctrl.getAttendanceFromId();
                  Get.back();
                  if (attendanceResult.result != null &&
                      attendanceResult.result!.isNotEmpty) {
                    final record = attendanceResult.result!.first;
                    await Get.to(() => CheckInScreen(
                          isEditMode: true,
                          preSelectedStatus: record.status,
                          attendanceId: record.autoId?.toString(),
                          preSelectedRemarks: record.remarks,
                        ))?.then((_) async {
                      await ctrl.fetchCheckinStatus();
                      await ctrl.fetchLastAttandances();
                    });
                  } else {
                    AppSnackBar.error(
                        "Error", "No attendance record found to edit.");
                  }
                } catch (e) {
                  Get.back();
                  AppSnackBar.error(
                      "Error", "Failed to fetch attendance details: $e");
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FlavorConfig.instance.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        FlavorConfig.instance.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined,
                        color: FlavorConfig.instance.primaryColor, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      "Edit",
                      style: TextStyle(
                          color: FlavorConfig.instance.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSinglaAttendanceList(
      HomeScreenController ctrl, RxString uName) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                CircularProgressIndicator(
                    color: FlavorConfig.instance.primaryColor),
                const SizedBox(height: 12),
                Text(
                  "Loading records...",
                  style: TextStyle(
                      color: FlavorConfig.instance.primaryColor
                          .withOpacity(0.7),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      if (ctrl.lastAttendances.isEmpty) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF5)),
          ),
          child: Column(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 44,
                  color:
                      FlavorConfig.instance.primaryColor.withOpacity(0.4)),
              const SizedBox(height: 10),
              Text(
                "No attendance data yet.",
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Unified table card (header + rows in one clipped container) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: FlavorConfig.instance.primaryColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                  color: FlavorConfig.instance.primaryColor.withOpacity(0.15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  color: FlavorConfig.instance.primaryColor,
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Text("Name",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text("In Time",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      SizedBox(
                        width: 54,
                        child: Text("Status",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text("Out Time",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                // Data rows — Column instead of ListView to prevent height expansion
                ...ctrl.lastAttendances.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  final statusColor = _singlaStatusColor(item.status ?? '');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index != 0)
                        Divider(
                          height: 1,
                          color: FlavorConfig.instance.primaryColor
                              .withOpacity(0.1),
                        ),
                      Container(
                        color: isEven
                            ? Colors.white
                            : FlavorConfig.instance.primaryColor
                                .withOpacity(0.03),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                uName.value,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E)),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.inTime ?? '—',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700),
                              ),
                            ),
                            SizedBox(
                              width: 54,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.status ?? '—',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.outTime ?? '—',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildSinglaCheckInSection(HomeScreenController ctrl) {
    final isCheckedIn = ctrl.hasCheckedIn.value;
    // Completed today = checked in AND checked out
    final isCompletedToday = !isCheckedIn && ctrl.checkOutTime.value.isNotEmpty;
    // Show green circle if checked in OR completed today
    final showGreen = isCheckedIn || isCompletedToday;
    final primaryColor = FlavorConfig.instance.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circle button ──────────────────────────────────────────
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: showGreen
                  ? Colors.green.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: showGreen
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : [
                            FlavorConfig.instance.primaryLightColor,
                            primaryColor,
                            const Color(0xFF0D2D6B),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (showGreen ? Colors.green : primaryColor)
                          .withOpacity(0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: (showGreen ? Colors.green : primaryColor)
                          .withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: MaterialButton(
                  elevation: 0,
                  shape: const CircleBorder(),
                  // Disabled if already checked in OR completed today
                  onPressed: (isCheckedIn || isCompletedToday)
                      ? null
                      : () async {
                          if (ctrl.isPermissionFlowRunning.value) return;
                          ctrl.isPermissionFlowRunning.value = true;
                          try {
                            await PermissionHandler
                                .showPermissionsBottomSheet(context);
                            await Get.to(CheckInScreen())?.then((_) async {
                              await ctrl.fetchCheckinStatus();
                              await ctrl.fetchLastAttandances();
                            });
                          } finally {
                            ctrl.isPermissionFlowRunning.value = false;
                          }
                        },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showGreen ? Icons.check_circle_outline : Icons.person,
                        color: Colors.white,
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showGreen ? "Checked In" : "Check In Now",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── State 2: Checked in, not yet checked out ───────────────
          if (isCheckedIn && ctrl.checkInTime.value.isNotEmpty) ...[
            const SizedBox(height: 16),
            // In-time chip
            _buildTimeChip(
              icon: Icons.login_rounded,
              label: "In at: ${ctrl.checkInTime.value}",
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            // Check Out button
            Obx(() {
              final isSubmitting = ctrl.isSubmittingCheckout.value;
              return GestureDetector(
                onTap: isSubmitting
                    ? null
                    : () => showCheckoutConfirmDialog(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSubmitting
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [Colors.red.shade400, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSubmitting
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSubmitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isSubmitting ? "Checking Out..." : "Check Out",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // ── State 3: Completed today (both in + out recorded) ──────
          if (isCompletedToday) ...[
            const SizedBox(height: 16),
            // In-time chip
            if (ctrl.checkInTime.value.isNotEmpty)
              _buildTimeChip(
                icon: Icons.login_rounded,
                label: "In at: ${ctrl.checkInTime.value}",
                color: Colors.green,
              ),
            const SizedBox(height: 8),
            // Out-time chip
            _buildTimeChip(
              icon: Icons.logout_rounded,
              label: "Out at: ${ctrl.checkOutTime.value}",
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            // Info label — attendance complete for today
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Attendance complete for today",
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small pill chip showing a time with an icon.
  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.85), size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _singlaStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'P':
        return Colors.green.shade600;
      case 'A':
        return Colors.red.shade600;
      case 'H':
        return Colors.orange.shade600;
      case 'L':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ─────────────────────────────────────────────

  void showCheckoutConfirmDialog(BuildContext context) {
    Get.dialog(
      Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoAlertDialog(
              title: const Text("Check Out"),
              content: const Text("Are you sure you want to check out?"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Cancel"),
                  onPressed: () => Get.back(),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text("Check Out"),
                  onPressed: () async {
                    Get.back();
                    await checkOutController.attandanceOutSubmit();
                    await controller.fetchCheckinStatus();
                    await controller.fetchLastAttandances();
                  },
                ),
              ],
            )
          : AlertDialog(
              title: const Text("Check Out"),
              content: const Text("Are you sure you want to check out?"),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Get.back();
                    await checkOutController.attandanceOutSubmit();
                    await controller.fetchCheckinStatus();
                    await controller.fetchLastAttandances();
                  },
                  child: const Text("Check Out"),
                ),
              ],
            ),
    );
  }

  void _showFollowUpDialog(FollowUpsResponseModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final List<List<FollowUpsResultData>> result =
            model.result ?? <List<FollowUpsResultData>>[];

        final List<FollowUpsResultData> nonEmptyList = result.firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => <FollowUpsResultData>[],
        );

        if (nonEmptyList.isEmpty) {
          return Platform.isIOS
              ? CupertinoAlertDialog(
                  title: const Text("Info"),
                  content: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("No follow-ups available"),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                )
              : AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("No follow-ups available"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlavorConfig.instance.primaryColor,
                          elevation: 3,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Close",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
        }

        final FollowUpsResultData data = nonEmptyList.first;

        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: const Text("Today's Follow Up For Order"),
                content: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      _row("Party Name", data.partyName ?? ''),
                      _row("Discussion", data.remarks ?? ''),
                    ],
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Skip-Today"),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              )
            : AlertDialog(
                scrollable: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Today's Follow Up For Order",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    _row("Party Name", data.partyName ?? ''),
                    _row("Discussion", data.remarks ?? ''),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlavorConfig.instance.primaryColor,
                              elevation: 3,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Skip-Today",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlavorConfig.instance.primaryColor,
                              elevation: 3,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "OK",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
      },
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
