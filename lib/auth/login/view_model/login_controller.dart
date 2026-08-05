import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart' hide FormData;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterman_iattandance/auth/login/model/user_valid_response_model.dart';
import 'package:dio/dio.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/auth/login/model/login_with_fcmid_response_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../flavor_config.dart';



class LoginController extends GetxController {
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController ipCtrl = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  var userResponse = Rxn<UserValidResponseModel>();
  String fcmId = '';

  @override
  void onInit() {
    super.onInit();
    fetchFCMID();
  } // var userResponse = Rxn<1>();



  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<UserValidResponseModel> userValidLogin(String ipAddress) async {
    isLoading.value = true;
    try {
      var data = FormData.fromMap({
        'MobileNo': phoneCtrl.text.trim(),
      });

      print('APIURL >>>>>>${ApiUrl.userValidLogin}');
      print('Request >>>>>>${data.fields}');

      var dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ));
      var response = await dio.request(
        '${ApiUrl.userValidLogin}',
        options: Options(
          method: 'POST',
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        print('userValidResponse>>>>>>>${response.data}');

        final parsed = UserValidResponseModel.fromJson(response.data);
        userResponse.value = parsed;

        if (parsed.result != null && parsed.result!.isNotEmpty) {
          final user = parsed.result!.first;

          // Save the actual typed mobile number since the API might return a GUID
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("REAL_MOBILE_NO", phoneCtrl.text.trim());

          await LocalDbController.to.saveUser(user);
        } else {
          print("API message: ${parsed.message}");
        }

        return parsed;
      } else {
        print(response.statusMessage);
        throw Exception('Failed to login');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFCMID() async {
    if (Platform.isIOS) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      print('🍎 APNS Token: $apns');

      // Skip if simulator / APNs not ready
      if (apns == null || apns.contains('fake')) {
        print('⚠️ APNs not ready or simulator – skipping FCM token');
        return;
      }
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await LocalDbController.to.saveFcm(token);
        print("✅ FCM Token: $token");
      } else {
        print("⚠️ FCM token is empty");
      }
    } catch (e) {
      print("⚠️ FCM token error: $e");
    }
  }

  // Future<void> fetchFCMID() async {
  //   final settings = await FirebaseMessaging.instance.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //
  //   if (settings.authorizationStatus != AuthorizationStatus.authorized) {
  //     print("Notification permission denied");
  //     return;
  //   }
  //
  //   if (Platform.isIOS) {
  //     final apns = await FirebaseMessaging.instance.getAPNSToken();
  //     print('🍎 APNS Token: $apns');
  //     if (apns == null || apns.contains('fake')) return;
  //   }
  //
  //   final token = await FirebaseMessaging.instance.getToken();
  //   if (token != null && token.isNotEmpty) {
  //     await LocalDbController.to.saveFcm(token);
  //     print("✅ FCM Token: $token");
  //   } else {
  //     print("❌ FCM token is empty");
  //   }
  // }

  // Future<void> fetchFCMID() async {
  //   try {
  //     // Request permissions
  //     final settings = await FirebaseMessaging.instance.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );
  //
  //     if (settings.authorizationStatus != AuthorizationStatus.authorized) {
  //       throw Exception("Notification permission denied");
  //     }
  //
  //     // iOS only: check APNs
  //     if (Platform.isIOS) {
  //       final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  //       print('🍎 APNS Token: $apnsToken');
  //
  //       if (apnsToken == null || apnsToken.contains('fake')) {
  //         print('⚠️ APNs not ready / simulator – skipping FCM token');
  //         return;
  //       }
  //     }
  //
  //     // Get FCM token
  //     String? fcmToken;
  //     do {
  //       fcmToken = await FirebaseMessaging.instance.getToken();
  //       if (fcmToken == null || fcmToken.isEmpty) {
  //         print('⚠️ Waiting for FCM token...');
  //         await Future.delayed(const Duration(seconds: 2));
  //       }
  //     } while (fcmToken == null || fcmToken.isEmpty);
  //
  //     // Save token
  //     await LocalDbController.to.saveFcm(fcmToken);
  //     print('✅ FCM Token saved: $fcmToken');
  //   } catch (e) {
  //     print('❌ FCM ERROR: $e');
  //   }
  // }

  Future<LoginWithFcmIdResponseModel> loginWithFcmId(String ipAddress) async {
    isLoading.value = true;
    try {
      final localDb = LocalDbController.to;

      // 🔐 Attempt to fetch FCM token
      if (localDb.fcmId.isEmpty) {
        await fetchFCMID();
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Get the real mobile number instead of the one from the API which might be a GUID
      final userName = prefs.getString("REAL_MOBILE_NO") ?? localDb.mobileNo;
      
      var imei = localDb.imeiCode;
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
          if (imei.isNotEmpty) {
            await localDb.updateImeiCode(imei);
          }
        } catch (e) {
          print('Error fetching fallback device ID in loginWithFcmId: $e');
        }
      }
      final fcmId = localDb.fcmId;

      // 🔴 Validate required fields (FCM is now optional)
      if (userName.isEmpty || imei.isEmpty) {
        throw Exception('Missing login parameters');
      }

      final data = FormData.fromMap({
        'UserName': userName,
        'IMEI': imei,
        // ✅ Only send FCM if available
        if (fcmId.isNotEmpty) 'FCMId': fcmId,
      });

      print('login Request >>>>>> ${data.fields}');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final response = await dio.post(
        '${ApiUrl.loginWithFcmId}',
        data: data,
      );

      if (response.statusCode == 200) {
        print('Login Response >>>>>> ${response.data}');

        final model =
        LoginWithFcmIdResponseModel.fromJson(response.data);

        final insertedByUserId =
            model.result?.first.insertedByUserId ?? "";

        // ✅ Save empId for Background Service
        final prefs = await SharedPreferences.getInstance();
        // await prefs.setString("BG_EMP_ID", insertedByUserId);
        await prefs.setString("BG_MOBILE_NO", userName);

        print("💾 BG_EMP_ID Saved → $insertedByUserId");

        FlutterBackgroundService().invoke('updateMobileNo', {
          'mobileNo': userName,
        });

        String cleanIp = ipAddress.trim();
        if (cleanIp.startsWith('http://')) {
          cleanIp = cleanIp.substring(7);
        } else if (cleanIp.startsWith('https://')) {
          cleanIp = cleanIp.substring(8);
        }
        final slashIndex = cleanIp.indexOf('/');
        if (slashIndex != -1) {
          cleanIp = cleanIp.substring(0, slashIndex);
        }
        cleanIp = cleanIp.trim();

        // Save IP
        localDb.storage.write('IP_Address', cleanIp);

        await LocalDbController.setIP(cleanIp);

        // ✅ ONLY place to mark login success
        localDb.setLoggedIn(true);

        await LocalDbController.setIsLoggedIn(true);

        final String apiFolder = FlavorConfig.instance.isSingla
            ? "DeltaAttendanceAPI"
            : "DeltaAttendanceAPIWIPL";
        final String fullBaseUrl =
            "http://$cleanIp/$apiFolder/";

        await LocalDbController.setBaseApiUrl(fullBaseUrl);

        FlutterBackgroundService().invoke('updateBaseUrl', {
          'baseUrl': fullBaseUrl,
        });
        return LoginWithFcmIdResponseModel.fromJson(response.data);
      }

      throw Exception('Login with FCM failed');
    } catch (e) {
      print("loginWithFcmId ERROR: $e");
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Future<LoginWithFcmIdResponseModel> loginWithFcmId(String ipAddress) async {
  //   try {
  //     final localDb = LocalDbController.to;
  //
  //     // 🔐 Ensure FCM exists
  //     if (localDb.fcmId.isEmpty) {
  //       await fetchFCMID();
  //     }
  //
  //     final userName = localDb.mobileNo;
  //     final imei = localDb.imeiCode;
  //     final fcmId = localDb.fcmId;
  //
  //     // 🔴 Validate required fields
  //     if (userName.isEmpty || imei.isEmpty || fcmId.isEmpty) {
  //       throw Exception('Missing login parameters');
  //     }
  //
  //     final data = FormData.fromMap({
  //       'UserName': userName,
  //       'IMEI': imei,
  //       'FCMId': fcmId,
  //     });
  //
  //     print('login Request >>>>>> ${data.fields}');
  //
  //     final dio = Dio();
  //     final response = await dio.post(
  //       'http://$ipAddress${ApiUrl.loginWithFcmId}',
  //       data: data,
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print('Login Response >>>>>> ${response.data}');
  //
  //       // Save IP
  //       localDb.storage.write('IP_Address', ipAddress);
  //
  //       // ✅ ONLY place to mark login success
  //       localDb.setLoggedIn(true);
  //
  //       return LoginWithFcmIdResponseModel.fromJson(response.data);
  //     }
  //
  //     throw Exception('Login with FCM failed');
  //   } catch (e) {
  //     print("loginWithFcmId ERROR: $e");
  //     rethrow;
  //   }
  // }

  // Future<LoginWithFcmIdResponseModel> loginWithFcmId(String ipAddress) async {
  //   // Wait for all saved fields
  //   final prefs = await SharedPreferences.getInstance();
  //   final userName = prefs.getString('MobileNo') ?? '';
  //   final imei = prefs.getString('IMEICode') ?? '';
  //   // final fcmId = prefs.getString('FCMId') ?? '';
  //
  //   var data = FormData.fromMap({
  //     'UserName': userName,
  //     'IMEI': imei,
  //     'FCMId': fcmId,
  //   });
  //
  //   print('login Request>>>>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     'http://${ipAddress}${ApiUrl.loginWithFcmId}',
  //     options: Options(method: 'POST'),
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200) {
  //     print('Login Response>>>>>>>${response.data}');
  //     await prefs.setString('IP_Address', ipAddress);
  //     await prefs.setBool('isLoggedIn', true);
  //     await prefs.setString('MobileNo', userName);
  //     await prefs.setString('IMEICode', imei);
  //
  //     return LoginWithFcmIdResponseModel.fromJson(response.data);
  //   } else {
  //     print('Error>>>>>>${response.statusMessage}');
  //     throw Exception('Login with FCM failed');
  //   }
  // }

  // Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isLoggedIn', false);
  //   await prefs.remove('MobileNo');
  //   await prefs.remove('IMEICode');
  //   Get.offAll(() => LoginScreen());
  // }

  // Future<LoginWithFcmIdResponseModel> loginWithFcmId(String ipAddress) async {
  //   var data = FormData.fromMap({
  //     'UserName': phoneCtrl.text.toString(),
  //     'IMEI': LocalDb().getIMEICode(),
  //     'FCMId': LocalDb().getFCMId(),
  //   });
  //
  //   print('login Request>>>>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     'http://${ipAddress}${ApiUrl.loginWithFcmId}',
  //     options: Options(
  //       method: 'POST',
  //     ),
  //     data: data,
  //   );
  //   print('DATAA>>>>>>${response.data}');
  //
  //   if (response.statusCode == 200) {
  //     print('Login Response>>>>>>>${response.data}');
  //
  //     return LoginWithFcmIdResponseModel.fromJson(response.data);
  //   }
  //   else {
  //     print('Eroror>>>>>>${response.statusMessage}');
  //     print(response.statusMessage);
  //   }
  //   throw Exception();
  // }

  // Future<UserValidResponseModel> userValidLogin(String ipAddress) async {
  //   var data = FormData.fromMap({
  //     'MobileNo': phoneCtrl.text.trim(),
  //   });
  //
  //   print('Request >>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     'http://${ipAddress}${ApiUrl.userValidLogin}',
  //     options: Options(
  //       method: 'POST',
  //     ),
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200) {
  //     print('userValidResponse>>>>>>>${response.data}');
  //
  //     final parsed = UserValidResponseModel.fromJson(response.data);
  //
  //     // Save individual fields in SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     if (parsed.result != null && parsed.result!.isNotEmpty) {
  //       final user = parsed.result!.first;
  //
  //       await prefs.setString('AutoId', user.autoId ?? '');
  //       await prefs.setString('MobileNo', user.mobileNo ?? '');
  //       await prefs.setString('IMEICode', user.imeiCode ?? '');
  //       await prefs.setString('IsApproved', user.isApproved ?? '');
  //       await prefs.setString('ApprovedDateTime', user.approvedDateTime ?? '');
  //       await prefs.setString('FCMId', user.fcmId ?? '');
  //       await prefs.setString('UsersName', user.usersName ?? '');
  //       await prefs.setString('CompanyName', user.companyName ?? '');
  //       await prefs.setString('EmpID', user.empId ?? '');
  //       await prefs.setString('DepartmentId', user.departmentId ?? '');
  //       // Add more fields as needed...
  //     }
  //
  //     userResponse.value = parsed;
  //     return parsed;
  //   } else {
  //     print(response.statusMessage);
  //   }
  //
  //   throw Exception('Failed to login');
  // }
  //
  // Future<UserValidResponseModel>userValidLogin(String ipAddress) async {
  //   var data = FormData.fromMap({
  //     'MobileNo': phoneCtrl.text.trim(),
  //   });
  //
  //   print('Request >>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     'http://${ipAddress}${ApiUrl.userValidLogin}',
  //     options: Options(
  //       method: 'POST',
  //     ),
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200) {
  //
  //     print('userValidResponse>>>>>>>${response}');
  //
  //     final parsed = UserValidResponseModel.fromJson(response.data);
  //     userResponse.value = parsed;
  //     return parsed;
  //   }
  //   else {
  //     print(response.statusMessage);
  //   }
  //   throw Exception();
  // }

  Future<void> login() async {
    isLoading.value = true;

    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;
  }

  @override
  void onClose() {
    // Dispose of the TextEditingControllers when the controller is closed
    // phoneCtrl.dispose();
    // ipCtrl.dispose();
    super.onClose();
  }
}
