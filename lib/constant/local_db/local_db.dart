import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterman_iattandance/auth/login/model/user_valid_response_model.dart';


class LocalDbController extends GetxController {
  static LocalDbController get to => Get.find();

  static late SharedPreferences _prefsInstance;

  static const String _lastBatteryKey = "LAST_BATTERY_STATUS";
  static const String _lastStartRouteKey = "last_start_route_time";
  static const String _isBgServiceRunningKey = "isBgServiceRunning";

  static const String _empIdBgKey = "BG_EMP_ID";
  static const String _baseUrlKey = "BASE_URL";
  static const String _isLoggedInBgKey = "IS_LOGGED_IN_BG";

  final GetStorage storage = GetStorage();

  // Reactive state
  RxBool isLoggedIn = false.obs;
  RxMap<String, String> userData = <String, String>{}.obs;

  /* ================= INIT (VERY IMPORTANT) ================= */

  static Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
  }

  static Future<void> setAutoId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoId', id);
  }

  Future<String> get autoId2 async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('autoId') ?? '';
  }

  static Future<void> setBaseApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('BASE_API_URL', url);
  }

  static String? getBaseApiUrl() {
    return _prefsInstance.getString('BASE_API_URL');
  }



  /* ================= BATTERY CACHE ================= */

  static Future<void> setUserId(String empId) async {
    await _prefsInstance.setString(_empIdBgKey, empId);
  }

  static String? getUserId() {
    return _prefsInstance.getString(_empIdBgKey);
  }


  static Future<void> setIsLoggedIn(bool val) async {
    await _prefsInstance.setBool(_isLoggedInBgKey, val);
  }

  static bool getIsLoggedIn() {
    return _prefsInstance.getBool(_isLoggedInBgKey) ?? false;
  }


  static Future<void> setIP(String baseUrl) async {
    await _prefsInstance.setString(_baseUrlKey, baseUrl);
  }

  static String getIP() {
    return _prefsInstance.getString(_baseUrlKey) ?? "";
  }

  static Future<void> setLastBattery(String value) async {
    await _prefsInstance.setString(_lastBatteryKey, value);
  }

  static String? getLastBattery() {
    return _prefsInstance.getString(_lastBatteryKey);
  }

  /* ================= START ROUTE TIMER ================= */

  static Future<DateTime?> getLastStartRouteTime() async {
    final value = _prefsInstance.getString(_lastStartRouteKey);
    return value == null ? null : DateTime.parse(value);
  }

  static Future<void> setLastStartRouteTime(DateTime time) async {
    await _prefsInstance.setString(
      _lastStartRouteKey,
      time.toIso8601String(),
    );
  }

  /* ================= BG SERVICE FLAG ================= */

  static Future<bool> setIsBgServiceRunning(bool val) async {
    return await _prefsInstance.setBool(
      _isBgServiceRunningKey,
      val,
    );
  }

  static bool getIsBgServiceRunning() {
    return _prefsInstance.getBool(
      _isBgServiceRunningKey,
    ) ??
        false;
  }

  /* ================= STORAGE KEYS ================= */
  static const String autoIdKey2 = 'AutoId2';
  static const String autoIdKey = 'AutoId';
  static const String mobileNoKey = 'MobileNo';
  static const String imeiCodeKey = 'IMEICode';
  static const String isApprovedKey = 'IsApproved';
  static const String approvedDateTimeKey = 'ApprovedDateTime';
  static const String fcmIdKey = 'FCMId';
  static const String usersNameKey = 'UsersName';
  static const String companyNameKey = 'CompanyName';
  static const String empIdKey = 'EmpID';
  static const String departmentIdKey = 'DepartmentId';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String insertedbyUserIdkey = 'InsertedbyUserId';
  static const String updatedbyUserId = 'UpdatedbyUserId';

  /* ================= SAVE METHODS ================= */

  Future<void> saveUser(Result user) async {
    await storage.write(autoIdKey, user.autoId ?? '');
    await storage.write(insertedbyUserIdkey, user.insertedByUserId ?? '');
    await storage.write(updatedbyUserId, user.lastUpdatedByUserId ?? '');
    await storage.write(mobileNoKey, user.mobileNo ?? '');

    String imei = user.imeiCode ?? '';
    if (imei.isEmpty) {
      try {
        final di = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final info = await di.androidInfo;
          imei = info.id;
        } else if (Platform.isIOS) {
          final info = await di.iosInfo;
          imei = info.identifierForVendor ?? '';
        }
      } catch (e) {
        print('Error fetching fallback device ID in saveUser: $e');
      }
    }
    await storage.write(imeiCodeKey, imei);

    await storage.write(isApprovedKey, user.isApproved ?? '');
    await storage.write(approvedDateTimeKey, user.approvedDateTime ?? '');
    await storage.write(usersNameKey, user.usersName ?? '');
    await storage.write(companyNameKey, user.companyName ?? '');
    await storage.write(empIdKey, user.empId ?? '');
    await storage.write(departmentIdKey, user.departmentId ?? '');

    _refreshReactiveData();
  }

  Future<void> updateImeiCode(String imei) async {
    await storage.write(imeiCodeKey, imei);
    _refreshReactiveData();
  }

  Future<void> saveFcm(String token) async {
    await storage.write(fcmIdKey, token);
    _refreshReactiveData();
  }

  void setLoggedIn(bool value) {
    isLoggedIn.value = value;
    storage.write(isLoggedInKey, value);
  }

  /* ================= CLEAR ================= */

  Future<void> clearUser() async {
    await storage.erase();
    userData.clear();
    isLoggedIn.value = false;
    await setIsLoggedIn(false);
  }

  /* ================= GETTERS ================= */

  String get fcmId => storage.read(fcmIdKey) ?? '';
  String get mobileNo => storage.read(mobileNoKey) ?? '';
  String get imeiCode => storage.read(imeiCodeKey) ?? '';
  String get usersName => storage.read(usersNameKey) ?? '';
  String get empId => storage.read(empIdKey)?.toString() ?? '';
  String get autoId => storage.read(autoIdKey)?.toString() ?? '';
  // String get autoId2 => storage.read(autoId2)?.toString() ?? '';
  String get companyName => storage.read(companyNameKey) ?? '';
  String get departmentId => storage.read(departmentIdKey) ?? '';
  bool get loggedIn => storage.read(isLoggedInKey) ?? false;
  String get insertedByUserId =>
      storage.read(insertedbyUserIdkey)?.toString() ?? '';
  String get updatedByUserId =>
      storage.read(updatedbyUserId)?.toString() ?? '';

  /* ================= INTERNAL ================= */

  void _refreshReactiveData() {
    userData.value = {
      'AutoId': autoId,
      'MobileNo': mobileNo,
      'IMEICode': imeiCode,
      'IsApproved': storage.read(isApprovedKey) ?? '',
      'ApprovedDateTime':
      storage.read(approvedDateTimeKey) ?? '',
      'FCMId': fcmId,
      'UsersName': usersName,
      'CompanyName': companyName,
      'EmpID': empId,
      'DepartmentId': departmentId,
      "InsertedByUserId": insertedByUserId,
      "LastUpdatedByUserId": updatedByUserId,
    };
  }

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = loggedIn;
    _refreshReactiveData();
  }
}


// class LocalDbController extends GetxController {
//   static LocalDbController get to => Get.find();
//   static late SharedPreferences _prefsInstance;
//
//
//
//   static const String _lastBatteryKey = "LAST_BATTERY_STATUS";
//
//   final GetStorage storage = GetStorage();
//
//   // Reactive state
//   RxBool isLoggedIn = false.obs;
//   RxMap<String, String> userData = <String, String>{}.obs;
//
//   static Future<void> setLastBattery(String value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_lastBatteryKey, value);
//   }
//
//   static Future<String?> getLastBattery() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_lastBatteryKey);
//   }
//
//   static Future<DateTime?> getLastStartRouteTime() async  {
//     final prefs = await SharedPreferences.getInstance();
//     final value = prefs.getString("last_start_route_time");
//     return value == null ? null : DateTime.parse(value);
//   }
//
//   static setLastStartRouteTime(DateTime time) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(
//         "last_start_route_time", time.toIso8601String());
//   }
//
//   static Future<bool> setIsBgServiceRunning(bool val) async {
//     return await _prefsInstance.setBool("isBgServiceRunning", val);
//   }
//
//   static bool getIsBgServiceRunning() {
//     return _prefsInstance.getBool("isBgServiceRunning") ?? false;
//   }
//
//
//   // Storage keys
//   static const String autoIdKey = 'AutoId';
//   static const String mobileNoKey = 'MobileNo';
//   static const String imeiCodeKey = 'IMEICode';
//   static const String isApprovedKey = 'IsApproved';
//   static const String approvedDateTimeKey = 'ApprovedDateTime';
//   static const String fcmIdKey = 'FCMId';
//   static const String usersNameKey = 'UsersName';
//   static const String companyNameKey = 'CompanyName';
//   static const String empIdKey = 'EmpID';
//   static const String departmentIdKey = 'DepartmentId';
//   static const String isLoggedInKey = 'isLoggedIn';
//   static const String insertedbyUserIdkey = 'InsertedbyUserId';
//   static const String updatedbyUserId = 'UpdatedbyUserId';
//
//   /* ================= SAVE METHODS ================= */
//
//   /// Save user after userValidLogin
//   Future<void> saveUser(Result user) async {
//     await storage.write(autoIdKey, user.autoId ?? '');
//     await storage.write(insertedbyUserIdkey, user.insertedByUserId ?? '');
//     await storage.write(updatedbyUserId, user.lastUpdatedByUserId ?? '');
//     await storage.write(mobileNoKey, user.mobileNo ?? '');
//     await storage.write(imeiCodeKey, user.imeiCode ?? '');
//     await storage.write(isApprovedKey, user.isApproved ?? '');
//     await storage.write(approvedDateTimeKey, user.approvedDateTime ?? '');
//     await storage.write(usersNameKey, user.usersName ?? '');
//     await storage.write(companyNameKey, user.companyName ?? '');
//     await storage.write(empIdKey, user.empId ?? '');
//     await storage.write(departmentIdKey, user.departmentId ?? '');
//
//     _refreshReactiveData();
//   }
//
//   /// Save FCM token ONLY from Firebase
//   Future<void> saveFcm(String token) async {
//     await storage.write(fcmIdKey, token);
//     _refreshReactiveData();
//   }
//
//   /// Call ONLY after loginWithFcmId success
//   void setLoggedIn(bool value) {
//     isLoggedIn.value = value;
//     storage.write(isLoggedInKey, value);
//   }
//
//   /* ================= CLEAR ================= */
//
//   Future<void> clearUser() async {
//     await storage.erase();
//     userData.clear();
//     isLoggedIn.value = false;
//   }
//
//   /* ================= GETTERS ================= */
//
//   String get fcmId => storage.read(fcmIdKey) ?? '';
//   String get mobileNo => storage.read(mobileNoKey) ?? '';
//   String get imeiCode => storage.read(imeiCodeKey) ?? '';
//   String get usersName => storage.read(usersNameKey) ?? '';
//   String get empId => storage.read(empIdKey) ?? '';
//   String get autoId => storage.read(autoIdKey) ?? '';
//   String get companyName => storage.read(companyNameKey) ?? '';
//   String get departmentId => storage.read(departmentIdKey) ?? '';
//   bool get loggedIn => storage.read(isLoggedInKey) ?? false;
//   String get insertedByUserId => storage.read(insertedbyUserIdkey) ?? '';
//   String get updatedByUserId => storage.read(updatedbyUserId) ?? '';
//   /* ================= INTERNAL ================= */
//
//   void _refreshReactiveData() {
//     userData.value = {
//       'AutoId': autoId,
//       'MobileNo': mobileNo,
//       'IMEICode': imeiCode,
//       'IsApproved': storage.read(isApprovedKey) ?? '',
//       'ApprovedDateTime': storage.read(approvedDateTimeKey) ?? '',
//       'FCMId': fcmId,
//       'UsersName': usersName,
//       'CompanyName': companyName,
//       'EmpID': empId,
//       'DepartmentId': departmentId,
//       "InsertedByUserId": insertedByUserId,
//       "LastUpdatedByUserId": updatedByUserId,
//     };
//   }
//
//   @override
//   void onInit() {
//     super.onInit();
//     isLoggedIn.value = loggedIn;
//     _refreshReactiveData();
//   }
// }



// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:waterman_iattandance/auth/login/model/user_valid_response_model.dart';

// class LocalDb {
//   // Save individual fields from Result
//   Future<void> saveUser(Result user) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('AutoId', user.autoId ?? '');
//     await prefs.setString('MobileNo', user.mobileNo ?? '');
//     await prefs.setString('IMEICode', user.imeiCode ?? '');
//     await prefs.setString('IsApproved', user.isApproved ?? '');
//     await prefs.setString('ApprovedDateTime', user.approvedDateTime ?? '');
//     await prefs.setString('FCMId', user.fcmId ?? '');
//     await prefs.setString('UsersName', user.usersName ?? '');
//     await prefs.setString('CompanyName', user.companyName ?? '');
//     await prefs.setString('EmpID', user.empId ?? '');
//     await prefs.setString('DepartmentId', user.departmentId ?? '');
//     // Add more fields as needed
//   }

//   // Getters
//   Future<String> getFCMId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('FCMId') ?? '';
//   }

//   Future<String> getMobileNo() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('MobileNo') ?? '';
//   }

//   Future<String> getUsersName() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('UsersName') ?? '';
//   }

//   Future<String> getIMEICode() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('IMEICode') ?? '';
//   }

//   Future<String> getEmpID() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('EmpID') ?? '';
//   }

//   // Clear all saved user data
//   Future<void> clearUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('AutoId');
//     await prefs.remove('MobileNo');
//     await prefs.remove('IMEICode');
//     await prefs.remove('IsApproved');
//     await prefs.remove('ApprovedDateTime');
//     await prefs.remove('FCMId');
//     await prefs.remove('UsersName');
//     await prefs.remove('CompanyName');
//     await prefs.remove('EmpID');
//     await prefs.remove('DepartmentId');
//     await prefs.remove('isLoggedIn');
//     // Add more fields if saved
//   }
// }
