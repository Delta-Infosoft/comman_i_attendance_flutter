import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide SnackBar utility using ScaffoldMessenger (native Flutter).
/// Use [AppSnackBar.show] everywhere instead of Get.snackbar.
class AppSnackBar {
  AppSnackBar._();

  // ─── Types ──────────────────────────────────────────────────────────────────

  static void success(String title, String message, {BuildContext? context}) {
    _show(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF2E7D32),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void error(String title, String message, {BuildContext? context}) {
    _show(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFC62828),
      icon: Icons.error_outline_rounded,
    );
  }

  static void warning(String title, String message, {BuildContext? context}) {
    _show(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFE65100),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void info(String title, String message, {BuildContext? context}) {
    _show(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF183f83),
      icon: Icons.info_outline_rounded,
    );
  }

  // ─── Generic show (kept for backward-compat with CustomSnackBar.show) ───────

  static void show({
    required String message,
    String? title,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    BuildContext? context,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      backgroundColor: backgroundColor ??
          (isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
      icon: isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
      duration: duration,
    );
  }

  // ─── Core ────────────────────────────────────────────────────────────────────

  static void _show({
    BuildContext? context,
    String? title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;

    // Dismiss any existing snackbar first to avoid stacking
    ScaffoldMessenger.of(ctx).clearSnackBars();

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null && title.isNotEmpty) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: title != null ? 13 : 14,
                        fontWeight: title != null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy alias kept for backward compatibility.
/// Prefer using [AppSnackBar] directly.
class CustomSnackBar {
  static void show({
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppSnackBar.show(
      message: message,
      isError: isError,
      duration: duration,
    );
  }
}
