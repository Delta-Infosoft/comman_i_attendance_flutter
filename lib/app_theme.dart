import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flavor_config.dart';

/// Returns the [ThemeData] for the current flavor.
class AppTheme {
  AppTheme._();

  static ThemeData get current {
    final config = FlavorConfig.instance;

    // Singla uses a clean white AppBar; Waterman uses the branded primary color
    final appBarBg =
        config.isSingla ? Colors.white : config.primaryColor;
    final appBarFg =
        config.isSingla ? const Color(0xFF1A1A2E) : Colors.white;
    final appBarElevation = config.isSingla ? 0.0 : 2.0;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primaryColor,
        primary: config.primaryColor,
        secondary: config.primaryLightColor,
      ),
      primaryColor: config.primaryColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: appBarElevation,
        // Thin bottom divider for white AppBar (matches Dealer Check-In style)
        shadowColor: config.isSingla
            ? Colors.black.withOpacity(0.08)
            : Colors.black26,
        systemOverlayStyle: config.isSingla
            ? SystemUiOverlayStyle.dark   // dark status-bar icons on white bg
            : SystemUiOverlayStyle.light, // light icons on colored bg
        titleTextStyle: TextStyle(
          color: appBarFg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: appBarFg),
        actionsIconTheme: IconThemeData(color: appBarFg),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
      ),
      useMaterial3: false,
    );
  }
}
