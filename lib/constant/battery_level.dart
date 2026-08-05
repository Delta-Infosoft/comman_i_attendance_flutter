// import 'package:flutter/services.dart';
//
// class NativeBattery {
//   static const MethodChannel _channel =
//   MethodChannel('mytime/native_battery');
//
//   static Future<String> getBatteryStatus() async {
//     try {
//       final result = await _channel.invokeMethod<Map>('getBatteryStatus');
//       if (result == null) return "";
//
//       final level = result['level'];
//       final state = result['state'];
//
//       if (level == null) return "";
//       return "$state ($level%)";
//     } catch (_) {
//       return "";
//     }
//   }
// }

import 'package:flutter/services.dart';

class NativeBattery {
  static const MethodChannel _channel =
  MethodChannel('mytime/native_battery');

  static Future<String> getBatteryStatus() async {
    try {
      final result =
      await _channel.invokeMethod<Map>('getBatteryStatus');

      if (result == null) return "";

      final int level = result['level'] ?? -1;
      final String state = result['state'] ?? "";

      if (level < 0) return "";

      return "$state ($level%)";
    } catch (e) {
      // VERY IMPORTANT: never throw in background isolate
      return "";
    }
  }
}
