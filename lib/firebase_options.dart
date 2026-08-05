// // lib/firebase_options.dart
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
//
// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       // TODO: Add Web Firebase configuration here if you need web support
//       throw UnsupportedError(
//         'DefaultFirebaseOptions have not been configured for web - '
//             'you can copy values from your Firebase web app settings.',
//       );
//     }
//
//     // Android configuration
//     return FirebaseOptions(
//       apiKey: 'AIzaSyDfPjQB_YBhGochjYUXoYoQWVlMX0X-GZE',
//       appId: '1:622997241417:android:2cf96de61898a1380b4998',
//       messagingSenderId: '622997241417',
//       projectId: 'watermaniattandanceapp',
//       storageBucket: 'watermaniattandanceapp.firebasestorage.app',
//     );
//
//     // iOS configuration
//     return FirebaseOptions(
//       apiKey: 'YOUR_IOS_API_KEY',
//       appId: 'YOUR_IOS_APP_ID',
//       messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
//       projectId: 'watermaniattandanceapp',
//       storageBucket: 'watermaniattandanceapp.firebasestorage.app',
//       iosBundleId: 'YOUR_IOS_BUNDLE_ID',
//       iosClientId: 'YOUR_IOS_CLIENT_ID',
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'flavor_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    final isSingla = FlavorConfig.isInitialized && FlavorConfig.instance.isSingla;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (isSingla) {
          return const FirebaseOptions(
            apiKey: 'AIzaSyAr5GJ-iYrAIWI2j9PDNrUy0Ei6VdRkc0Y',
            appId: '1:1075219872908:android:a2fc44fd435ecd0c1c0fa9',
            messagingSenderId: '1075219872908',
            projectId: 'single-motors',
            storageBucket: 'single-motors.firebasestorage.app',
          );
        }
        return const FirebaseOptions(
          apiKey: 'AIzaSyDfPjQB_YBhGochjYUXoYoQWVlMX0X-GZE',
          appId: '1:622997241417:android:2cf96de61898a1380b4998',
          messagingSenderId: '622997241417',
          projectId: 'watermaniattandanceapp',
          storageBucket: 'watermaniattandanceapp.firebasestorage.app',
        );

      case TargetPlatform.iOS:
        if (isSingla) {
          return const FirebaseOptions(
            apiKey: 'AIzaSyAr5GJ-iYrAIWI2j9PDNrUy0Ei6VdRkc0Y',
            appId: '1:1075219872908:ios:a2fc44fd435ecd0c1c0fa9',
            messagingSenderId: '1075219872908',
            projectId: 'single-motors',
            storageBucket: 'single-motors.firebasestorage.app',
            iosBundleId: 'com.i.singla.iattendanceapp',
          );
        }
        return const FirebaseOptions(
          apiKey: 'AIzaSyCFzA5eOM6uWNVp1qhg2KfCiT7inxd6vTw',
          appId: '622997241417:ios:dfd2bf7958ea418a0b4998',
          messagingSenderId: '622997241417',
          projectId: 'watermaniattandanceapp',
          storageBucket: 'watermaniattandanceapp.firebasestorage.app',
          iosBundleId: 'com.delta.watermaniattendance',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
