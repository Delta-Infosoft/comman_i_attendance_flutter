import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';

/// Supported client flavors
enum AppFlavor { waterman, singla }

/// Menu options per flavor. Add a new value here to create a new menu entry.
enum MenuOption {
  PJC_CALENDAR,
  DAILY_TOUR,
  TOUR_VOUCHER,
  TOUR_VOUCHER_APPROVAL,
  TOUR_ADVANCE_EXPENSE,
  NEW_CUSTOMER_DEALER,
  DEALER_CHECK_IN,
  MY_PORTFOLIO,
  LOCATION_LOG,
  ATTENDANCE_REPORT,
  IERP_HO,
  IERP_NAGPUR,
  IERP_KOLKATA,
  WIPL_PJC,
  PRIVACY_POLICY,
}

/// Central flavor configuration — set once at startup via [FlavorConfig.initialize].
class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String logoAsset;
  final Color primaryColor;
  final Color primaryLightColor;
  final Set<MenuOption> menuOptions;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.logoAsset,
    required this.primaryColor,
    required this.primaryLightColor,
    required this.menuOptions,
  });

  String get serverIp {
    try {
      final saved = LocalDbController.getIP();
      if (saved.isNotEmpty) {
        return saved;
      }
    } catch (_) {}
    return flavor == AppFlavor.singla ? '103.168.19.137' : '103.113.32.126';
  }

  String get baseUrl {
    try {
      final saved = LocalDbController.getBaseApiUrl();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (_) {}
    final apiFolder = flavor == AppFlavor.singla
        ? "DeltaAttendanceAPI"
        : "DeltaAttendanceAPIWIPL";
    return "http://$serverIp/$apiFolder/";
  }

  // ── Singleton ────────────────────────────────────────────────────────────────
  static FlavorConfig? _instance;

  static bool get isInitialized => _instance != null;

  static FlavorConfig get instance {
    assert(_instance != null,
        'FlavorConfig is not initialized. Call FlavorConfig.initialize() first.');
    return _instance!;
  }

  /// Call this once inside each flavor's main entry point before [runApp].
  static void initialize(AppFlavor flavor) {
    _instance = _buildConfig(flavor);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('APP_FLAVOR', flavor.name);
    });
  }

  // ── Per-flavor definitions ───────────────────────────────────────────────────
  static FlavorConfig _buildConfig(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.waterman:
        return FlavorConfig._(
          flavor: AppFlavor.waterman,
          appName: 'Waterman iAttendance V2',
          logoAsset: 'assets/img_1.png',
          primaryColor: const Color(0xFFE53935), // Waterman Red
          primaryLightColor: const Color(0xFFEF5350), // Waterman Light Red
          menuOptions: {
            MenuOption.PJC_CALENDAR,
            MenuOption.DAILY_TOUR,
            MenuOption.TOUR_VOUCHER,
            MenuOption.TOUR_VOUCHER_APPROVAL,
            MenuOption.NEW_CUSTOMER_DEALER,
            MenuOption.MY_PORTFOLIO,
            MenuOption.ATTENDANCE_REPORT,
            MenuOption.IERP_HO,
            MenuOption.IERP_NAGPUR,
            MenuOption.IERP_KOLKATA,
            MenuOption.WIPL_PJC,
          },
        );

      case AppFlavor.singla:
        return FlavorConfig._(
          flavor: AppFlavor.singla,
          appName: 'Singla iAttendance',
          logoAsset: 'assets/singla_logo.png',
          primaryColor: const Color(0xFF183f83), // Singla dark blue
          primaryLightColor: const Color(0xFF1565C0),
          menuOptions: {
            MenuOption.PJC_CALENDAR,
            MenuOption.DAILY_TOUR,
            MenuOption.TOUR_VOUCHER,
            MenuOption.TOUR_ADVANCE_EXPENSE,
            MenuOption.NEW_CUSTOMER_DEALER,
            MenuOption.DEALER_CHECK_IN,
            MenuOption.MY_PORTFOLIO,
            MenuOption.LOCATION_LOG,
            MenuOption.ATTENDANCE_REPORT,
            MenuOption.PRIVACY_POLICY,
          },
        );
    }
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────
  bool get isWaterman => flavor == AppFlavor.waterman;
  bool get isSingla => flavor == AppFlavor.singla;
  String get appTitle => isSingla ? 'Singla' : 'Waterman';

  /// Button main action color: green for Waterman, primaryColor for Singla
  Color get buttonColor => isWaterman ? Colors.green : primaryColor;
  Color get buttonLightColor => isWaterman ? Colors.lightGreen : primaryLightColor;

  /// AppBar background color: white for Singla, primaryColor for Waterman
  Color get appBarColor => isSingla ? Colors.white : primaryColor;

  /// Table header/border color: green for Waterman, primaryColor for Singla
  Color get tableColor => isWaterman ? Colors.green : primaryColor;


  /// AppBar icon/title color: dark for Singla, white for Waterman
  Color get appBarForegroundColor =>
      isSingla ? const Color(0xFF1A1A2E) : Colors.white;

  bool hasMenu(MenuOption option) => menuOptions.contains(option);

  /// Returns a 3 px blue indicator line at the bottom of the AppBar for
  /// the Singla flavor.  Returns null for Waterman (no indicator needed).
  /// Usage: AppBar(bottom: FlavorConfig.instance.getAppBarBottom(), ...)
  PreferredSizeWidget? getAppBarBottom() {
    if (!isSingla) return null;
    return PreferredSize(
      preferredSize: const Size.fromHeight(3),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryLightColor,
              primaryColor,
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a styled leading back button for the flavor:
  /// - Singla: circular grey container with back icon
  /// - Waterman: simple back button with correct foreground color
  Widget? getAppBarLeading(BuildContext context, {VoidCallback? onPressed}) {
    if (isSingla) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F9), // Subtle grey-blue circle
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A2E), // Dark color for icon
              size: 18,
            ),
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: appBarForegroundColor, // White for Waterman
        ),
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
      );
    }
  }
}
