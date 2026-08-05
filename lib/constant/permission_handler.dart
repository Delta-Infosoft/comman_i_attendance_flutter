import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:waterman_iattandance/flavor_config.dart';

class PermissionHandler {
  static Future<void> showPermissionsBottomSheet(BuildContext context) async {
    List<PermissionItem> permissionItems = await _getPermissionItems();

    if (permissionItems.isEmpty) return;
    bool isAllAllowed = false;
    await showModalBottomSheet(
      context: context,
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return WillPopScope(
          onWillPop: () {
            return Future.value(isAllAllowed);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              maintainBottomViewPadding: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Allow us to take the following permissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...permissionItems,
                  const SizedBox(height: 20),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlavorConfig.instance.primaryColor,

                          ),
                          child: Text('GRANT PERMISSION',
                              style: GoogleFonts.montserrat(color: Colors.white)),
                          onPressed: () async {
                            await requestPermissionsSequentially(
                                context, permissionItems);
                            final permissions = await _getPermissionItems();
                            if (permissions.isEmpty || Platform.isIOS) {
                              isAllAllowed = true;
                              Get.back();
                            } else {
                              isAllAllowed = false;
                              Fluttertoast.showToast(
                                  msg:
                                  'You need to allow this permissions to use this app');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
      await openAppSettings(); // Android 13–16 → opens Unrestricted Battery page
    }
  }

  static Future<void> requestPermissionsSequentially(
      BuildContext context, List<PermissionItem> permissions) async {
    for (var item in permissions) {
      PermissionStatus? status;
      // if (item.permission == Permission.notification) {
      //   FirebaseMessaging messaging = FirebaseMessaging.instance;
      //   NotificationSettings settings = await messaging.requestPermission();
      //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //     status = PermissionStatus.granted;
      //   } else {
      //     status = PermissionStatus.permanentlyDenied;
      //   }
      // } else {

      if (item.permission == Permission.notification) {
        // NOTIFICATION PERMISSION HANDLING...
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission();
        status = settings.authorizationStatus == AuthorizationStatus.authorized
            ? PermissionStatus.granted
            : PermissionStatus.permanentlyDenied;
      }
      else if (item.permission == Permission.locationAlways) {
        // ── Location — iOS & Android two-step flow ──
        if (Platform.isIOS) {
          final whenInUseStatus = await Permission.locationWhenInUse.status;
          if (!whenInUseStatus.isGranted) {
            final result = await Permission.locationWhenInUse.request();
            if (result.isGranted) {
              await Future.delayed(const Duration(milliseconds: 1200));
              status = await Permission.locationAlways.request();
            } else {
              status = result;
            }
          } else {
            status = await Permission.locationAlways.request();
          }
        } else {
          final whenInUse = await Permission.locationWhenInUse.status;
          if (!whenInUse.isGranted) {
            await Permission.locationWhenInUse.request();
          }
          status = await Permission.locationAlways.request();
        }
      }

// 🔋 Battery Optimization Permission Handling
      else if (item.permission == Permission.ignoreBatteryOptimizations) {
        status = await Permission.ignoreBatteryOptimizations.status;

        if (!status.isGranted) {
          // request permission
          final request = await Permission.ignoreBatteryOptimizations.request();

          if (!request.isGranted) {
            // open correct settings page for Android 13–16
            await openAppSettings();
          }

          status = request;
        }
      }
      else {
        status = await item.requestPermission();
      }

      if (status!.isGranted) {
        Fluttertoast.showToast(msg: '${item.title} permission granted');
      } else if (status.isPermanentlyDenied || (Platform.isIOS && !status.isGranted)) {
        bool isGranted = false;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () {
                return Future.value(isGranted);
              },
              child: AlertDialog(
                title: Text('${item.title} Permission Required'),
                content: Text(
                  '${item.title} permission is required. Please enable it from app settings.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Check Status'),
                    onPressed: () async {
                      if (item.permission == Permission.locationAlways && Platform.isIOS) {
                        status = await Permission.locationAlways.status;
                      } else {
                        status = await item.requestPermission();
                      }
                      isGranted = status!.isGranted;
                      if (isGranted) {
                        Get.back();
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Please allow ${item.title} permission');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('Open Settings'),
                    onPressed: () async {
                      await openAppSettings();
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else if (status.isDenied) {
        Fluttertoast.showToast(msg: '${item.title} permission denied');
      }

      // Ensure one permission request finishes before another starts
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  static Future<List<PermissionItem>> _getPermissionItems() async {
    List<PermissionItem> permissionItems = [];

    // 1. Location (Universal)
    final locationStatus = await Permission.locationAlways.status;
    if (!locationStatus.isGranted) {
      permissionItems.add(
        PermissionItem(
          icon: Icons.location_on,
          title: 'Location Always',
          description: 'We request your permission to access location services Always.',
          permission: Permission.locationAlways,
        ),
      );
    }

    // 2. Camera
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
      permissionItems.add(
        PermissionItem(
          icon: Icons.camera_alt,
          title: 'Camera',
          description: 'This app requires access to your camera to capture photos.',
          permission: Permission.camera,
        ),
      );
    }

    // 3. Microphone
    // final micStatus = await Permission.microphone.status;
    // if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
    //   permissionItems.add(
    //     PermissionItem(
    //       icon: Icons.mic,
    //       title: 'Microphone',
    //       description: 'This app requires microphone access for voice features.',
    //       permission: Permission.microphone,
    //     ),
    //   );
    // }

    // 4. Photos / Gallery Access (iOS and Android 33+)
    // final photosStatus = await Permission.photos.status;
    // if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
    //   permissionItems.add(
    //     PermissionItem(
    //       icon: Icons.photo,
    //       title: 'Gallery',
    //       description: 'This app requires access to your photo library.',
    //       permission: Permission.photos,
    //     ),
    //   );
    // }

    // if (Platform.isIOS) {
    //   final photosStatus = await Permission.photos.status;
    //
    //   if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
    //     permissionItems.add(
    //       PermissionItem(
    //         icon: Icons.photo,
    //         title: 'Gallery',
    //         description: 'This app requires access to your photo library.',
    //         permission: Permission.photos,
    //       ),
    //     );
    //   }
    // }

    // if (Platform.isAndroid) {
    //   final androidInfo = await DeviceInfoPlugin().androidInfo;
    //
    //   if (androidInfo.version.sdkInt >= 33) {
    //     final photosStatus = await Permission.photos.status;
    //
    //     if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
    //       permissionItems.add(
    //         PermissionItem(
    //           icon: Icons.photo,
    //           title: 'Gallery',
    //           description: 'This app requires access to your photo library.',
    //           permission: Permission.photos,
    //         ),
    //       );
    //     }
    //   } else {
    //     final storageStatus = await Permission.storage.status;
    //
    //     if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
    //       permissionItems.add(
    //         PermissionItem(
    //           icon: Icons.photo,
    //           title: 'Gallery',
    //           description: 'This app requires access to your photo library.',
    //           permission: Permission.storage,
    //         ),
    //       );
    //     }
    //   }
    // }

    // 5. Storage (Android only for SDK <= 32)
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
          permissionItems.add(
            PermissionItem(
              icon: Icons.folder,
              title: 'File Storage',
              description: 'This app requires access to file storage.',
              permission: Permission.storage,
            ),
          );
        }
      }
    }

    // 6. Notification
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      permissionItems.add(
        PermissionItem(
          icon: Icons.notifications,
          title: 'Notifications',
          description: 'We need notification access to alert you of updates.',
          permission: Permission.notification,
        ),
      );
    }

    // 7. Battery Optimization (Android Only)
    if (Platform.isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      if (!batteryStatus.isGranted) {
        permissionItems.add(
          PermissionItem(
            icon: Icons.battery_alert,
            title: 'Battery Optimization',
            description:
            'Disable battery optimization to allow background location tracking.',
            permission: Permission.ignoreBatteryOptimizations,
          ),
        );
      }
    }


    return permissionItems;
  }

}

class PermissionItem extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? description;
  final Permission? permission;

  PermissionItem({this.icon, this.title, this.description, this.permission});

  Future<PermissionStatus>? requestPermission() {
    return permission?.request();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.redAccent.withOpacity(0.4),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    // color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}