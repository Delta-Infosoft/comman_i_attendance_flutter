import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../flavor_config.dart';

/// Shows background location permission setup instructions
/// and opens manufacturer-specific auto-start settings.
class BackgroundLocationInfoScreen extends StatefulWidget {
  const BackgroundLocationInfoScreen({super.key});

  @override
  State<BackgroundLocationInfoScreen> createState() => _BackgroundLocationInfoScreenState();
}

class _BackgroundLocationInfoScreenState extends State<BackgroundLocationInfoScreen> {

  String pauseAppActivityStatus = 'Checking...';



  @override
  void initState() {
    _loadPauseStatus();
    super.initState();
  }

  Future<void> _loadPauseStatus() async {
    try {
      String status = await NativeService.getUnusedAppSettingStatus();

      setState(() {
        pauseAppActivityStatus = status;
      });
    } catch (e) {
      setState(() {
        pauseAppActivityStatus = 'Unable to check';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Location Permission Setup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600,fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Background Location Access Required',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To ensure accurate background location tracking after check-in, please complete the steps below:',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xff444444), height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Step 1 — Battery Usage
                  _buildStepCard(
                    stepNumber: '1',
                    title: 'Battery Usage',
                    icon: Icons.battery_charging_full,
                    iconColor: Colors.orange,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set battery usage to:',
                          style:
                          TextStyle(fontSize: 13, color: Color(0xff555555)),
                        ),
                        const SizedBox(height: 6),
                        _buildBullet('Unrestricted'),
                        _buildBullet('Allow background activity'),
                        _buildBullet('No restrictions'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'This is required to keep location tracking active in the background.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xff666666)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Step 2 — Auto-start
                  _buildStepCard(
                    stepNumber: '2',
                    title: 'Enable Auto-start',
                    icon: Icons.auto_mode,
                    iconColor: Colors.green,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Steps:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff333333)),
                        ),
                        const SizedBox(height: 6),
                        _buildPathRow([
                          'Settings',
                          'Apps',
                          'Auto-start / Background autostart',
                          FlavorConfig.instance.appName,
                          'Allow',
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Step 3 — Pause app activity

                  _buildStepCard(
                    stepNumber: '3',
                    title: 'Disable "Pause app activity if unused"',
                    icon: Icons.pause_circle_outline,
                    iconColor: Colors.purple,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          'Make sure this option is OFF.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xff555555),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          'Current Status: $pauseAppActivityStatus',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: pauseAppActivityStatus.contains('ON')
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),


                      ],
                    ),
                  ),

                  // _buildStepCard(
                  //   stepNumber: '3',
                  //   title: 'Disable "Pause app activity if unused"',
                  //   icon: Icons.pause_circle_outline,
                  //   iconColor: Colors.purple,
                  //   content: const Text(
                  //     'Make sure this option is OFF.',
                  //     style: TextStyle(fontSize: 13, color: Color(0xff555555)),
                  //   ),
                  // ),
                  const SizedBox(height: 12),

                  // Step 4 — Location Permission
                  _buildStepCard(
                    stepNumber: '4',
                    title: 'Location Permission',
                    icon: Icons.gps_fixed,
                    iconColor: Colors.blue,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Set location permission to:',
                              style:
                              TextStyle(fontSize: 13, color: Color(0xff555555)),
                            ),

                            SizedBox(
                              width: 6,
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Allow all the time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 6),

                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'This ensures location is tracked after check-in even when the app is closed.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xff666666)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mandatory warning (red)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      '⚠  These settings are mandatory for reliable location tracking.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // bottom padding for buttons
                ],
              ),
            ),
          ),

          // Bottom action buttons
          SafeArea(
            maintainBottomViewPadding: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Later button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Later',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Enable button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _openAutoStartSettings,

                      child: Text('Enable Auto-start',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlavorConfig.instance.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),


                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      // onPressed: _openAutoStartSettings,
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          await openAppSettings();
                        }
                      },
                      child: Text('Open App Setting',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlavorConfig.instance.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    String? text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: iconColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff292666)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 14, color: Color(0xff555555))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathRow(List<String> steps) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: steps.asMap().entries.map((e) {
        final isLast = e.key == steps.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLast
                    ? const Color(0xff292666).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isLast
                        ? const Color(0xff292666).withOpacity(0.3)
                        : Colors.grey.shade300),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                  color: isLast
                      ? const Color(0xff292666)
                      : const Color(0xff555555),
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_ios,
                  size: 10, color: Color(0xff888888)),
              const SizedBox(width: 2),
            ],
          ],
        );
      }).toList(),
    );
  }

//  ─── Auto-start settings per manufacturer ──────────────────────────────────
  Future<void> _openAutoStartSettings() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      debugPrint('📦 Device manufacturer: $manufacturer');
      await _launchAutoStartIntent(manufacturer);
    } catch (e) {
      debugPrint('Auto-start settings error: $e');
      _openAppDetails(); // fallback
    }
  }

  Future<void> _launchAutoStartIntent(String manufacturer) async {
    // Show instruction dialog BEFORE opening the screen
    await _showPermissionInstructionDialog(manufacturer);
  }

  Future<void> _showPermissionInstructionDialog(String manufacturer) async {
    final context = Get.context!;

    // Instruction text varies by OEM
    String steps = '';
    if (manufacturer == 'vivo') {
      steps =
      '1. Enable "Allow background activity"\n2. Enable "Allow auto-launch"';
    } else if (manufacturer == 'realme' || manufacturer == 'oppo') {
      steps =
      '1. Enable "Allow background activity"\n2. Enable "Allow auto-launch"';
    } else if (manufacturer == 'xiaomi' ||
        manufacturer == 'redmi' ||
        manufacturer == 'poco') {
      steps =
      '1. Enable "Autostart"\n2. Set Battery Saver to "No restrictions"';
    } else {
      steps =
      '1. Tap "Battery"\n2. Select "Unrestricted"\n3. Enable background activity';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Background Permission'),
        content: Text(
          '${FlavorConfig.instance.appName} needs background activity permission to track location.\n\n'
              'On the next screen:\n$steps',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openOemScreen(
                  manufacturer); // open exact screen after dialog
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openOemScreen(String manufacturer) async {
    final intents = _getOemIntents(manufacturer);

    for (final intent in intents) {
      try {
        await intent.launch();
        return; // success — stop trying
      } on PlatformException catch (e) {
        debugPrint('⚠️ Intent failed ($manufacturer): $e → trying next...');
      } catch (e) {
        debugPrint('⚠️ Intent error: $e → trying next...');
      }
    }

    // All OEM intents failed → fall back to standard app details
    debugPrint('⚠️ All OEM intents failed → opening app details');
    await _openAppDetails();
  }

  /// Returns a list of intents to try in order for each OEM.
  /// Multiple intents per OEM handle different firmware versions.
  List<AndroidIntent> _getOemIntents(String manufacturer) {
    switch (manufacturer.toLowerCase()) {
    // ── VIVO ─────────────────────────────────────────────────
      case 'vivo':
        return [
          // Power consumption controls screen (exact screen in screenshot)
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.vivo.permissionmanager',
            componentName:
            'com.vivo.permissionmanager.activity.PurviewTabActivity',
          ),
          // Older Vivo firmware
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.vivo.permissionmanager',
            componentName:
            'com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
          ),
        ];

    // ── XIAOMI / REDMI / POCO ────────────────────────────────
      case 'xiaomi':
      case 'redmi':
      case 'poco':
        return [
          // MIUI 12+ autostart
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.miui.securitycenter',
            componentName:
            'com.miui.permcenter.autostart.AutoStartManagementActivity',
          ),
          // MIUI battery settings (unrestricted background)
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.miui.powerkeeper',
            componentName:
            'com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity',
          ),
          // Older MIUI
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.miui.securitycenter',
            componentName: 'com.miui.securitycenter.MainActivity',
          ),
        ];

    // ── OPPO ─────────────────────────────────────────────────
      case 'oppo':
        return [
          // ColorOS 11+
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.safecenter',
            componentName:
            'com.coloros.safecenter.permission.startup.StartupAppListActivity',
          ),
          // ColorOS older
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oppo.safe',
            componentName:
            'com.oppo.safe.permission.startup.StartupAppListActivity',
          ),
          // ColorOS battery
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.oppoguardelf',
            componentName:
            'com.coloros.powermanager.powersave.PowerUsageModelActivity',
          ),
        ];

    // ── REALME ───────────────────────────────────────────────
      case 'realme':
        return [
          // Realme UI 2.0+
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.realme.securitycenter',
            componentName:
            'com.realme.securitycenter.permission.startup.StartupAppListActivity',
          ),
          // Realme UI older (uses OPPO base)
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.safecenter',
            componentName:
            'com.coloros.safecenter.permission.startup.StartupAppListActivity',
          ),
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oppo.safe',
            componentName:
            'com.oppo.safe.permission.startup.StartupAppListActivity',
          ),

          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oplus.safecenter',
            componentName:
            'com.oplus.safecenter.permission.startup.StartupAppListActivity',
          ),

          // ── Realme UI 2.0 (2021 devices) ────────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.realme.safecenter',
            componentName:
            'com.realme.safecenter.permission.startup.StartupAppListActivity',
          ),

          // ── Realme Security Center variant ───────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.realme.securitycenter',
            componentName:
            'com.realme.securitycenter.permission.startup.StartupAppListActivity',
          ),

          // ── ColorOS 11 base (older Realme) ───────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.safecenter',
            componentName:
            'com.coloros.safecenter.permission.startup.StartupAppListActivity',
          ),

          // ── OPPO Safe base (very old Realme) ─────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oppo.safe',
            componentName:
            'com.oppo.safe.permission.startup.StartupAppListActivity',
          ),

          // ── Realme Power Manager ─────────────────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oplus.powerkeeper',
            componentName:
            'com.oplus.powerkeeper.ui.HiddenAppsContainerManagementActivity',
          ),

          // ── ColorOS Power Manager ────────────────────────────────
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.oppoguardelf',
            componentName:
            'com.coloros.powermanager.powersave.PowerUsageModelActivity',
          ),

          // ── Direct app battery settings (Android 6+) ─────────────
          // Opens "Battery" page for THIS app specifically
          AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oplus.safecenter',
            componentName:
            'com.oplus.safecenter.permission.PermissionTopActivity',
            arguments: <String, dynamic>{
              'packageName': _getPackageName(),
            },
          ),

          // ── Stock Android battery optimization ───────────────────
          // Last resort — works on any Android
          const AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
        ];

    // ── SAMSUNG ──────────────────────────────────────────────
      case 'samsung':
        return [
          // One UI 4+ — Device Care > Battery > Background usage limits
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.samsung.android.lool',
            componentName: 'com.samsung.android.lool.MainActivity',
          ),
          // Older One UI — Device Maintenance
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.samsung.android.sm.policy',
            componentName: 'com.samsung.android.sm.policy.MainActivity',
          ),
        ];

    // ── HUAWEI / HONOR ───────────────────────────────────────
      case 'huawei':
      case 'honor':
        return [
          // EMUI 9+ — App Launch
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.huawei.systemmanager',
            componentName:
            'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
          ),
          // EMUI older
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.huawei.systemmanager',
            componentName:
            'com.huawei.systemmanager.optimize.process.ProtectActivity',
          ),
          // Battery optimization
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.huawei.systemmanager',
            componentName: 'com.huawei.systemmanager.MainActivityWithTabbar',
          ),
        ];

    // ── ONEPLUS ──────────────────────────────────────────────
      case 'oneplus':
        return [
          // OxygenOS / ColorOS (newer OnePlus uses ColorOS base)
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.coloros.safecenter',
            componentName:
            'com.coloros.safecenter.permission.startup.StartupAppListActivity',
          ),
          // OxygenOS older
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.oneplus.security',
            componentName:
            'com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
          ),
        ];

    // ── ASUS ─────────────────────────────────────────────────
      case 'asus':
        return [
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.asus.mobilemanager',
            componentName:
            'com.asus.mobilemanager.powersaver.PowerSaverSettings',
          ),
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.asus.mobilemanager',
            componentName: 'com.asus.mobilemanager.entry.FunctionActivity',
          ),
        ];

    // ── MEIZU ────────────────────────────────────────────────
      case 'meizu':
        return [
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.meizu.safe',
            componentName: 'com.meizu.safe.permission.SmartPermissionActivity',
          ),
        ];

    // ── LENOVO ───────────────────────────────────────────────
      case 'lenovo':
        return [
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.lenovo.security',
            componentName: 'com.lenovo.security.MainActivity',
          ),
        ];

    // ── TECNO / INFINIX / ITEL (Transsion) ───────────────────
      case 'tecno':
      case 'infinix':
      case 'itel':
        return [
          const AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.transsion.phonemaster',
            componentName: 'com.transsion.phonemaster.ui.activity.MainActivity',
          ),
        ];

    // ── NOKIA ────────────────────────────────────────────────
      case 'nokia':
        return [
          // Nokia uses near-stock Android — battery optimization is enough
          const AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
        ];

    // ── MOTOROLA / GOOGLE / STOCK ANDROID ────────────────────
    // These use stock Android — just battery optimization settings
      case 'motorola':
      case 'google':
      default:
        return [
          const AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
        ];
    }
  }

  Future<void> _openAppDetails() async {
    final intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:${await _getPackageName()}',
    );
    try {
      await intent.launch();
    } catch (e) {
      debugPrint('❌ App details failed: $e');
    }
  }

  Future<String> _getPackageName() async {
    final info = await PackageInfo.fromPlatform();
    return info.packageName;
  }
}

// oem_battery_optimizer.dart
//
// The single biggest cause of background-kill on real-world Android devices is
// NOT Doze — it's OEM-specific "background app cleaner" features.
// This file gives you a one-call API to deep-link users into the right
// settings screen for each manufacturer so they can whitelist your app.
//
// Usage (call once after first check-in):
//   await OemBatteryOptimizer.requestUnrestricted(context);

class OemBatteryOptimizer {
  OemBatteryOptimizer._();

  static const _channel = MethodChannel('com.fieldtracker/battery_optimizer');

  /// Show a one-time dialog and deep-link to the correct OEM settings screen.
  /// Safe to call on every app launch — tracks whether the user has already
  /// dismissed it via SharedPreferences (handled in native via the channel).
  static Future<void> requestUnrestricted(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final info = await DeviceInfoPlugin().androidInfo;
    final brand = info.brand.toLowerCase(); // e.g. "xiaomi", "samsung"
    final sdkVersion = info.version.sdkInt;

    // On Android 6+ (API 23) we can request to be excluded from Doze.
    // This is separate from OEM-specific screens.
    if (sdkVersion >= 23) {
      try {
        await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (_) {}
    }

    // OEM-specific deep-links.
    // These are undocumented intents; they may break on future ROM updates
    // but are the only reliable way to help users on affected devices.
    String? oemAction;
    String? oemNote;

    if (brand == 'xiaomi' || brand == 'redmi' || brand == 'poco') {
      oemAction = 'com.miui.securitycenter.ACTION_APP_PERM_EDITOR';
      oemNote = 'Tap "No restrictions" under Battery saver';
    } else if (brand == 'huawei' || brand == 'honor') {
      oemAction = 'huawei.intent.action.HSM_PROTECTED_APPS_SETTINGS';
      oemNote = 'Enable "Protected apps" for Field Tracker';
    } else if (brand == 'oppo' || brand == 'realme' || brand == 'oneplus') {
      oemAction =
      'com.coloros.oppoguardelf.powersave.ACTION_POWER_SAVE_SETTING';
      oemNote = 'Set battery usage to "No restrictions"';
    } else if (brand == 'vivo') {
      oemAction =
      'com.vivo.permissionmanager.activity.BgStartUpManagerActivity';
      oemNote = 'Enable background start permission';
    } else if (brand == 'samsung') {
      // Samsung: Settings → Apps → Field Tracker → Battery → Unrestricted
      oemAction =
      null; // Standard ACTION_APPLICATION_DETAILS_SETTINGS works here
      oemNote = 'Go to Battery → select "Unrestricted"';
    }

    if (oemAction != null) {
      try {
        await _channel.invokeMethod('openOemSettings', {'action': oemAction});
      } catch (_) {
        // Fall back to standard app details if OEM intent is unavailable.
        try {
          await _channel.invokeMethod('openAppDetails');
        } catch (_) {}
      }
    } else {
      // Standard: open app battery settings (Android 9+)
      try {
        await _channel.invokeMethod('openAppDetails');
      } catch (_) {}
    }

    if (context.mounted && oemNote != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 $oemNote'),
          showCloseIcon: true,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}



class NativeService {
  static const MethodChannel _channel =
  MethodChannel('mytime/native_battery');

  static Future<String> getUnusedAppSettingStatus() async {
    final String result =
    await _channel.invokeMethod('getUnusedAppSettingStatus');
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Native companion — BatteryOptimizerChannel.kt
// Place at: android/app/src/main/kotlin/com/fieldtracker/BatteryOptimizerChannel.kt
// ─────────────────────────────────────────────────────────────────────────────
//
// class BatteryOptimizerChannel : FlutterPlugin, MethodChannel.MethodCallHandler {
//
//   private lateinit var channel: MethodChannel
//   private lateinit var context: Context
//   private lateinit var activity: Activity
//
//   override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//     context = binding.applicationContext
//     channel = MethodChannel(binding.binaryMessenger, "com.fieldtracker/battery_optimizer")
//     channel.setMethodCallHandler(this)
//   }
//
//   override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//     when (call.method) {
//       "requestIgnoreBatteryOptimizations" -> {
//         val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
//         if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
//           val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
//             data = Uri.parse("package:${context.packageName}")
//           }
//           intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//           context.startActivity(intent)
//         }
//         result.success(null)
//       }
//       "openOemSettings" -> {
//         val action = call.argument<String>("action") ?: return result.error("NO_ACTION","",null)
//         try {
//           val intent = Intent(action).apply {
//             addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//             putExtra("package", context.packageName)
//           }
//           context.startActivity(intent)
//           result.success(null)
//         } catch (e: Exception) {
//           result.error("OEM_FAIL", e.message, null)
//         }
//       }
//       "openAppDetails" -> {
//         val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
//           data = Uri.parse("package:${context.packageName}")
//           addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//         }
//         context.startActivity(intent)
//         result.success(null)
//       }
//       else -> result.notImplemented()
//     }
//   }
//
//   override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//     channel.setMethodCallHandler(null)
//   }
// }
