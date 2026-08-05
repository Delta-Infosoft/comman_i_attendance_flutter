import 'package:flutter/material.dart';
import 'flavor_config.dart';
import 'main.dart';

/// Entry point for the SINGLA flavor.
/// Build: flutter build apk --flavor singla -t lib/main_singla.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(AppFlavor.singla);
  runMyApp();
}
