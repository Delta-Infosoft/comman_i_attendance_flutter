import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/constant/permission_handler.dart';
import 'package:waterman_iattandance/insert_lat_ong/start_latlong.dart';
import 'package:waterman_iattandance/screens/TourVoucharApproval/view/tour_voucher_approval.dart';
import 'package:waterman_iattandance/screens/attendance_report_screen/view/attandance_report_screen.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/view_model/check_in_now_screen_controller.dart';
import 'package:waterman_iattandance/screens/my_portfolio_screen/view/my_portfolio_screen.dart';
import 'package:waterman_iattandance/screens/new_customer_dealer_screen/view/new_customer_dealer_screen.dart';
import 'package:waterman_iattandance/screens/dealer_check_in/view/dealer_check_in_screen.dart';
import 'package:waterman_iattandance/screens/tour_advance_expense/view/tour_advance_expense_screen.dart';
import 'package:waterman_iattandance/screens/tour_agenda_tracking/view/tour_agenda_tracking.dart';
import 'package:waterman_iattandance/screens/tour_voucher/view/Insert_tour_voucher_screen.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/view/project_journey_cycle.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/view/daily_tour_details_screen.dart';
import 'package:waterman_iattandance/screens/tour_voucher/view/tour_voucher_screen.dart';
import 'package:waterman_iattandance/auth/login/view/login_screen.dart';
import 'package:waterman_iattandance/screens/webviews/ierp_Kolkata_web_view.dart';
import 'package:waterman_iattandance/screens/webviews/ierp_Nagpur_web_view.dart';
import 'package:waterman_iattandance/screens/webviews/ierp_ho_web_view.dart';
import 'package:waterman_iattandance/screens/webviews/location_log_view.dart';
import 'package:waterman_iattandance/screens/webviews/wipl_PJC_web_view.dart';
import 'package:waterman_iattandance/flavor_config.dart';

import '../../../auth/login/view_model/login_controller.dart';
import '../../../constant/api_url/api_url.dart';
import '../../../service/background_location_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../daily_tour_details/viewmodel/DTD_Controller.dart';
import '../../project_journey_cycle/viewmodel/Project_journey_controller.dart';
import '../view/home_screen.dart';
import '../view_model/home_screen_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AttendanceDrawer extends StatefulWidget {
  const AttendanceDrawer({super.key});

  @override
  State<AttendanceDrawer> createState() => _AttendanceDrawerState();
}

class _AttendanceDrawerState extends State<AttendanceDrawer> {
  final LocalDbController localDbController = Get.find<LocalDbController>();
  final LoginController loginController = Get.put(LoginController());

  final HomeScreenController controller =
      Get.find<HomeScreenController>();
  final CheckInNowScreenController checkInNowScreenController =
      Get.find<CheckInNowScreenController>();

  bool get isAmrutApi =>
      ApiUrl.BASE_URL.contains("AmrutAttendanceAPI");

  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }


  Future<void> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platformName = Platform.isAndroid ? "Android App" : (Platform.isIOS ? "iOS App" : "App");
      setState(() {
        appVersion = "$platformName Version ${info.version}";
      });
    } catch (e) {
      print("Error getting version: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobileNo = LocalDbController.to.mobileNo ?? '';


    return SafeArea(
      maintainBottomViewPadding: true,
      top: false,
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Logo Section
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.asset(
                      FlavorConfig.instance.logoAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Name: ${localDbController.usersName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
      
            // Menu Items
      
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Menu Items (visibility controlled per flavor) ──────────

                  _DrawerItem(
                    icon: Icons.home,
                    text: "Home",
                    onPress: () async{
                      Navigator.pop(context);
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.PJC_CALENDAR))
                  _DrawerItem(
                    icon: Icons.calendar_month,
                    text: "Project Journey Cycle",
                    onPress: () {
                      Navigator.pop(context);
                      if (!controller.hasCheckedIn.value) {
                        ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar =
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                             behavior: SnackBarBehavior.floating,
                            showCloseIcon: true,
                            backgroundColor: FlavorConfig.instance.primaryColor,
                            content: const Text(
                                "Please check in after accessing Project Journey Cycle"),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      Get.to(() => JourneyCalendarScreen());
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.DAILY_TOUR))
                  _DrawerItem(
                    icon: Icons.today,
                    text: "Daily Tour Details",
                    onPress: () {
                      Navigator.pop(context);
                      if (!controller.hasCheckedIn.value) {
                        ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar =
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            showCloseIcon: true,
                            backgroundColor: FlavorConfig.instance.primaryColor,
                            content: const Text(
                                "Please check in after accessing Daily Tour Details"),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      Get.to(() => DailyTourDetailsScreen());
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.TOUR_VOUCHER))
                  _DrawerItem(
                    icon: Icons.receipt_long,
                    text: "Tour Voucher",
                    onPress: () {
                      Navigator.pop(context);
                      if (!controller.hasCheckedIn.value) {
                        ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar =
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            showCloseIcon: true,
                            backgroundColor: FlavorConfig.instance.primaryColor,
                            content: const Text(
                                "Please check in after accessing Tour Voucher"),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      Get.to(() => TourVoucherScreen());
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.CLIENT_CHECK_IN))
                  _DrawerItem(
                    icon: Icons.storefront_rounded,
                    text: "Client Check-In",
                    onPress: () {
                      Navigator.pop(context);
                      Get.to(() => const DealerCheckInScreen());
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.TOUR_ADVANCE_EXPENSE))
                    _DrawerItem(
                      icon: Icons.receipt_long,
                      text: "Tour Advance Expense",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => TourAdvanceExpenseScreen());
                      },
                    ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.TOUR_VOUCHER_APPROVAL))
                  _DrawerItem(
                    icon: Icons.check_circle_outline,
                    text: "Tour Voucher Approval",
                    onPress: () {
                      Navigator.pop(context);
                      Get.to(() => TourVoucherApprovalScreen(mobileNo: mobileNo));
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.NEW_CUSTOMER_DEALER))
                  _DrawerItem(
                    icon: Icons.group_add,
                    text: "New Customer/Dealer",
                    onPress: () {
                      Navigator.pop(context);
                      Get.to(() => NewCustomerDealerScreen());
                    },
                  ),

                  // _DrawerItem(
                  //   icon: Icons.account_balance_wallet_rounded,
                  //   text: "Tour Advance Expense",
                  //   onPress: () {
                  //     Navigator.pop(context);
                  //     Get.to(() => const TourAdvanceExpenseScreen());
                  //   },
                  // ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.MY_PORTFOLIO))
                  _DrawerItem(
                    icon: Icons.person,
                    text: "My Portfolio",
                    onPress: () {
                      Navigator.pop(context);
                      Get.to(() => MyPortfolioScreen());
                    },
                  ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.LOCATION_LOG))
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      text: "Location Logs",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => LocationLogWebView());
                      },
                    ),

                  if (FlavorConfig.instance.hasMenu(MenuOption.ATTENDANCE_REPORT))
                  _DrawerItem(
                    icon: Icons.assignment,
                    text: "Attendance Report",
                    onPress: () {
                      Get.to(AttendanceReportScreen());
                    },
                  ),

                  // iERP web links — Waterman only
                  if (!isAmrutApi) ...[
                    if (FlavorConfig.instance.hasMenu(MenuOption.IERP_HO))
                    _DrawerItem(
                      icon: Icons.assessment_outlined,
                      text: "iERP HO Login",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => IerpHoWebView());
                      },
                    ),
                    if (FlavorConfig.instance.hasMenu(MenuOption.IERP_NAGPUR))
                    _DrawerItem(
                      icon: Icons.assessment_outlined,
                      text: "iERP Nagpur Login",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => IerpNagpurWebView());
                      },
                    ),
                    if (FlavorConfig.instance.hasMenu(MenuOption.IERP_KOLKATA))
                    _DrawerItem(
                      icon: Icons.assessment_outlined,
                      text: "iERP Kolkata Login",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => IerpKolkataWebView());
                      },
                    ),
                    if (FlavorConfig.instance.hasMenu(MenuOption.WIPL_PJC))
                    _DrawerItem(
                      icon: Icons.assessment_outlined,
                      text: "WIPL PJC",
                      onPress: () {
                        Navigator.pop(context);
                        Get.to(() => WiplPJVWebView());
                      },
                    ),
                  ],

                  _DrawerItem(
                    icon: Icons.logout,
                    text: "Logout",
                    showDivider: false,
                    onPress: () => showLogoutDialog(context),
                  ),


                  // _DrawerItem(
                  //   icon: Icons.logout,
                  //   text: "Logout",
                  //   onPress: () {
                  //     showDialog(
                  //       context: context,
                  //       builder: (_) => AlertDialog(
                  //         title: const Text("Logout"),
                  //         content: const Text("Are you sure you want to logout?"),
                  //         actions: [
                  //           TextButton(
                  //             onPressed: () => Navigator.pop(context),
                  //             child: const Text("Cancel"),
                  //           ),
                  //           TextButton(
                  //             onPressed: () async {
                  //               await LocalDbController.to.clearUser();
                  //
                  //               Get.delete<HomeScreenController>();
                  //               Get.delete<JourneyCycleController>();
                  //               Get.delete<DTDController>();
                  //
                  //               Get.offAll(() => LoginScreen());
                  //             },
                  //             child: const Text("Logout"),
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
      
      
            // Expanded(
            //   child: ListView(
            //     padding: EdgeInsets.zero,
            //     physics: BouncingScrollPhysics(),
            //     children: [
            //       _DrawerItem(
            //         icon: Icons.home,
            //         text: "Home",
            //         onPress: () {
            //           Navigator.pop(context);
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.calendar_month,
            //         text: "Projected Journey Cycle",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => JourneyCalendarScreen());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.today,
            //         text: "Daily Tour Details",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => DailyTourDetailsScreen());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.receipt_long,
            //         text: "Tour Voucher",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => TourVoucherScreen());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.check_circle_outline,
            //         text: "Tour Voucher Approval",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => TourVoucherApprovalScreen(
            //                 mobileNo: mobileNo,
            //               ));
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.group_add,
            //         text: "New Customer/Dealer",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => NewCustomerDealerScreen());
            //         },
            //       ),
            //       // _DrawerItem(
            //       //   icon: Icons.person,
            //       //   text: "My Portfolio",
            //       //   onPress: () {},
            //       // ),
            //       _DrawerItem(
            //         icon: Icons.assignment,
            //         text: "Attendance Report",
            //         onPress: () {
            //           Get.to(AttendanceReportScreen());
            //         },
            //       ),
            //      /* _DrawerItem(
            //         icon: Icons.assessment_outlined,
            //         text: "iERP HO Login",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => IerpHoWebView());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.assessment_outlined,
            //         text: "iERP Nagpur Login",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => IerpNagpurWebView());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.assessment_outlined,
            //         text: "iERP Kolkata Login",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => IerpKolkataWebView());
            //         },
            //       ),
            //       _DrawerItem(
            //         icon: Icons.assessment_outlined,
            //         text: "WIPL PJC",
            //         onPress: () {
            //           Navigator.pop(context);
            //           Get.to(() => WiplPJVWebView());
            //         },
            //       ),*/
            //       _DrawerItem(
            //         icon: Icons.logout,
            //         text: "Logout",
            //         onPress: () {
            //           showDialog(
            //               context: context,
            //               builder: (_) => AlertDialog(
            //                     title: const Text("Logout"),
            //                     content: const Text(
            //                         "Are you sure you want to logout?"),
            //                     actions: [
            //                       TextButton(
            //                           onPressed: () {
            //                             Navigator.pop(context);
            //                           },
            //                           child: const Text("Cancel")),
            //                       TextButton(
            //                         onPressed: () async {
            //                           await LocalDbController.to.clearUser();
            //
            //                           Get.delete<HomeScreenController>();
            //                           Get.delete<JourneyCycleController>();
            //                           Get.delete<DTDController>();
            //
            //                           Get.offAll(() =>  LoginScreen());
            //                         },
            //                         child: const Text("Logout"),
            //                       )
            //
            //                       // TextButton(
            //                       //     onPressed: () {
            //                       //       LocalDbController.to.clearUser();
            //                       //       Navigator.pop(context);
            //                       //       Get.offAll(LoginScreen());
            //                       //     },
            //                       //     child: const Text("Logout")),
            //                     ],
            //                   ));
            //         },
            //         // onPressed: () {
            //         //   LocalDbController.to.clearUser();
            //         //   Navigator.pop(context);
            //         //   Get.offAll(LoginScreen());
            //         // },
            //       ),
            //     ],
            //   ),
            // ),
      
            // Footer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Design by ",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Image.asset(
                        "assets/delta_logo.png",
                        height: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                   Text(
                    "${appVersion.isNotEmpty ? appVersion : 'Loading...'}",
                    style: TextStyle(
                        color: FlavorConfig.instance.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLogoutDialog(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Logout"),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("Are you sure you want to logout?"),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);

                print("🛑 Logout: Stopping Background Service...");
                try {
                  await stopWatermanTracking();
                } catch (e) {
                  print("❌ Error stopping background service on logout: $e");
                }
                print("✅ Logout: Background Service Stop command sent.");

                await LocalDbController.to.clearUser();

                Get.delete<HomeScreenController>();
                Get.delete<JourneyCycleController>();
                Get.delete<DTDController>();

                loginController.phoneCtrl.clear();
                loginController.ipCtrl.clear();

                Get.offAll(() => LoginScreen());
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                print("🛑 Logout: Stopping Background Service...");
                try {
                  await stopWatermanTracking();
                } catch (e) {
                  print("❌ Error stopping background service on logout: $e");
                }
                print("✅ Logout: Background Service Stop command sent.");

                await LocalDbController.to.clearUser();

                Get.delete<HomeScreenController>();
                Get.delete<JourneyCycleController>();
                Get.delete<DTDController>();

                loginController.phoneCtrl.clear();
                loginController.ipCtrl.clear();

                Get.offAll(() => LoginScreen());
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }

  // void showLogoutDialog(BuildContext context) {
  //   if (Platform.isIOS) {
  //     showCupertinoDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => CupertinoAlertDialog(
  //         title: const Text("Logout"),
  //         content: const Padding(
  //           padding: EdgeInsets.only(top: 8),
  //           child: Text("Are you sure you want to logout?"),
  //         ),
  //         actions: [
  //           CupertinoDialogAction(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           CupertinoDialogAction(
  //             isDestructiveAction: true,
  //             onPressed: () async {
  //               Navigator.pop(context);
  //
  //               await LocalDbController.to.clearUser();
  //
  //
  //               print("🛑 Logout: Stopping Background Service...");
  //               FlutterBackgroundService().invoke("stop");
  //               await LocalDbController.setIsBgServiceRunning(false);
  //               print("✅ Logout: Background Service Stop command sent.");
  //
  //               Get.delete<HomeScreenController>();
  //               Get.delete<JourneyCycleController>();
  //               Get.delete<DTDController>();
  //
  //               loginController.phoneCtrl.clear();
  //               loginController.ipCtrl.clear();
  //
  //               Get.offAll(() => LoginScreen());
  //             },
  //             child: const Text("Logout"),
  //           ),
  //         ],
  //       ),
  //     );
  //   } else {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => AlertDialog(
  //         title: const Text("Logout"),
  //         content: const Text("Are you sure you want to logout?"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(context);
  //
  //               await LocalDbController.to.clearUser();
  //
  //               print("🛑 Logout: Stopping Background Service...");
  //               FlutterBackgroundService().invoke("stop");
  //               await LocalDbController.setIsBgServiceRunning(false);
  //               print("✅ Logout: Background Service Stop command sent.");
  //
  //               Get.delete<HomeScreenController>();
  //               Get.delete<JourneyCycleController>();
  //               Get.delete<DTDController>();
  //
  //               loginController.phoneCtrl.clear();
  //               loginController.ipCtrl.clear();
  //
  //               Get.offAll(() => LoginScreen());
  //             },
  //             child: const Text(
  //               "Logout",
  //               style: TextStyle(color: Colors.red),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPress;
  final bool showDivider;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.onPress,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, color: FlavorConfig.instance.primaryColor),
          title: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          onTap: () {
            onPress();
          },
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.grey.shade300,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
