import 'package:flutter/material.dart';
import 'flavor_config.dart';
import 'main.dart';

/// Entry point for the WATERMAN flavor.
/// Build: flutter build apk --flavor waterman -t lib/main_waterman.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(AppFlavor.waterman);
  runMyApp();
}
