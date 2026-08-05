import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/model/attandance_in_out_response_model.dart';
import 'package:waterman_iattandance/screens/check_in_now_screen/model/attandance_textlist_responsemodel.dart';
import 'package:waterman_iattandance/service/background_location_service.dart';

import '../../home/view_model/home_screen_controller.dart';
import '../model/get_emp_coff_date_response_model.dart';

class CheckInNowScreenController extends GetxController {
  var isLoading = false.obs;
  List<DateTime> availableCoffDates = [];
  bool isLoadingCoffDates = false;

  Future<AttandanceTextListResponseModel> attandanceStatusTextList() async {
    var data = FormData.fromMap({'Type': 'AttendanceStatus'});

    var dio = Dio();
    var response = await dio.request(
      //'http://${'103.113.32.126'}${ApiUrl.attandanceTextList}',
      '${ApiUrl.attandanceTextList}',
      options: Options(
        method: 'GET',
      ),
      data: data,
    );

    if (response.statusCode == 200) {
      print('Attandance Text List Response>>>>>>>${response.data}');
      return AttandanceTextListResponseModel.fromJson(response.data);
    } else {
      print(response.statusMessage);
    }
    throw Exception();
  }

  String getStatusCode(String status) {
    // Check if status contains '-' (format: CODE-Text)
    if (status.contains('-')) {
      return status.split('-')[0]; // Take the first part as code
    }

    // fallback mapping in case the format is different
    switch (status.toUpperCase()) {
      case 'ABSENT':
        return 'A';
      case 'HALF DAY PRESENT':
        return 'HF';
      case 'WEEKLY OFF PRESENT':
        return 'WOP';
      case 'CASUAL LEAVE OFF':
        return 'COFF';
      case 'FULL DAY PRESENT':
        return 'P';
      case 'WEEKLY OFF HALF DAY PRESENT':
        return 'WOHF';
      default:
        return 'A'; // default fallback
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }


  Future<void> getEMPCOFFDate(BuildContext context) async {
    try {
      isLoadingCoffDates = true;
      availableCoffDates.clear();

      var data = FormData.fromMap({
        'EmpId': LocalDbController.to.empId ?? '',
        'Date': DateTime.now().toString().split(' ')[0],
      });

      var response = await Dio().post(
        ApiUrl.GetEmpCoffDate,
        data: data,
      );

      if (response.statusCode == 200) {
        final json = response.data;

        if (json["status"] == "200") {
          final model = GetEmpCoffDateResponseModel.fromJson(json);

          availableCoffDates = model.result
              ?.map((e) => _parseApiDate(e.date ?? ''))
              .whereType<DateTime>()
              .toList() ??
              [];
        } else {
          availableCoffDates.clear();
          ScaffoldMessenger.of(context)
              .hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text(
                    json["message"] ?? 'No COFF dates available'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                showCloseIcon: true,
                margin: EdgeInsets.all(12),
                duration: Duration(seconds: 2),
              ));

        }
      }
    } catch (e) {
      print(e);
    } finally {
      isLoadingCoffDates = false;
      update(); // if GetxController
    }
  }

  DateTime? _parseApiDate(String value) {
    try {
      return DateFormat("dd-MMM-yyyy hh:mm:ss a").parse(value);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> startrouteApi({
    required String fullUrl,
    required String mobileNo,
    required String lat,
    required String long,
    required String batterystatus,
    required String gpsstatus,
    required String netstatus,
    required String appversion,
    required String insertedon,
    required String modelname,
    required String androidversion,
  }) async {
    final dio = Dio();

    final formData = FormData.fromMap({
      "MobileNo": mobileNo,
      "Lat": lat,
      "Long": long,
      "BattryStatus": batterystatus,
      "GPSStatus": gpsstatus,
      "NetStatus": netstatus,
      "AppVersion": appversion,
      "InsertedOn": insertedon,
      "ModelName": modelname,
      "AndroidVersion": androidversion,
    });

    final response = await dio.post(
      fullUrl,
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
      ),
    );

    final data = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    if (data['status'] == "200") {
      print("✅ Start Route Response >>>>> $data");
    } else {
      print("❌ Start Route Error Response >>>>> $data");
    }

    return Map<String, dynamic>.from(data);
  }




  // Future<AttandanceInOutResponseModel> attandanceInOutSubmit(
  //     String selectedStatusText,
  //     String remark,
  //     ) async {
  //
  //   final mobile = LocalDbController.to.mobileNo;
  //   final now = DateTime.now();
  //   final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
  //
  //   // Get status code
  //   String statusCode = getStatusCode(selectedStatusText);
  //
  //   // Ensure remark length
  //   remark = remark.isEmpty
  //       ? "."
  //       : (remark.length > 100 ? remark.substring(0, 100) : remark);
  //
  //   // ✅ Get current GPS location
  //   Position position = await _getCurrentPosition();
  //
  //   double latitude = position.latitude;
  //   double longitude = position.longitude;
  //
  //   var data = FormData.fromMap({
  //     'MobileNo': mobile,
  //     'Status': statusCode,
  //     'BattryStatus': 100.0,
  //     'InTime': formattedDate,
  //     'Remarks': remark,
  //     'OutTime': "",
  //     'Long': longitude,
  //     'Lat': latitude,
  //     'NetStatus': true,
  //     'GPSStatus': true,
  //   });
  //
  //   print('Attandance In Out Request >>>>>> ${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.post(
  //     ApiUrl.attandanceInOut,
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     print('Attandance In Out Response>>>>>>> ${response.data}');
  //     return AttandanceInOutResponseModel.fromJson(response.data);
  //   }
  //
  //   throw Exception("Attendance submit failed");
  // }

  Future<AttandanceInOutResponseModel> attandanceInOutSubmit(
      String selectedStatusText,
      String remark,
      String coffDt,
      ) async {
    final mobile = LocalDbController.to.mobileNo;
    final now = DateTime.now();
    final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);

    // Get status code
    String statusCode = getStatusCode(selectedStatusText);

    // Ensure remark length
    remark = remark.isEmpty
        ? "."
        : (remark.length > 100 ? remark.substring(0, 100) : remark);


    Position position;
    bool gpsStatus = false;
    try {
      position = await _getCurrentPosition();
      gpsStatus = true;
    } catch (_) {
      // Fallback if GPS fails
      position = Position(
          longitude: 0.0,
          latitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
      gpsStatus = false;
    }

    // 📱 Gather missing metadata internally
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await getDeviceAndStatusInfo(); // This helper is in background_location_service.dart or similar available via imports
    
    var connectivityResult = await Connectivity().checkConnectivity();
    bool netStatus = connectivityResult != ConnectivityResult.none;

    final battery = Battery();
    String batteryStatus = '0%';
    try {
      int batteryLevel = await battery.batteryLevel;
      batteryStatus = "$batteryLevel%";
    } catch (e) {
      debugPrint("Failed to get battery level: $e");
      batteryStatus = (await LocalDbController.getLastBattery()) ?? '0%';
      if (!batteryStatus.contains('%')) batteryStatus = "$batteryStatus%";
    }

    final insertedOnDate = DateFormat("dd-MMM-yyyy hh:mm a").format(now);

    var data = FormData.fromMap({
      'MobileNo': mobile.toString(),
      'Status': statusCode,
      'BattryStatus': batteryStatus,
      'InTime': formattedDate,
      'Remarks': remark,
      'OutTime': "",
      'Long': position.longitude.toString(),
      'Lat': position.latitude.toString(),
      'CoffDate': coffDt,
      'NetStatus': netStatus ? "true" : "false",
      'GPSStatus': gpsStatus ? "true" : "false",
      'ModelName': (deviceInfo["modelname"] ?? "").toString(),
      'AndroidVersion': (deviceInfo["androidversion"] ?? "").toString(),
      'AppVersion': packageInfo.version.toString(),
      'InsertedOn': insertedOnDate,
    });

    print('Attendance In Out Request >>>>>> ${data.fields}');

    var dio = Dio();
    var response = await dio.post(
      ApiUrl.attandanceInOut,
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Attendance In Out Response>>>>>>> ${response.data}');
      return AttandanceInOutResponseModel.fromJson(response.data);
    }

    throw Exception("Attendance submit failed");
  }


  // Future<void> updateAttendanceStatus() async {
  //   final String status = checkInStatusController.text.trim();
  //   var dio = Dio();
  //
  //   final Map<String, dynamic> body = {
  //     "Id": checkInId.toString(),
  //     "MobileNo": userNameStr,
  //     "Status": status.toLowerCase() != selectedStatusName.toLowerCase()
  //         ? firstPart
  //         : status,
  //     "Remarks": remarksController.text.trim(),
  //     "COffDt": currentDateTimeString,
  //     "Lat": currentPosition.latitude.toString(),
  //     "Long": currentPosition.longitude.toString(),
  //     "GPSStatus": gpsStatus.toString(),
  //     "NetStatus": "true",
  //     "InTime": currentDateTimeString,
  //     "OutTime": (firstPart == "PL" ||
  //         firstPart == "CL" ||
  //         firstPart == "A")
  //         ? currentDateTimeString
  //         : "",
  //   };
  //
  //   try {
  //     final response = await dio.post(
  //       ApiUrl.GetAttendanceStatusUpdate,
  //       data: body,
  //     );
  //
  //     print(response.data);
  //   } catch (e) {
  //     print("Error: $e");
  //   }
  // }

  /// Update attendance status for an existing check-in record (edit mode).
  Future<void> updateAttendanceStatus({
    required String selectedStatusText,
    required String remarks,
    String? coffDate,
  }) async {
    final mobile = LocalDbController.to.mobileNo;
    final now = DateTime.now();
    final currentDateTimeString = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);

    String statusCode = getStatusCode(selectedStatusText);

    remarks = remarks.isEmpty
        ? "."
        : (remarks.length > 100 ? remarks.substring(0, 100) : remarks);

    Position position;
    bool gpsStatus = false;
    try {
      position = await _getCurrentPosition();
      gpsStatus = true;
    } catch (_) {
      position = Position(
          longitude: 0.0,
          latitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0);
      gpsStatus = false;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    bool netStatus = connectivityResult != ConnectivityResult.none;

    var AutoID = await LocalDbController.to.autoId2;

    // Determine outTime — set for leave/absent statuses
    final leaveStatuses = ["PL", "CL", "A", "COFF"];
    final String outTime = leaveStatuses.contains(statusCode) ? currentDateTimeString : "";

    final formData = FormData.fromMap({
      "Id": AutoID.toString(),
      "MobileNo": mobile.toString(),
      "Status": statusCode,
      "Remarks": remarks,
      "COffDt": statusCode == "COFF" ? (coffDate ?? "") : "",
      "Lat": position.latitude.toString(),
      "Long": position.longitude.toString(),
      "GPSStatus": gpsStatus.toString(),
      "NetStatus": netStatus.toString(),
      "InTime": currentDateTimeString,
      "OutTime": outTime,
    });

    print('Update Attendance Status Request >>>>>> ${formData.fields}');

    try {
      final response = await Dio().post(
        ApiUrl.GetAttendanceStatusUpdate,
        data: formData,
      );
      print('Update Attendance Status Response >>>>>> ${response.data}');
    } catch (e) {
      print("Update Attendance Status Error: $e");
      rethrow;
    }
  }



  Future<void> attandanceOutSubmit() async {
    final homeCtrl = Get.find<HomeScreenController>();

    try {
      homeCtrl.isSubmittingCheckout.value = true;

      final mobile = LocalDbController.to.mobileNo;
      final formattedDate =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

      Position position;
      try {
        position = await _getCurrentPosition();
      } catch (_) {
        position = Position(
            longitude: 0.0,
            latitude: 0.0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
      }

      // 📱 Gather missing metadata internally
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = await getDeviceAndStatusInfo();

      var connectivityResult = await Connectivity().checkConnectivity();
      bool netStatus = connectivityResult != ConnectivityResult.none;

      final battery = Battery();
      String batteryStatus = '0%';
      try {
        int batteryLevel = await battery.batteryLevel;
        batteryStatus = "$batteryLevel%";
      } catch (e) {
        batteryStatus = (await LocalDbController.getLastBattery()) ?? '0%';
        if (!batteryStatus.contains('%')) batteryStatus = "$batteryStatus%";
      }

      final insertedOnDate = DateFormat("dd-MMM-yyyy hh:mm a").format(DateTime.now());

      var data = FormData.fromMap({
        'MobileNo': mobile.toString(),
        'OutTime': formattedDate,
        'Long': position.longitude.toString(),
        'Lat': position.latitude.toString(),
        'NetStatus': netStatus ? "true" : "false",
        'GPSStatus': "true",
        'BattryStatus': batteryStatus,
        'ModelName': (deviceInfo["modelname"] ?? "").toString(),
        'AndroidVersion': (deviceInfo["androidversion"] ?? "").toString(),
        'AppVersion': packageInfo.version.toString(),
        'InsertedOn': insertedOnDate,
      });

      final response =
      await Dio().post(ApiUrl.attandanceInOut, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        homeCtrl.hasCheckedIn.value = false;
        homeCtrl.checkOutTime.value = formattedDate;

        // Ensure final tracking record is pushed to the server
        try {
          print("📡 Sending final Check-Out Tracking Record...");
          await sendBackgroundLocationApi(
            fullUrl: ApiUrl.InsertlatLong,
            mobileNo: mobile.toString(),
            lat: position.latitude.toString(),
            long: position.longitude.toString(),
            batterystatus: batteryStatus,
            gpsstatus: "true",
            netstatus: netStatus ? "true" : "false",
            appversion: packageInfo.version.toString(),
            modelname: (deviceInfo["modelname"] ?? "").toString(),
            androidversion: (deviceInfo["androidversion"] ?? "").toString(),
            insertedon: insertedOnDate,
          );
        } catch (e) {
          print("⚠️ Failed to send final Check-Out tracking record: $e");
        }

        // Stop background service on checkout
        print("🛑 Checkout: Stopping Background Service...");
        FlutterBackgroundService().invoke("stop");
        await LocalDbController.setIsBgServiceRunning(false);
        print("✅ Checkout: Background Service Stop command sent.");

        homeCtrl.startAutoHideTimer();
      }
    } finally {
      homeCtrl.isSubmittingCheckout.value = false;
    }
  }




// Future<AttandanceInOutResponseModel> attandanceInOutSubmit(
  //     String selectedStatusText, String remark) async {
  //
  //   final mobile = LocalDbController.to.mobileNo;
  //   final now = DateTime.now();
  //   final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
  //
  //   // Get code from TextList
  //   String statusCode = getStatusCode(selectedStatusText);
  //
  //   // Ensure remark length
  //   remark = remark.isEmpty ? "." : (remark.length > 100 ? remark.substring(0, 100) : remark);
  //
  //   var data = FormData.fromMap({
  //     'MobileNo': mobile,
  //     'Status': statusCode,   // now dynamic
  //     'BattryStatus': 100.0,
  //     'InTime': formattedDate,
  //     'Remarks': remark,
  //     'OutTime': "",
  //     'Long': 0,
  //     'Lat': 0,
  //     'NetStatus': true,
  //     'GPSStatus': true,
  //   });
  //
  //   print('Attandance In Out Request >>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     //'http://103.113.32.126${ApiUrl.attandanceInOut}',
  //     '${ApiUrl.attandanceInOut}',
  //     options: Options(method: 'POST'),
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     print('Attandance in Out Response>>>>>>>${response.data}');
  //     return AttandanceInOutResponseModel.fromJson(response.data);
  //   }
  //
  //   throw Exception("Attendance submit failed");
  // }


// Future<AttandanceInOutResponseModel> attandanceInOutSubmit(
  //     String status, String remark) async {
  //
  //   final mobile = LocalDbController.to.getMobileNo();
  //   final now = DateTime.now();
  //   final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
  //
  //   // Limit lengths to prevent SQL truncation
  //   status = status.length > 20 ? status.substring(0, 20) : status;
  //   remark = remark.isEmpty ? "." : (remark.length > 100 ? remark.substring(0, 100) : remark);
  //
  //   var data = FormData.fromMap({
  //     'MobileNo': mobile,
  //     'Status':  'A',
  //     'BattryStatus': '100.0',
  //     'InTime': formattedDate,
  //     'Remarks': remark.isEmpty ? "." : (remark.length > 100 ? remark.substring(0, 100) : remark),
  //     'OutTime': "",
  //     'Long': 0,
  //     'Lat': 0,
  //     'NetStatus': true,
  //     'GPSStatus': true,
  //   });
  //
  //
  //   print('Attandance In Out Request >>>>>>${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.request(
  //     'http://103.113.32.126${ApiUrl.attandanceInOut}',
  //     options: Options(method: 'POST'),
  //     data: data,
  //   );
  //
  //   if (response.statusCode == 200) {
  //     print('Attandance in Out Response>>>>>>>${response.data}');
  //     return AttandanceInOutResponseModel.fromJson(response.data);
  //   }
  //
  //   throw Exception("Attendance submit failed");
  // }



// Future<AttandanceInOutResponseModel> attandanceInOutSubmit(
//       String status, String remark) async {
//     final prefs = await SharedPreferences.getInstance();
//     final mobile = LocalDbController.to.getMobileNo();
//     print('Fetched MobileNo from LocalDb >>> $mobile');
//     await prefs.setString('MobileNo', mobile);
//     final now = DateTime.now();
//     final formattedDate = DateFormat("dd-MMM-yyyy hh:mm:ss a").format(now);
//
//     var data = FormData.fromMap({
//       'MobileNo': mobile,
//       'Status': status,
//       'BattryStatus': '100.0',
//       'InTime': formattedDate,
//       'Remarks': remark,
//       'OutTime': '',
//       'Long': '72.5107533',
//       'NetStatus': 'true',
//       'GPSStatus': 'true',
//       'Lat': '23.0120333'
//     });
//
//     print('Attandance In Out Request >>>>>>${data.fields}');
//
//     var dio = Dio();
//     var response = await dio.request(
//       'http://${'103.113.32.126'}${ApiUrl.attandanceInOut}',
//       options: Options(
//         method: 'POST',
//       ),
//       data: data,
//     );
//
//     if (response.statusCode == 200) {
//       print('Attandance in Out Response>>>>>>>${response.data}');
//       return AttandanceInOutResponseModel.fromJson(response.data);
//     } else {
//       print(response.statusMessage);
//     }
//     throw Exception();
//   }
}
