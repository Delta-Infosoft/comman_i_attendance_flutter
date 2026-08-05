// import UIKit
// import Flutter
// import FirebaseCore
// import FirebaseMessaging
// import GoogleMaps
// import CoreLocation
// import webview_flutter_wkwebview
//
// @main
// @objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
//
//     let locationManager = CLLocationManager()
//
//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//
//         FirebaseApp.configure()
//         GeneratedPluginRegistrant.register(with: self)
//
// //        if #available(iOS 14.0, *) {
// //            WKWebView.appearance().allowsBackForwardNavigationGestures = true
// //          }
//
//
//         // --------------------------------------
//         // 🔥 Background Location Configuration
//         // --------------------------------------
//         locationManager.delegate = self
//         locationManager.requestAlwaysAuthorization()
//         locationManager.allowsBackgroundLocationUpdates = true
//         locationManager.pausesLocationUpdatesAutomatically = false
//         locationManager.showsBackgroundLocationIndicator = true
//         locationManager.startUpdatingLocation()
//
//         // --------------------------------------
//         // 🔋 Battery Method Channel
//         // --------------------------------------
//         UIDevice.current.isBatteryMonitoringEnabled = true
//         let controller = window?.rootViewController as! FlutterViewController
//
//         let batteryChannel = FlutterMethodChannel(
//             name: "mytime/native_battery",
//             binaryMessenger: controller.binaryMessenger
//         )
//
//         batteryChannel.setMethodCallHandler { call, result in
//             if call.method == "getBatteryStatus" {
//                 UIDevice.current.isBatteryMonitoringEnabled = true
//                 let level = UIDevice.current.batteryLevel
//                 let state = UIDevice.current.batteryState
//
//                 if level < 0 {
//                     result(nil)
//                     return
//                 }
//
//                 let levelPercent = Int(level * 100)
//                 let stateString: String
//                 switch state {
//                 case .charging: stateString = "charging"
//                 case .full: stateString = "full"
//                 case .unplugged: stateString = "discharging"
//                 default: stateString = "unknown"
//                 }
//
//                 result([
//                     "level": levelPercent,
//                     "state": stateString
//                 ])
//             } else {
//                 result(FlutterMethodNotImplemented)
//             }
//         }
//
//         // Register for remote notifications
//         if #available(iOS 10.0, *) {
//             UNUserNotificationCenter.current().delegate = self
//         }
//         application.registerForRemoteNotifications()
//
//         GMSServices.provideAPIKey("AIzaSyAW9ruVcdwyJekrngeWRQ9Z4On_0XCMLy0")
//
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
//
//     // --------------------------------------
//     // 🔥 Native Background Location Callback
//     // --------------------------------------
//     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//         guard let loc = locations.last else { return }
//         print("📍 Native BG Location → \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
//     }
//
//     // Optional: receive APNs token
//     override func application(_ application: UIApplication,
//                               didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//         Messaging.messaging().apnsToken = deviceToken
//         super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
//     }
// }


import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import GoogleMaps
import CoreLocation
import webview_flutter_wkwebview
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

//        if #available(iOS 14.0, *) {
//            WKWebView.appearance().allowsBackForwardNavigationGestures = true
//          }

        // --------------------------------------
        // 🐕 Background Task Watchdog
        // Identifier must match _kWmTaskName in the Dart watchdog
        // ('waterman_service_watchdog').
        // --------------------------------------
        WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "waterman_service_watchdog")

        // --------------------------------------
        // 🔥 Background Location Configuration
        // --------------------------------------
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()

        // --------------------------------------
        // 🔋 Battery Method Channel
        // --------------------------------------
        UIDevice.current.isBatteryMonitoringEnabled = true
        let controller = window?.rootViewController as! FlutterViewController

        let batteryChannel = FlutterMethodChannel(
            name: "mytime/native_battery",
            binaryMessenger: controller.binaryMessenger
        )

        batteryChannel.setMethodCallHandler { call, result in
            if call.method == "getBatteryStatus" {
                UIDevice.current.isBatteryMonitoringEnabled = true
                let level = UIDevice.current.batteryLevel
                let state = UIDevice.current.batteryState

                if level < 0 {
                    result(nil)
                    return
                }

                let levelPercent = Int(level * 100)
                let stateString: String
                switch state {
                case .charging: stateString = "charging"
                case .full: stateString = "full"
                case .unplugged: stateString = "discharging"
                default: stateString = "unknown"
                }

                result([
                    "level": levelPercent,
                    "state": stateString
                ])
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // Register for remote notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        application.registerForRemoteNotifications()

        GMSServices.provideAPIKey("AIzaSyAW9ruVcdwyJekrngeWRQ9Z4On_0XCMLy0")

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
//         print("📍 Native BG Location → \(loc.coordinate.latitude), \(loc.coordinate.longitude)")

        // Keep updates alive — mirrors MyTime's behavior of re-requesting
        // continuous updates after each fix, which helps some OEMs from
        // silently pausing location delivery in the background.
        locationManager.startUpdatingLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedAlways:
            print("✅ Always location granted")
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        case .authorizedWhenInUse:
            print("⚠️ Only when in use granted")
        case .denied:
            print("❌ Location denied")
        default:
            break
        }
    }

    // Optional: receive APNs token
    override func application(_ application: UIApplication,
                              didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}
