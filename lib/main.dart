import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:waterman_iattandance/screens/home/view_model/home_screen_controller.dart';
import 'package:waterman_iattandance/service/background_location_service.dart';
import 'package:waterman_iattandance/service/my_firebase_messaging_service.dart';
import 'constant/battery_level.dart';
import 'firebase_options.dart';
import 'auth/login/view/login_screen.dart';
import 'auth/login/view/permission_verification_screen.dart';
import 'constant/local_db/local_db.dart';
import 'screens/project_journey_cycle/viewmodel/Project_journey_controller.dart';
import 'screens/daily_tour_details/viewmodel/DTD_Controller.dart';
import 'screens/daily_tour_details/viewmodel/DTD_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constant/api_url/api_url.dart';
import 'flavor_config.dart';
import 'app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(AppFlavor.singla);
  runMyApp();
}

/// Shared startup logic called by every flavor's entry point.
Future<void> runMyApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("🔥 Firebase init warning/error: $e");
  }

  try {
    await MyFirebaseMessagingService.backgroundMessage();
    await MyFirebaseMessagingService.initilizeNotification();
  } catch (e) {
    debugPrint("🔥 FirebaseMessaging init error: $e");
  }
  // await initNotificationChannel(); // Replaced by MyFirebaseMessagingService
  // await requestLocationPermissions();
  await rearmWatchdogsIfNeeded();


  // 🏠 App startup: resume background tracking if it was active
  // when the app got killed (mirrors MyTime's post-frame status check).
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final mobileNo = LocalDbController.to.mobileNo;

    if (mobileNo != null && mobileNo.toString().isNotEmpty) {
      debugPrint(
          "🏠 App startup: Checking status for $mobileNo to resume background service");
      try {
        final homeCtrl = Get.find<HomeScreenController>();
        await homeCtrl.fetchCheckinStatus();
      } catch (e) {
        debugPrint("Startup Status Check Error: $e");
      }
    }
  });


  Timer.periodic(const Duration(minutes: 5), (timer) async {
    try {
      final battery = await NativeBattery.getBatteryStatus();
      if (battery.isNotEmpty) {
        await LocalDbController.setLastBattery(battery);

        FlutterBackgroundService().invoke(
          'updateBattery',
          {'battery': battery},
        );

        print("🔋 Foreground battery updated → $battery");
      }
    } catch (_) {}
  });

  // Initialize Firebase

  // Initialize GetStorage

  await GetStorage.init();
  await LocalDbController.init();

  final savedBaseUrl = LocalDbController.getBaseApiUrl();
  if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
    ApiUrl.BASE_URL = savedBaseUrl;
    debugPrint("🌐 Restored saved BASE_URL on startup: $savedBaseUrl");
  }
  // Get.lazyPut<HomeScreenController>(() => HomeScreenController());
  Get.lazyPut(() => HomeScreenController(), fenix: true);

  runApp(MyApp());
}

Future<void> requestLocationPermissions() async {
  // Foreground location
  if (!await Permission.location.isGranted) {
    await Permission.location.request();
  }

  // Background location
  if (!await Permission.locationAlways.isGranted) {
    await Permission.locationAlways.request();
  }

  print("✅ Location permissions granted");
}

Future<void> initNotificationChannel() async {
  final appTitle = FlavorConfig.isInitialized ? FlavorConfig.instance.appTitle : 'Singla';
  final channelId = FlavorConfig.isInitialized ? '${FlavorConfig.instance.flavor.name}_bg_service' : 'singla_bg_service';

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    '$appTitle Background Service',
    description: 'Used for background attendance tracking',
    importance: Importance.low,
  );

  final flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      initialBinding: AppBindings(),
      home: UpgradeAlert(
        showIgnore: false,
        showLater: false,
        barrierDismissible: false,
        upgrader: Upgrader(
          countryCode: 'IN',
          debugLogging: true,
          debugDisplayAlways: false,
          durationUntilAlertAgain: Duration.zero,
          storeController: UpgraderStoreController(
            onAndroid: () => PlayStoreUpgraderStore(),
            oniOS: () => AppStoreUpgraderStore(),
          ),
        ),
        child: Obx(() {
          final localDb = LocalDbController.to;

          return localDb.isLoggedIn.value
              ? const PermissionVerificationScreen()
              : LoginScreen();
        }),
      ),
    );
  }

  Future<bool> _checkLoginStatus() async {
    try {
      // Check login status using LocalDbController
      return LocalDbController.to.mobileNo != null &&
          LocalDbController.to.mobileNo!.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}


class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Permanent Local DB
    Get.put(LocalDbController(), permanent: true);

    Get.lazyPut(() => HomeScreenController(), fenix: true);
    Get.lazyPut(() => JourneyCycleController(), fenix: true);

    Get.lazyPut(() => DTDRepository(), fenix: true);
    Get.lazyPut(() => DTDController(repository: Get.find()), fenix: true);
  }
}

class PlayStoreUpgraderStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    if (state.packageInfo == null) return UpgraderVersionInfo();
    final id = state.packageInfo!.packageName;
    final url = 'https://play.google.com/store/apps/details?id=$id&gl=${country ?? 'IN'}&hl=${language ?? 'en'}';
    
    try {
      final response = await http.get(Uri.parse(url), headers: state.clientHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final html = response.body;
        final match = RegExp(r'\[\[\[\"([0-9]+\.[0-9]+\.[0-9]+[^\\\"]*)\"\]\]').firstMatch(html);
        final versionStr = match?.group(1);
        
        if (versionStr != null) {
          final appStoreVersion = Version.parse(versionStr);
          
          final versionInfo = UpgraderVersionInfo(
            installedVersion: installedVersion,
            appStoreListingURL: url,
            appStoreVersion: appStoreVersion,
            isCriticalUpdate: true,
            minAppVersion: appStoreVersion,
            // releaseNotes: 'New version available. Please update to continue.',
          );
          if (state.debugLogging) {
            print('upgrader: PlayStoreUpgraderStore parsed info: $versionInfo');
          }
          return versionInfo;
        }
      }
    } catch (e) {
      if (state.debugLogging) {
        print('upgrader: PlayStoreUpgraderStore error: $e');
      }
    }
    return UpgraderVersionInfo();
  }
}

class AppStoreUpgraderStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    if (state.packageInfo == null) return UpgraderVersionInfo();
    final bundleId = state.packageInfo!.packageName;
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = state.debugLogging;
    iTunes.client = state.client;
    iTunes.clientHeaders = state.clientHeaders;

    final effectiveCountry = country ?? state.countryCodeOverride ?? 'IN';

    try {
      final response = await iTunes.lookupByBundleId(
        bundleId,
        country: effectiveCountry,
        language: language,
      );

      if (response != null) {
        final version = iTunes.version(response);
        final url = iTunes.trackViewUrl(response);
        final releaseNotes = iTunes.releaseNotes(response);

        if (version != null) {
          final appStoreVersion = Version.parse(version);
          final versionInfo = UpgraderVersionInfo(
            installedVersion: installedVersion,
            appStoreListingURL: url,
            appStoreVersion: appStoreVersion,
            isCriticalUpdate: true,
            minAppVersion: appStoreVersion,
            releaseNotes: releaseNotes,
          );
          if (state.debugLogging) {
            print('upgrader: AppStoreUpgraderStore parsed info: $versionInfo');
          }
          return versionInfo;
        }
      }
    } catch (e) {
      if (state.debugLogging) {
        print('upgrader: AppStoreUpgraderStore error: $e');
      }
    }
    return UpgraderVersionInfo();
  }
}
