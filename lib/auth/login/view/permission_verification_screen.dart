import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:waterman_iattandance/screens/home/view/home_screen.dart';
import '../../../flavor_config.dart';

// ─────────────────────────────────────────────
// Data model for each permission step
// ─────────────────────────────────────────────
class _PermissionStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Permission? permission;
  final bool androidOnly;
  final bool isOptional;
  final Color color;

  const _PermissionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.permission,
    this.androidOnly = false,
    this.isOptional = false,
    required this.color,
  });
}

// ─────────────────────────────────────────────
// All permission steps required for background
// tracking service, in order of importance.
// ALL steps are MANDATORY — no skip allowed.
// ─────────────────────────────────────────────
// App primary color — matches the current flavor theme
Color get _kAppRed => FlavorConfig.instance.primaryColor;

List<_PermissionStep> get _allSteps => [
  _PermissionStep(
    icon: Icons.location_on_rounded,
    title: 'Location Access',
    subtitle: 'Allow Location',
    description:
    'Background location is required for geo-fence check-in/out and live route tracking even when the app is closed.\n\nOn Android: select "Allow all the time".\nOn iOS: tap Allow → then select "Always" from the prompt that appears, or go to Settings → Privacy → Location Services → this app → Always.\n\nThis permission is mandatory to use the app.',
    permission: Permission.locationAlways,
    color: _kAppRed,
  ),
  _PermissionStep(
    icon: Icons.notifications_active_rounded,
    title: 'Notifications',
    subtitle: 'Allow Notifications',
    description:
    'Push notifications keep you informed about attendance updates, approvals, and the background tracking service status.\n\nThis permission is optional, but highly recommended.',
    permission: Permission.notification,
    isOptional: true,
    color: _kAppRed,
  ),
  _PermissionStep(
    icon: Icons.camera_alt_rounded,
    title: 'Camera',
    subtitle: 'Allow Camera',
    description:
    'Camera access is needed to capture GPS-tagged attendance photos and images for Outdoor Duty requests.\n\nThis permission is mandatory to use the app.',
    permission: Permission.camera,
    color: _kAppRed,
  ),
  _PermissionStep(
    icon: Icons.battery_charging_full_rounded,
    title: 'Battery Optimization',
    subtitle: 'Unrestricted Battery',
    description:
    'Disabling battery optimization ensures the background tracking service stays alive and continues sending your location, even when the device is in power-saving mode.\n\nThis permission is mandatory to use the app.',
    permission: Permission.ignoreBatteryOptimizations,
    androidOnly: true,
    color: _kAppRed,
  ),
];

// ─────────────────────────────────────────────
// Permission Verification Screen
// ─────────────────────────────────────────────
class PermissionVerificationScreen extends StatefulWidget {
  const PermissionVerificationScreen({super.key});

  @override
  State<PermissionVerificationScreen> createState() =>
      _PermissionVerificationScreenState();
}

class _PermissionVerificationScreenState
    extends State<PermissionVerificationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<_PermissionStep> _steps = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isRequesting = false;

  // null  = not yet requested for this step
  // true  = granted
  // false = denied / not granted
  bool? _stepGranted;

  bool _allDone = false;

  bool _isAppInactive = false;
  bool _waitingForLifecycleResume = false;
  Completer<void>? _resumeCompleter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _initializeSteps();
  }

  // ── Build the list of steps that still need granting ──
  Future<void> _initializeSteps() async {
    final validSteps =
    _allSteps.where((s) => !s.androidOnly || Platform.isAndroid).toList();
    
    final List<_PermissionStep> missingMandatory = [];
    final List<_PermissionStep> missingOptional = [];

    for (final step in validSteps) {
      if (step.permission == null) continue;
      final granted = await _checkPermissionGranted(step);
      if (!granted) {
        if (step.isOptional) {
          missingOptional.add(step);
        } else {
          missingMandatory.add(step);
        }
      }
    }

    if (!mounted) return;

    // If all mandatory permissions are granted, we can bypass the verification screen
    // and go straight to the HomeScreen.
    if (missingMandatory.isEmpty) {
      setState(() {
        _isLoading = false;
        _allDone = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) Get.offAll(() => const HomeScreen());
      });
      return;
    }

    setState(() {
      _steps = [...missingMandatory, ...missingOptional];
      _isLoading = false;
    });

    _animController.forward();
    // Pre-check: maybe user already granted this one outside the app
    _preCheckCurrentStep();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _isAppInactive = true;
    } else if (state == AppLifecycleState.resumed) {
      _isAppInactive = false;
      if (_waitingForLifecycleResume) {
        _waitingForLifecycleResume = false;
        _resumeCompleter?.complete();
      }
      _pollPermissionStatus();
    }
  }

  // ── Active status polling to handle OS propagation delay ──
  Future<void> _pollPermissionStatus() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      if (_currentIndex >= _steps.length) return;
      final step = _steps[_currentIndex];
      final granted = await _checkPermissionGranted(step);
      if (granted) {
        setState(() => _stepGranted = true);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ── Returns true if the given step's permission is sufficiently granted ──
  Future<bool> _checkPermissionGranted(_PermissionStep step) async {
    if (step.permission == null) return true;

    if (step.permission == Permission.notification) {
      final settings =
      await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    // For location:
    // We require "Always" (locationAlways) for background tracking on both Android and iOS.
    if (step.permission == Permission.locationAlways) {
      final alwaysStatus = await Permission.locationAlways.status;
      return alwaysStatus.isGranted;
    }

    // On iOS 14+, photos can be "Limited Access" (PermissionStatus.limited).
    // We accept limited as sufficient — the user has granted some gallery access.
    // if (step.permission == Permission.photos) {
    //   final status = await Permission.photos.status;
    //   return status.isGranted || status.isLimited;
    // }

    final status = await step.permission!.status;
    return status.isGranted;
  }

  // ── Pre-check: mark current step granted if already approved ──
  Future<void> _preCheckCurrentStep() async {
    if (_currentIndex >= _steps.length) return;
    final granted = await _checkPermissionGranted(_steps[_currentIndex]);
    if (mounted && granted) {
      setState(() => _stepGranted = true);
    }
  }

  // ── Request the current permission ──
  // The user CANNOT proceed without granting it.
  Future<void> _requestCurrentPermission() async {
    if (_isRequesting) return;
    setState(() {
      _isRequesting = true;
      _stepGranted = null; // reset while requesting
    });

    final step = _steps[_currentIndex];

    try {
      bool granted = false;

      if (step.permission == Permission.notification) {
        // ── Notifications via Firebase ──
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        granted =
            settings.authorizationStatus == AuthorizationStatus.authorized;
      } else if (step.permission == Permission.locationAlways) {
        // ── Location — iOS two-step flow ──
        //
        // iOS enforces a strict two-step flow:
        //   1. Request "When In Use" → system dialog shown to user
        //   2. Request "Always"      → iOS shows an in-app upgrade prompt
        //                             (only after step 1 is granted)
        //
        // Calling locationAlways.request() directly on iOS returns
        // PermissionStatus.denied even if the user tapped "Allow While Using"
        // because iOS does NOT grant "Always" on the first dialog — it only
        // grants "When In Use". The upgrade to Always is a separate step.

        if (Platform.isIOS) {
          // Step 1: Request "When In Use" if not yet granted
          final whenInUseStatus = await Permission.locationWhenInUse.status;
          if (!whenInUseStatus.isGranted) {
            final result = await Permission.locationWhenInUse.request();
            if (!result.isGranted) {
              // User denied even "When In Use" — nothing we can do
              granted = false;
            } else {
              // Wait for the first dialog dismissal animation to complete
              await Future.delayed(const Duration(milliseconds: 1200));
              
              // Step 2: Now try to upgrade to Always
              final alwaysResult = await Permission.locationAlways.request();
              granted = alwaysResult.isGranted;
            }
          } else {
            // "When In Use" already granted — try upgrading to Always
            final alwaysResult = await Permission.locationAlways.request();
            granted = alwaysResult.isGranted;
          }

          // If still not granted after the dialog, open Settings since Always is required
          if (!granted) {
            await openAppSettings();
            // Wait for the user to return from settings and check again
            _isAppInactive = false;
            _waitingForLifecycleResume = true;
            _resumeCompleter = Completer<void>();
            await _resumeCompleter!.future.timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                _waitingForLifecycleResume = false;
              },
            );
            // Give the OS a tiny moment to register the change
            await Future.delayed(const Duration(milliseconds: 500));
            granted = await _checkPermissionGranted(step);
          }
        } else {
          // ── Android: standard Always flow ──
          // Step 1: ensure "When In Use" is granted first
          final whenInUse = await Permission.locationWhenInUse.status;
          if (!whenInUse.isGranted) {
            await Permission.locationWhenInUse.request();
          }
          // Step 2: request Always
          final alwaysStatus = await Permission.locationAlways.request();
          granted = alwaysStatus.isGranted;

          if (!granted) {
            // Android 11+: system may not show dialog again
            // Send user to Settings where they can pick "Allow all the time"
            await openAppSettings();
            await Future.delayed(const Duration(seconds: 2));
            granted = await _checkPermissionGranted(step);
          }
        }
      } else if (step.permission == Permission.ignoreBatteryOptimizations) {
        // ── Battery optimization (Android only) ──
        final current = await Permission.ignoreBatteryOptimizations.status;
        if (current.isGranted) {
          granted = true;
        } else {
          final result = await Permission.ignoreBatteryOptimizations.request();
          granted = result.isGranted;
          if (!granted) {
            await openAppSettings();
            await Future.delayed(const Duration(seconds: 2));
            granted = await _checkPermissionGranted(step);
          }
        }
      } else {
        // ── Standard permissions ──
        final result = await step.permission!.request();
        // Accept limited access for photos on iOS 14+
        granted = result.isGranted ||
            (step.permission == Permission.photos && result.isLimited);
        if (!granted && result.isPermanentlyDenied) {
          await openAppSettings();
          await Future.delayed(const Duration(seconds: 2));
          granted = await _checkPermissionGranted(step);
        }
      }

      if (mounted) {
        setState(() {
          _stepGranted = granted;
          _isRequesting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stepGranted = false;
          _isRequesting = false;
        });
      }
    }
  }

  // ── Open Settings so user can manually grant ──
  Future<void> _openSettings() async {
    await openAppSettings();
    // After returning, re-check the permission status
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final granted = await _checkPermissionGranted(_steps[_currentIndex]);
    if (mounted) {
      setState(() => _stepGranted = granted);
      if (!granted) {
        // Run active polling just in case it takes a moment to propagate
        _pollPermissionStatus();
      }
    }
  }

  // ── Advance to next step (only called when _stepGranted == true) ──
  void _nextStep() {
    if (_stepGranted != true) return; // guard — must be granted

    if (_currentIndex + 1 >= _steps.length) {
      _finishAndNavigate();
      return;
    }
    setState(() {
      _currentIndex++;
      _stepGranted = null;
      _isRequesting = false;
    });
    _animController.reset();
    _animController.forward();
    _preCheckCurrentStep();
  }

  // ── Skip the current optional permission step ──
  void _skipStep() {
    if (_currentIndex + 1 >= _steps.length) {
      _finishAndNavigate();
      return;
    }
    setState(() {
      _currentIndex++;
      _stepGranted = null;
      _isRequesting = false;
    });
    _animController.reset();
    _animController.forward();
    _preCheckCurrentStep();
  }

  // ── Navigate to dashboard — only when truly all done ──
  void _finishAndNavigate() {
    setState(() => _allDone = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Get.offAll(() => const HomeScreen());
    });
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _kAppRed),
        ),
      );
    }

    if (_allDone) return _buildAllDoneScreen();

    final size = MediaQuery.of(context).size;
    final step = _steps[_currentIndex];
    final progress = (_currentIndex + 1) / _steps.length;
    final isLast = _currentIndex == _steps.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(step, progress),
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildIconCard(step, size),
                        const SizedBox(height: 28),

                        // Title
                        Text(
                          step.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D2E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          step.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Status badge (only after a request has been made)
                        if (_stepGranted == true) _buildStatusBadge(true),
                        if (_stepGranted == false) _buildStatusBadge(false),

                        const SizedBox(height: 20),

                        // Completed steps summary
                        if (_currentIndex > 0) _buildCompletedSteps(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomActions(step, isLast),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Top bar with progress
  // ─────────────────────────────────────────────
  Widget _buildTopBar(_PermissionStep step, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Step ${_currentIndex + 1} of ${_steps.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kAppRed,
                  ),
                ),
              ),
              const Spacer(),
              // Mandatory/Optional badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: step.isOptional ? Colors.blue.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: step.isOptional ? Colors.blue.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      step.isOptional ? Icons.info_outline_rounded : Icons.lock_rounded,
                      size: 12,
                      color: step.isOptional ? Colors.blue.shade600 : Colors.red.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      step.isOptional ? 'Optional' : 'Required',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: step.isOptional ? Colors.blue.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_kAppRed),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Large icon card
  // ─────────────────────────────────────────────
  Widget _buildIconCard(_PermissionStep step, Size size) {
    return Container(
      width: size.width * 0.75,
      height: size.width * 0.65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.color.withOpacity(0.12),
            step.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: step.color.withOpacity(0.15), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.color.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: -15,
            left: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.color.withOpacity(0.08),
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: step.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: step.color.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(step.icon, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Granted / Denied status badge
  // ─────────────────────────────────────────────
  Widget _buildStatusBadge(bool granted) {
    final step = _steps[_currentIndex];
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: granted
              ? Colors.green.shade50
              : (step.isOptional ? Colors.orange.shade50 : Colors.red.shade50),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: granted
                ? Colors.green.shade200
                : (step.isOptional ? Colors.orange.shade200 : Colors.red.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted
                  ? Icons.check_circle_rounded
                  : (step.isOptional ? Icons.info_outline_rounded : Icons.cancel_rounded),
              color: granted
                  ? Colors.green.shade600
                  : (step.isOptional ? Colors.orange.shade600 : Colors.red.shade600),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                granted
                    ? 'Permission Granted ✓'
                    : (step.isOptional
                        ? 'Optional permission — you can skip this step'
                        : 'Permission is required — please grant it to continue'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: granted
                      ? Colors.green.shade700
                      : (step.isOptional ? Colors.orange.shade700 : Colors.red.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Completed steps summary
  // ─────────────────────────────────────────────
  Widget _buildCompletedSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPLETED STEPS',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_currentIndex, (i) {
          final s = _steps[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Icon(Icons.check_rounded,
                      color: Colors.green.shade600, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  s.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Bottom action buttons
  //
  // • Not yet requested  → single "Grant Permission" button (or Skip/Grant for optional)
  // • Granted            → "Continue" / "Go to Dashboard" (green)
  // • Denied             → "Try Again" + "Open Settings" — NO continue/skip (or Skip/Try Again for optional)
  // ─────────────────────────────────────────────
  Widget _buildBottomActions(_PermissionStep step, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── GRANTED: show Continue / All Done ──
          if (_stepGranted == true) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAppRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _nextStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isLast ? 'All Done! Go to Dashboard' : 'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]

          // ── DENIED: Try Again + Open Settings ──
          else if (_stepGranted == false) ...[
            if (step.isOptional) ...[
              // Optional hint
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 15, color: Colors.blue.shade400),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'This permission is optional. You can skip this step.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Skip
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _skipStep,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Try Again
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                        _isRequesting ? null : _requestCurrentPermission,
                        child: _isRequesting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Try Again',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Warning hint
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 15, color: Colors.red.shade400),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'This permission is required. You cannot skip it.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Open Settings
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: step.color, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _openSettings,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_rounded,
                                size: 18, color: step.color),
                            const SizedBox(width: 6),
                            Text(
                              'Open Settings',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: step.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Try Again
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                        _isRequesting ? null : _requestCurrentPermission,
                        child: _isRequesting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Try Again',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ]

          // ── NOT YET REQUESTED ──
          else ...[
            if (step.isOptional) ...[
              Row(
                children: [
                  // Skip Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _skipStep,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Grant Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          _isRequesting ? step.color.withOpacity(0.6) : step.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isRequesting ? null : _requestCurrentPermission,
                        child: _isRequesting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              step.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isRequesting ? step.color.withOpacity(0.6) : step.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isRequesting ? null : _requestCurrentPermission,
                  child: _isRequesting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        (Platform.isIOS && step.permission == Permission.locationAlways || Platform.isIOS && step.permission == Permission.camera)
                            ? 'Continue'
                            : step.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // All Done celebration screen
  // ─────────────────────────────────────────────
  Widget _buildAllDoneScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kAppRed.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.verified_rounded,
                  size: 64, color: _kAppRed),
            ),
            const SizedBox(height: 30),
            Text(
              "You're all set! All permissions granted 🎉",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Taking you to the dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(color: _kAppRed),
          ],
        ),
      ),
    );
  }
}
