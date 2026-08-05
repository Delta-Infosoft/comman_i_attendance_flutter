import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';

import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import '../constant/api_url/api_url.dart';
import '../flavor_config.dart';

// // ================= CONFIG =================
// const Duration _kInterval = Duration(minutes: 5);
// const Duration _kLocTimeout = Duration(seconds: 20);
// const int _kGuardMs = 1 * 60 * 1000;
//
// bool _isServiceStarted = false;
// int _lastSentMs = 0;
// String _lastBatteryInfo = "";
// String _bgMobileNo = "";
//
// // ================= OFFLINE QUEUE =================
// class OfflineQueue {
//   static const String key = "offline_locations";
//
//   static Future<void> add(Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = prefs.getStringList(key) ?? [];
//
//     if (list.length > 500) list.removeAt(0);
//
//     list.add(jsonEncode(data));
//     await prefs.setStringList(key, list);
//
//     print("📦 Saved offline. Count: ${list.length} | Time: ${data['time']}");
//   }
//
//   static Future<List<dynamic>> getAll() async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = prefs.getStringList(key) ?? [];
//     return list.map((e) => jsonDecode(e)).toList();
//   }
//
//   static Future<void> removeAt(int index) async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = prefs.getStringList(key) ?? [];
//     if (index >= 0 && index < list.length) {
//       list.removeAt(index);
//       await prefs.setStringList(key, list);
//     }
//   }
// }
//
// // ================= SYNC =================
// Future<void> syncOfflineLocations(String baseUrl) async {
//   final list = await OfflineQueue.getAll();
//
//   if (list.isEmpty) return;
//
//   print("🔄 Syncing ${list.length} records...");
//
//   // 👉 IMPORTANT: Clear queue first to avoid duplication issue
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.remove(OfflineQueue.key);
//
//   for (final item in list) {
//     try {
//       final storedTime = item['time'] ?? "";
//
//       print("📤 Sending time >>>>>>>>>>: $storedTime");
//
//       await sendBackgroundLocationApi(
//         fullUrl: ApiUrl.InsertlatLong,
//         mobileNo: item['mobileNo'] ?? '',
//         lat: item['lat'] ?? '',
//         long: item['long'] ?? '',
//         batterystatus: item['battery'] ?? '',
//         gpsstatus: item['gps'] ?? '',
//         netstatus: item['net'] ?? "false",
//         appversion: item['appversion'] ?? '',
//         modelname: item['modelname'] ?? '',
//         androidversion: item['androidversion'] ?? '',
//         insertedon: storedTime,
//       );
//
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       print("✅ Synced 1");
//
//     } catch (e) {
//       print("❌ Sync failed → saving remaining back");
//
//       // 👉 Put remaining items back
//       final remaining = list.sublist(list.indexOf(item));
//       for (final r in remaining) {
//         await OfflineQueue.add(Map<String, dynamic>.from(r));
//       }
//
//       break;
//     }
//   }
// }
//
// // ================= START SERVICE =================
// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();
//
//   if (await service.isRunning()) {
//     print("⚠️ Service already running");
//     return;
//   }
//
//   if (Platform.isAndroid) {
//     const AndroidNotificationChannel backgroundChannel =
//         AndroidNotificationChannel(
//       "waterman_bg_service",
//       "Waterman Background Service",
//       description: "Used for background location tracking",
//       importance: Importance.low,
//     );
//
//     final plugin = FlutterLocalNotificationsPlugin();
//     await plugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(backgroundChannel);
//   }
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'waterman_bg_service',
//       initialNotificationTitle: 'Waterman Service',
//       initialNotificationContent: 'Ready to track location',
//       foregroundServiceNotificationId: 999,
//       foregroundServiceTypes: [
//         AndroidForegroundType.location,
//         AndroidForegroundType.dataSync,
//       ],
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }
//
// @pragma('vm:entry-point')
// bool onIosBackground(ServiceInstance service) {
//   WidgetsFlutterBinding.ensureInitialized();
//   print("iOS background fetch executed");
//   return true;
// }
//
// // ================= STOP =================
// Future<void> stopBackgroundService() async {
//   final service = FlutterBackgroundService();
//   service.invoke("stop");
// }
//
// // ================= MAIN ENTRY =================
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//
//   if (_isServiceStarted) {
//     print("⚠️ Already started → skipping");
//     return;
//   }
//   _isServiceStarted = true;
//
//   print("🚀 BG Service Started");
//
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//     service.setForegroundNotificationInfo(
//       title: "Waterman Service Running",
//       content: "Initializing background tracking...",
//     );
//   }
//
//   await LocalDbController.init();
//   await SharedPreferences.getInstance();
//   await GetStorage.init();
//
//   final String baseUrl = LocalDbController.getBaseApiUrl() ?? "";
//   if (baseUrl.isNotEmpty) {
//     ApiUrl.BASE_URL = baseUrl.endsWith('/') ? baseUrl : "$baseUrl/";
//   }
//
//   service.on('updateBaseUrl').listen((event) {
//     final newUrl = event?['baseUrl'] ?? "";
//     if (newUrl.isNotEmpty) {
//       ApiUrl.BASE_URL = newUrl.endsWith('/') ? newUrl : "$newUrl/";
//     }
//   });
//
//   service.on('updateBattery').listen((event) async {
//     final battery = event?['battery'] ?? '';
//     if (battery.isNotEmpty) {
//       _lastBatteryInfo = battery;
//       await LocalDbController.setLastBattery(battery);
//     }
//   });
//
//   service.on('updateMobileNo').listen((event) {
//     _bgMobileNo = event?['mobileNo'] ?? "";
//   });
//
//   service.on('stop').listen((event) {
//     service.stopSelf();
//   });
//
//   Connectivity().onConnectivityChanged.listen((result) async {
//     final bool hasNetwork = result != ConnectivityResult.none;
//
//     if (hasNetwork) {
//       print("🌐 Network restored → syncing offline data");
//       await syncOfflineLocations(ApiUrl.BASE_URL);
//     } else {
//       print("📡 Network lost → will queue data");
//     }
//   });
//
//   while (true) {
//     try {
//       final now = DateTime.now();
//       if (now.hour == 23 && now.minute >= 59) {
//         print("🛑 BG: Auto-stopping service at 11:59 PM");
//         service.stopSelf();
//         break;
//       }
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.reload();
//
//       String mobileNo = prefs.getString("REAL_MOBILE_NO") ?? prefs.getString("BG_MOBILE_NO") ?? _bgMobileNo;
//       if (mobileNo.isEmpty || mobileNo.contains('-')) {
//         final gs = GetStorage();
//         final possibleValues = [
//           gs.read('MobileNo')?.toString(),
//           gs.read('EmpID')?.toString(),
//           gs.read('UsersName')?.toString(),
//           gs.read('AutoId')?.toString(),
//         ];
//         for(final val in possibleValues) {
//           if (val != null && val.isNotEmpty && !val.contains('-')) {
//              mobileNo = val;
//              break;
//           }
//         }
//       }
//
//       if (ApiUrl.BASE_URL.isNotEmpty && mobileNo.isNotEmpty) {
//         await _runTick(ApiUrl.BASE_URL, mobileNo);
//       } else {
//         print("⚠️ Waiting for BaseUrl and MobileNo...");
//       }
//     } catch (e) {
//       print("❌ Loop error: $e");
//     }
//     await Future.delayed(_kInterval);
//   }
// }
//
// // ================= TICK =================
// Future<void> _runTick(String baseUrl, String mobileNo) async {
//   try {
//     final nowMs = DateTime.now().millisecondsSinceEpoch;
//
//     if (nowMs - _lastSentMs < _kGuardMs) {
//       print("⏱ Skipping duplicate tick");
//       return;
//     }
//     _lastSentMs = nowMs;
//
//     var permission = await Geolocator.checkPermission();
//
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       print("❌ Permission denied");
//       return;
//     }
//
//     final isGpsOn = await Geolocator.isLocationServiceEnabled();
//
//     Position? pos;
//
//     if (isGpsOn) {
//       pos = await _getPosition();
//     } else {
//       print("⚠️ GPS OFF → will send 0,0");
//     }
//
//     await _sendLocation(pos, mobileNo, baseUrl);
//     await syncOfflineLocations(baseUrl);
//
//   } catch (e) {
//     print("❌ Tick error: $e");
//   }
// }
//
// // ================= GET POSITION =================
// Future<Position?> _getPosition() async {
//   try {
//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//       timeLimit: _kLocTimeout,
//     );
//   } catch (_) {
//     return await Geolocator.getLastKnownPosition();
//   }
// }
//
// // ================= SEND =================
// Future<void> _sendLocation(
//     Position? pos,
//     String mobileNo,
//     String baseUrl,
//     ) async {
//
//   final now = DateTime.now();
//
//   final connectivity = await Connectivity().checkConnectivity();
//   final bool hasNetwork = connectivity != ConnectivityResult.none;
//
//   final isGpsOn = await Geolocator.isLocationServiceEnabled();
//
//   final info = await getDeviceAndStatusInfo();
//
//   String lat = "0";
//   String long = "0";
//
//   if (isGpsOn && pos != null) {
//     lat = pos.latitude.toString();
//     long = pos.longitude.toString();
//   }
//
//   final timestamp = DateFormat("dd-MMM-yyyy hh:mm a").format(now);
//
//   if (!hasNetwork) {
//     await OfflineQueue.add({
//       "mobileNo": mobileNo,
//       "lat": lat,
//       "long": long,
//       "battery": _cleanBattery(info['batterystatus']),
//       "gps": isGpsOn ? "true" : "false",
//       "net": "false",
//       "time": timestamp,
//       "appversion": info['appversion'],
//       "modelname": info['modelname'],
//       "androidversion": info['androidversion'],
//     });
//     return;
//   }
//
//   try {
//     await sendBackgroundLocationApi(
//       fullUrl: ApiUrl.InsertlatLong,
//       mobileNo: mobileNo,
//       lat: lat,
//       long: long,
//       batterystatus: _cleanBattery(info['batterystatus']),
//       gpsstatus: isGpsOn ? "true" : "false",
//       netstatus: hasNetwork ? "true" : "false",
//       appversion: info['appversion'] ?? '',
//       modelname: info['modelname'] ?? '',
//       androidversion: info['androidversion'] ?? '',
//       insertedon: timestamp,
//     );
//
//     print("✅ SENT SUCCESS → GPS:${isGpsOn} LAT:$lat");
//
//   } catch (e) {
//     print("❌ API failed → saved offline");
//
//     await OfflineQueue.add({
//       "mobileNo": mobileNo,
//       "lat": lat,
//       "long": long,
//       "battery": info['batterystatus'],
//       "gps": isGpsOn ? "true" : "false",
//       "net": "false",
//       "time": timestamp,
//       "appversion": info['appversion'],
//       "modelname": info['modelname'],
//       "androidversion": info['androidversion'],
//     });
//   }
// }
//
// // ================= API CALL =================
// Future<void> sendBackgroundLocationApi({
//   required String fullUrl,
//   required String mobileNo,
//   required String lat,
//   required String long,
//   required String batterystatus,
//   required String gpsstatus,
//   required String netstatus,
//   required String appversion,
//   required String insertedon,
//   required String modelname,
//   required String androidversion,
// }) async {
//   print("🚀 BG-API: Sending to $fullUrl");
//   print("📱 MobileNo: $mobileNo | Lat: $lat | Long: $long | Battery: $batterystatus | GPS: $gpsstatus | Net: $netstatus | AppVer: $appversion | Model: $modelname | AndroidVer: $androidversion | Time: $insertedon");
//
//   try {
//     final dio = Dio();
//     String safeStr(String? val, int maxLength) {
//       if (val == null) return "";
//       return val.length > maxLength ? val.substring(0, maxLength) : val;
//     }
//
//     final formData = FormData.fromMap({
//       "MobileNo": mobileNo,
//       "Lat": lat,
//       "Long": long,
//       "BattryStatus": batterystatus, // Already cleaned by _cleanBattery
//       "GPSStatus": safeStr(gpsstatus, 50),
//       "NetStatus": safeStr(netstatus, 50),
//       "AppVersion": safeStr(appversion, 20),
//       "InsertedOn": insertedon,
//       "ModelName": safeStr(modelname, 50),
//       "AndroidVersion": safeStr(androidversion, 20),
//     });
//
//     print('====================================================');
//     print('🚀 REQUEST PARAMETERS FOR InsertlatLong API:');
//     print('====================================================');
//     for (var field in formData.fields) {
//       print('   ${field.key}: ${field.value}');
//     }
//     print('====================================================');
//
//     final response = await dio.post(
//       fullUrl,
//       data: formData,
//     );
//
//     if (response.statusCode == 200) {
//       print("✅ BG-API Success: ${response.data}");
//     } else {
//       print("⚠️ BG-API Failed with status: ${response.statusCode}");
//       throw Exception("API Failed: ${response.statusCode}");
//     }
//   } catch (e) {
//     print("❌ BG-API Error: $e");
//     if (e is DioException) {
//       print("❌ Dio Error Info: ${e.response?.statusCode} | ${e.response?.statusMessage}");
//     }
//     rethrow;
//   }
// }
//
// // ================= HELPERS =================
// String _cleanBattery(String? status) {
//   if (status == null) return "0%";
//   final match = RegExp(r'\((\d+%)\)').firstMatch(status);
//   if (match != null) return match.group(1)!;
//   return status.replaceAll(RegExp(r'[^0-9%]'), '');
// }
//
// // ================= DEVICE INFO =================
// Future<Map<String, String>> getDeviceAndStatusInfo() async {
//   String battery = "";
//
//   try {
//     final batteryPlugin = Battery();
//     final level = await batteryPlugin.batteryLevel;
//     final state = await batteryPlugin.batteryState;
//
//     String stateStr = "unknown";
//     switch (state) {
//       case BatteryState.charging:
//         stateStr = "charging";
//         break;
//       case BatteryState.discharging:
//         stateStr = "discharging";
//         break;
//       case BatteryState.full:
//         stateStr = "full";
//         break;
//       case BatteryState.unknown:
//         stateStr = "unknown";
//         break;
//       case BatteryState.connectedNotCharging:
//         stateStr = "not_charging";
//         break;
//     }
//
//     battery = "$stateStr ($level%)";
//   } catch (e) {
//     print("❌ Error fetching battery from plugin: $e");
//   }
//
//   if (battery.isEmpty) {
//     battery = _lastBatteryInfo;
//   }
//
//   if (battery.isEmpty) {
//     battery = await LocalDbController.getLastBattery() ?? "";
//   }
//
//   final di = DeviceInfoPlugin();
//
//   String model = '';
//   String os = '';
//
//   try {
//     if (Platform.isAndroid) {
//       final a = await di.androidInfo;
//       model = a.model ?? '';
//       os = a.version.release;
//     } else if (Platform.isIOS) {
//       final ios = await di.iosInfo;
//       model = ios.utsname.machine;
//       os = ios.systemVersion;
//     }
//   } catch (e) {}
//
//   String appVer = "";
//   try {
//     appVer = (await PackageInfo.fromPlatform()).version;
//   } catch (e) {}
//
//   return {
//     'batterystatus': battery,
//     'modelname': model,
//     'androidversion': os,
//     'appversion': appVer,
//   };
// }


// =====================================================================
// waterman_background_service.dart
//
// Same reliability model as the "MyTime" background service:
//   - WorkManager + AndroidAlarmManager watchdog that detects a killed
//     service and restarts it.
//   - A persisted "should be running" flag so the watchdog knows
//     whether it's supposed to bring the service back after a reboot
//     or an app kill.
//   - Calendar-day based auto-stop (robust vs. the old
//     `hour==23 && minute>=59` check, which can be skipped over if the
//     tick interval jumps past that window).
//
// Everything Waterman-specific is kept as-is:
//   - ApiUrl.BASE_URL / ApiUrl.InsertlatLong
//   - LocalDbController for base url + last battery caching
//   - GetStorage fallback chain for resolving the mobile number
//   - sendBackgroundLocationApi() using Dio + FormData
//
// REQUIRED DEPENDENCIES (pubspec.yaml) — same as MyTime:
//   flutter_background_service
//   flutter_local_notifications
//   workmanager
//   android_alarm_manager_plus
//   wakelock_plus
//   permission_handler
//   connectivity_plus
//   geolocator
//   battery_plus
//   device_info_plus
//   package_info_plus
//   dio
//   intl
//   shared_preferences
//   get_storage
// =====================================================================

import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// ================= CONSTANTS =================
const Duration _kInterval = Duration(minutes: 5);      // location tick
const Duration _kLocTimeout = Duration(seconds: 20);
const int _kGuardMs = 1 * 60 * 1000;                    // 1 min duplicate guard

const Duration _kWmInterval = Duration(minutes: 15);    // watchdog check interval
const int _kAlarmId = 77;
const String _kWmTaskName = 'waterman_service_watchdog';
const String _kWmTaskUnique = 'waterman_watchdog_unique';

// persisted "should be running" flag key (survives app kill/reboot)
const String _kFlagShouldRun = 'WM_BG_SERVICE_SHOULD_RUN';

bool _isServiceStarted = false;
int _lastSentMs = 0;
String _lastBatteryInfo = "";
String _bgMobileNo = "";
late FlutterLocalNotificationsPlugin _notificationPlugin;

// ================= OFFLINE QUEUE =================
class OfflineQueue {
  static const String key = "offline_locations";

  static Future<void> add(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    if (list.length > 500) list.removeAt(0);

    list.add(jsonEncode(data));
    await prefs.setStringList(key, list);

    print("📦 Saved offline. Count: ${list.length} | Time: ${data['time']}");
  }

  static Future<List<dynamic>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    return list.map((e) => jsonDecode(e)).toList();
  }

  static Future<void> removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(key, list);
    }
  }
}

// ================= SYNC =================
Future<void> syncOfflineLocations(String baseUrl) async {
  final list = await OfflineQueue.getAll();

  if (list.isEmpty) return;

  print("🔄 Syncing ${list.length} records...");

  // 👉 IMPORTANT: Clear queue first to avoid duplication issue
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(OfflineQueue.key);

  for (final item in list) {
    try {
      final storedTime = item['time'] ?? "";

      print("📤 Sending time >>>>>>>>>>: $storedTime");

      await sendBackgroundLocationApi(
        fullUrl: ApiUrl.InsertlatLong,
        mobileNo: item['mobileNo'] ?? '',
        lat: item['lat'] ?? '',
        long: item['long'] ?? '',
        batterystatus: item['battery'] ?? '',
        gpsstatus: item['gps'] ?? '',
        netstatus: item['net'] ?? "false",
        appversion: item['appversion'] ?? '',
        modelname: item['modelname'] ?? '',
        androidversion: item['androidversion'] ?? '',
        insertedon: storedTime,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      print("✅ Synced 1");
    } catch (e) {
      print("❌ Sync failed → saving remaining back");

      // 👉 Put remaining items back
      final remaining = list.sublist(list.indexOf(item));
      for (final r in remaining) {
        await OfflineQueue.add(Map<String, dynamic>.from(r));
      }

      break;
    }
  }
}

// ================= PUBLIC API =================

/// Call this wherever you previously relied on autoStart:true — e.g. after
/// login, or from a "start tracking" button. Starts the service AND arms
/// the watchdog so Android/OEM battery-killers can't silently end tracking.
Future<void> startWatermanTracking() async {
  await initializeBackgroundService();
  await _setShouldRun(true);
  await _armWatchdogs();
  print("✅ [Waterman] Service started + watchdogs armed");
}

/// Call this wherever you previously called stopBackgroundService().
/// Stops the service AND disarms the watchdog so it doesn't resurrect it.
Future<void> stopWatermanTracking() async {
  await stopBackgroundService();
  await _setShouldRun(false);
  await _disarmWatchdogs();
  print("✅ [Waterman] Service stopped + watchdogs disarmed");
}

/// Call this in main(), after your local DB / SharedPreferences init.
/// If tracking was active before the app got killed or the device
/// rebooted, this re-arms the watchdog so it can bring the service back.
Future<void> rearmWatchdogsIfNeeded() async {
  final shouldRun = await _getShouldRun();
  if (!shouldRun) return;

  await _armWatchdogs();
  print("✅ [Waterman] Watchdogs re-armed after app restart");
}

Future<void> _setShouldRun(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kFlagShouldRun, value);
}

Future<bool> _getShouldRun() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kFlagShouldRun) ?? false;
}

// ================= START SERVICE =================
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  if (await service.isRunning()) {
    print("⚠️ Service already running");
    return;
  }

  final appTitle = FlavorConfig.isInitialized ? FlavorConfig.instance.appTitle : 'Singla';
  final channelId = FlavorConfig.isInitialized ? '${FlavorConfig.instance.flavor.name}_bg_service' : 'singla_bg_service';

  if (Platform.isAndroid) {
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      print("⚠️ [BG] Notification permission not granted");
      // Still proceed to configure; startService below may fail silently
      // on some OEMs without notification permission, so surface this
      // to the caller if you want to prompt the user explicitly.
    }

    final AndroidNotificationChannel backgroundChannel =
    AndroidNotificationChannel(
      channelId,
      "$appTitle Background Service",
      description: "Used for background location tracking",
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    _notificationPlugin = FlutterLocalNotificationsPlugin();
    await _notificationPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backgroundChannel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      // autoStart is now false — the watchdog + startWatermanTracking()
      // are responsible for (re)starting it deliberately.
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: channelId,
      initialNotificationTitle: '$appTitle Service',
      initialNotificationContent: 'Ready to track location',
      foregroundServiceNotificationId: 999,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
  print("✅ [BG] Background service started");
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print("iOS background fetch executed");
  return true;
}

// ================= STOP =================
Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

// ================= WATCHDOG (WorkManager + AlarmManager) =================

Future<void> _armWatchdogs() async {
  await _registerWorkManager();
  if (Platform.isAndroid) {
    await _registerAlarmManager();
  }
}

Future<void> _disarmWatchdogs() async {
  try {
    await Workmanager().cancelByUniqueName(_kWmTaskUnique);
  } catch (e) {
    print('⚠️ [WM] Cancel failed: $e');
  }

  if (Platform.isAndroid) {
    try {
      await AndroidAlarmManager.cancel(_kAlarmId);
    } catch (e) {
      print('⚠️ [Alarm] Cancel failed: $e');
    }
  }
}

Future<void> _registerWorkManager() async {
  await Workmanager().initialize(
    _wmCallbackDispatcher,
    isInDebugMode: false,
  );

  if (Platform.isAndroid) {
    await Workmanager().registerPeriodicTask(
      _kWmTaskUnique,
      _kWmTaskName,
      frequency: _kWmInterval,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
      tag: _kWmTaskUnique,
    );
  }

  if (Platform.isIOS) {
    await Workmanager().registerOneOffTask(
      _kWmTaskUnique,
      _kWmTaskName,
      initialDelay: _kWmInterval,
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}

Future<void> _registerAlarmManager() async {
  await AndroidAlarmManager.initialize();
  await AndroidAlarmManager.periodic(
    _kWmInterval,
    _kAlarmId,
    _alarmCallback,
    wakeup: true,
    rescheduleOnReboot: true,
    exact: false,
    allowWhileIdle: true,
  );
}

@pragma('vm:entry-point')
void _wmCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _kWmTaskName) return true;
    await _watchdogTick(source: 'WorkManager');
    if (Platform.isIOS) {
      await Workmanager().registerOneOffTask(
        _kWmTaskUnique,
        _kWmTaskName,
        initialDelay: _kWmInterval,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
    return true;
  });
}

@pragma('vm:entry-point')
Future<void> _alarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _watchdogTick(source: 'AlarmManager');
}

/// Runs on a schedule independent of the foreground service. If tracking
/// is supposed to be active but the service has died (OEM battery killer,
/// crash, etc.), this restarts it.
Future<void> _watchdogTick({required String source}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
  } catch (e) {
    print('⚠️ [$source] Failed to reload SharedPreferences: $e');
  }

  final shouldRun = await _getShouldRun();
  if (!shouldRun) return;

  final baseUrl = LocalDbController.getBaseApiUrl() ?? "";
  final mobileNo = _resolveMobileNo();
  if (baseUrl.isEmpty || mobileNo.isEmpty) {
    print('⚠️ [$source] Missing baseUrl/mobileNo → skipping restart');
    return;
  }

  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (!isRunning) {
      print('🚨 [$source] Service dead → restarting');
      await initializeBackgroundService();
    }
  } catch (e) {
    print('❌ [$source] Watchdog restart failed: $e');
  }
}

// ================= MAIN ENTRY (SERVICE ISOLATE) =================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (_isServiceStarted) {
    print("⚠️ Already started → skipping");
    return;
  }
  _isServiceStarted = true;

  print("🚀 BG Service Started");

  await LocalDbController.init();
  final prefs = await SharedPreferences.getInstance();
  await GetStorage.init();

  final savedFlavorStr = prefs.getString('APP_FLAVOR');
  if (savedFlavorStr == 'singla') {
    FlavorConfig.initialize(AppFlavor.singla);
  } else if (savedFlavorStr == 'waterman') {
    FlavorConfig.initialize(AppFlavor.waterman);
  } else if (!FlavorConfig.isInitialized) {
    FlavorConfig.initialize(AppFlavor.singla);
  }
  final appTitle = FlavorConfig.instance.appTitle;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "$appTitle Service Running",
      content: "Initializing background tracking...",
    );
  }

  String baseUrl = LocalDbController.getBaseApiUrl() ?? "";
  if (FlavorConfig.isInitialized && FlavorConfig.instance.isSingla && baseUrl.contains("DeltaAttendanceAPIWIPL")) {
    baseUrl = baseUrl.replaceAll("DeltaAttendanceAPIWIPL", "DeltaAttendanceAPI");
    await LocalDbController.setBaseApiUrl(baseUrl);
  }
  if (baseUrl.isEmpty && FlavorConfig.isInitialized) {
    baseUrl = FlavorConfig.instance.baseUrl;
  }
  if (baseUrl.isNotEmpty) {
    ApiUrl.BASE_URL = baseUrl.endsWith('/') ? baseUrl : "$baseUrl/";
  }

  service.on('updateBaseUrl').listen((event) {
    String newUrl = event?['baseUrl'] ?? "";
    if (FlavorConfig.isInitialized && FlavorConfig.instance.isSingla && newUrl.contains("DeltaAttendanceAPIWIPL")) {
      newUrl = newUrl.replaceAll("DeltaAttendanceAPIWIPL", "DeltaAttendanceAPI");
    }
    if (newUrl.isNotEmpty) {
      ApiUrl.BASE_URL = newUrl.endsWith('/') ? newUrl : "$newUrl/";
    }
  });

  service.on('updateBattery').listen((event) async {
    final battery = event?['battery'] ?? '';
    if (battery.isNotEmpty) {
      _lastBatteryInfo = battery;
      await LocalDbController.setLastBattery(battery);
    }
  });

  service.on('updateMobileNo').listen((event) {
    _bgMobileNo = event?['mobileNo'] ?? "";
  });

  service.on('stop').listen((event) async {
    // User/app explicitly stopped tracking — clear the "should run" flag
    // so the watchdog doesn't bring it back up.
    await _setShouldRun(false);
    service.stopSelf();
  });

  Connectivity().onConnectivityChanged.listen((result) async {
    final bool hasNetwork = result != ConnectivityResult.none;

    if (hasNetwork) {
      print("🌐 Network restored → syncing offline data");
      await syncOfflineLocations(ApiUrl.BASE_URL);
    } else {
      print("📡 Network lost → will queue data");
    }
  });

  final startDay = DateTime.now();

  while (true) {
    try {
      final now = DateTime.now();

      // Robust calendar-day rollover check (replaces the fragile
      // hour==23 && minute>=59 check, which can be skipped over if the
      // tick interval jumps past that window, e.g. device sleep).
      if ((now.hour == 23 && now.minute >= 59) ||
          now.day != startDay.day ||
          now.month != startDay.month ||
          now.year != startDay.year) {
        print("🛑 BG: Auto-stopping service at 11:59 PM or calendar day changed");
        await LocalDbController.setIsBgServiceRunning(false);
        await _setShouldRun(false);
        try {
          await _disarmWatchdogs();
        } catch (e) {
          print("⚠️ Failed to disarm watchdogs in background isolate: $e");
        }
        service.stopSelf();
        break;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      String mobileNo = _resolveMobileNo(prefs: prefs);

      if (ApiUrl.BASE_URL.isNotEmpty && mobileNo.isNotEmpty) {
        await _runTick(ApiUrl.BASE_URL, mobileNo, service);
      } else {
        print("⚠️ Waiting for BaseUrl and MobileNo...");
      }
    } catch (e) {
      print("❌ Loop error: $e");
    }
    await Future.delayed(_kInterval);
  }
}

/// Same mobile-number fallback chain used by the original loop, extracted
/// so both the service loop and the watchdog tick can share it.
String _resolveMobileNo({SharedPreferences? prefs}) {
  String mobileNo = "";

  if (prefs != null) {
    mobileNo = prefs.getString("REAL_MOBILE_NO") ??
        prefs.getString("BG_MOBILE_NO") ??
        _bgMobileNo;
  } else {
    mobileNo = _bgMobileNo;
  }

  if (mobileNo.isEmpty || mobileNo.contains('-')) {
    final gs = GetStorage();
    final possibleValues = [
      gs.read('MobileNo')?.toString(),
      gs.read('EmpID')?.toString(),
      gs.read('UsersName')?.toString(),
      gs.read('AutoId')?.toString(),
    ];
    for (final val in possibleValues) {
      if (val != null && val.isNotEmpty && !val.contains('-')) {
        mobileNo = val;
        break;
      }
    }
  }

  return mobileNo;
}

// ================= TICK =================
Future<void> _runTick(
    String baseUrl, String mobileNo, ServiceInstance service) async {
  try {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (nowMs - _lastSentMs < _kGuardMs) {
      print("⏱ Skipping duplicate tick");
      return;
    }
    _lastSentMs = nowMs;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permission denied");
      return;
    }

    final isGpsOn = await Geolocator.isLocationServiceEnabled();

    Position? pos;

    if (isGpsOn) {
      pos = await _getPosition();
    } else {
      print("⚠️ GPS OFF → will send 0,0");
    }

    await _sendLocation(pos, mobileNo, baseUrl, service);
    await syncOfflineLocations(baseUrl);
  } catch (e) {
    print("❌ Tick error: $e");
  }
}

// ================= GET POSITION =================
Future<Position?> _getPosition() async {
  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _kLocTimeout,
    );
  } catch (_) {
    return await Geolocator.getLastKnownPosition();
  }
}

// ================= SEND =================
Future<void> _sendLocation(
    Position? pos,
    String mobileNo,
    String baseUrl,
    ServiceInstance service,
    ) async {
  final now = DateTime.now();

  final connectivity = await Connectivity().checkConnectivity();
  final bool hasNetwork = connectivity != ConnectivityResult.none;

  final isGpsOn = await Geolocator.isLocationServiceEnabled();

  final info = await getDeviceAndStatusInfo();

  String lat = "0";
  String long = "0";

  if (isGpsOn && pos != null) {
    lat = pos.latitude.toString();
    long = pos.longitude.toString();
  }

  final timestamp = DateFormat("dd-MMM-yyyy hh:mm a").format(now);

  if (!hasNetwork) {
    await OfflineQueue.add({
      "mobileNo": mobileNo,
      "lat": lat,
      "long": long,
      "battery": _cleanBattery(info['batterystatus']),
      "gps": isGpsOn ? "true" : "false",
      "net": "false",
      "time": timestamp,
      "appversion": info['appversion'],
      "modelname": info['modelname'],
      "androidversion": info['androidversion'],
    });
    _updateNotification(service, "Saved offline", lat, long);
    return;
  }

  try {
    await sendBackgroundLocationApi(
      fullUrl: ApiUrl.InsertlatLong,
      mobileNo: mobileNo,
      lat: lat,
      long: long,
      batterystatus: _cleanBattery(info['batterystatus']),
      gpsstatus: isGpsOn ? "true" : "false",
      netstatus: hasNetwork ? "true" : "false",
      appversion: info['appversion'] ?? '',
      modelname: info['modelname'] ?? '',
      androidversion: info['androidversion'] ?? '',
      insertedon: timestamp,
    );

    print("✅ SENT SUCCESS → GPS:${isGpsOn} LAT:$lat");
    _updateNotification(service, "Last: ${DateFormat('HH:mm:ss').format(now)}", lat, long);
  } catch (e) {
    print("❌ API failed → saved offline");

    await OfflineQueue.add({
      "mobileNo": mobileNo,
      "lat": lat,
      "long": long,
      "battery": info['batterystatus'],
      "gps": isGpsOn ? "true" : "false",
      "net": "false",
      "time": timestamp,
      "appversion": info['appversion'],
      "modelname": info['modelname'],
      "androidversion": info['androidversion'],
    });

    _updateNotification(service, "Offline mode", lat, long);
  }
}

void _updateNotification(
    ServiceInstance service, String status, String lat, String long) {
  if (service is AndroidServiceInstance) {
    final String appTitle = FlavorConfig.isInitialized ? FlavorConfig.instance.appTitle : 'Singla';
    service.setForegroundNotificationInfo(
      title: "$appTitle Location Tracking",
      content: "$status | Lat: $lat, Long: $long",
    );
  }
}

// ================= API CALL =================
Future<void> sendBackgroundLocationApi({
  required String fullUrl,
  required String mobileNo,
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
  print("🚀 BG-API: Sending to $fullUrl");
  print("📱 MobileNo: $mobileNo | Lat: $lat | Long: $long | Battery: $batterystatus | GPS: $gpsstatus | Net: $netstatus | AppVer: $appversion | Model: $modelname | AndroidVer: $androidversion | Time: $insertedon");

  try {
    final dio = Dio();
    String safeStr(String? val, int maxLength) {
      if (val == null) return "";
      return val.length > maxLength ? val.substring(0, maxLength) : val;
    }

    final formData = FormData.fromMap({
      "MobileNo": mobileNo,
      "Lat": lat,
      "Long": long,
      "BattryStatus": batterystatus, // Already cleaned by _cleanBattery
      "GPSStatus": safeStr(gpsstatus, 50),
      "NetStatus": safeStr(netstatus, 50),
      "AppVersion": safeStr(appversion, 20),
      "InsertedOn": insertedon,
      "ModelName": safeStr(modelname, 50),
      "AndroidVersion": safeStr(androidversion, 20),
    });

    final response = await dio.post(
      fullUrl,
      data: formData,
    );

    if (response.statusCode == 200) {
      print("✅ BG-API Success: ${response.data}");
    } else {
      print("⚠️ BG-API Failed with status: ${response.statusCode}");
      throw Exception("API Failed: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ BG-API Error: $e");
    if (e is DioException) {
      print("❌ Dio Error Info: ${e.response?.statusCode} | ${e.response?.statusMessage}");
    }
    rethrow;
  }
}

// ================= HELPERS =================
String _cleanBattery(String? status) {
  if (status == null) return "0%";
  final match = RegExp(r'\((\d+%)\)').firstMatch(status);
  if (match != null) return match.group(1)!;
  return status.replaceAll(RegExp(r'[^0-9%]'), '');
}

// ================= DEVICE INFO =================
Future<Map<String, String>> getDeviceAndStatusInfo() async {
  String battery = "";

  try {
    final batteryPlugin = Battery();
    final level = await batteryPlugin.batteryLevel;
    final state = await batteryPlugin.batteryState;

    String stateStr = "unknown";
    switch (state) {
      case BatteryState.charging:
        stateStr = "charging";
        break;
      case BatteryState.discharging:
        stateStr = "discharging";
        break;
      case BatteryState.full:
        stateStr = "full";
        break;
      case BatteryState.unknown:
        stateStr = "unknown";
        break;
      case BatteryState.connectedNotCharging:
        stateStr = "not_charging";
        break;
    }

    battery = "$stateStr ($level%)";
  } catch (e) {
    print("❌ Error fetching battery from plugin: $e");
  }

  if (battery.isEmpty) {
    battery = _lastBatteryInfo;
  }

  if (battery.isEmpty) {
    battery = await LocalDbController.getLastBattery() ?? "";
  }

  final di = DeviceInfoPlugin();

  String model = '';
  String os = '';

  try {
    if (Platform.isAndroid) {
      final a = await di.androidInfo;
      model = a.model ?? '';
      os = a.version.release;
    } else if (Platform.isIOS) {
      final ios = await di.iosInfo;
      model = ios.utsname.machine;
      os = ios.systemVersion;
    }
  } catch (e) {}

  String appVer = "";
  try {
    appVer = (await PackageInfo.fromPlatform()).version;
  } catch (e) {}

  return {
    'batterystatus': battery,
    'modelname': model,
    'androidversion': os,
    'appversion': appVer,
  };
}
