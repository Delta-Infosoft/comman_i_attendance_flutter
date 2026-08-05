import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart' hide FormData;
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/home/model/follow_ups_response_model.dart';
import 'package:waterman_iattandance/screens/home/model/get_attendance_from_id_response_model.dart';

import '../../../constant/api_url/api_url.dart';
import '../model/get_last_attandances_response_model.dart';
import 'package:waterman_iattandance/service/background_location_service.dart';

class HomeScreenController extends GetxController {
  var isLoading = true.obs;
  var lastAttendances = <GetLastAttandancesResultData>[].obs; // Assuming 'Result' is your model type
  var hasCheckedIn = false.obs;
  var checkInTime = ''.obs;
  RxString checkOutTime = ''.obs;
  RxBool isSubmittingCheckout = false.obs;
  Timer? _autoHideTimer;

  RxBool isPermissionFlowRunning = false.obs;

  RxBool isTodayCompleted = false.obs;

  bool get showCheckoutCard =>
      hasCheckedIn.value || checkOutTime.value.isNotEmpty;


  @override
  void onInit() {
    super.onInit();
    fetchLastAttandances();
    fetchCheckinStatus();
    followUps();
  }

  @override
  void onClose() {
    _autoHideTimer?.cancel();
    super.onClose();
  }

  void startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(minutes: 5), () {
      checkOutTime.value = '';
    });
  }

  DateTime? parseApiDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try ISO 8601 first (e.g. "2026-08-03T11:05:04")
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // API typically returns "M/d/yyyy h:mm:ss a"  e.g. "8/3/2026 11:05:04 AM"
    try {
      return DateFormat('M/d/yyyy h:mm:ss a').parse(dateStr);
    } catch (_) {}

    // Also try "d/M/yyyy h:mm:ss a"
    try {
      return DateFormat('d/M/yyyy h:mm:ss a').parse(dateStr);
    } catch (_) {}

    // Try "M/d/yyyy HH:mm:ss"
    try {
      return DateFormat('M/d/yyyy HH:mm:ss').parse(dateStr);
    } catch (_) {}

    // Try "dd-MMM-yyyy hh:mm:ss a" e.g. "03-Aug-2026 11:05:04 AM"
    try {
      return DateFormat('dd-MMM-yyyy hh:mm:ss a').parse(dateStr);
    } catch (_) {}

    print('⚠️ parseApiDate: unrecognised format → "$dateStr"');
    return null;
  }


  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _resetToday() {
    hasCheckedIn.value = false;
    checkInTime.value = '';
    checkOutTime.value = '';
    isTodayCompleted.value = false;
  }

  Future<FollowUpsResponseModel> followUps() async {
    var data = FormData.fromMap({
      'MobileNo': LocalDbController.to.mobileNo, // later replace with dynamic
    });

    var dio = Dio();
    var response = await dio.request(
      '${ApiUrl.FollowUps}',
      options: Options(
        method: 'POST',
      ),
      data: data,
    );

    if (response.statusCode == 200) {

      print('Follow Ups Response>>>>>>>${response.data}');
      final model = FollowUpsResponseModel.fromJson(response.data);
      return model;
    }
    else {
      print(response.statusMessage);
    }
    throw UnimplementedError();
  }


  Map<String, dynamic>? findTodayLatest(List list) {
    final today = DateTime.now();

    final todayRecords = list.where((e) {
      final inTime = parseApiDate(e['InTime'] ?? '');
      return inTime != null && isSameDay(inTime, today);
    }).toList();

    if (todayRecords.isEmpty) return null;

    /// Sort latest first
    todayRecords.sort((a, b) {
      final aTime = parseApiDate(a['InTime'])!;
      final bTime = parseApiDate(b['InTime'])!;
      return bTime.compareTo(aTime);
    });

    return todayRecords.first;
  }



  // Future<void> fetchCheckinStatus() async {
  //   try {
  //     final response = await Dio().post(
  //       ApiUrl.getCheckinoutStatus,
  //       data: FormData.fromMap({
  //         'UserName': LocalDbController.to.mobileNo,
  //       }),
  //     );
  //
  //     if (response.statusCode != 200) {
  //       _resetToday();
  //       return;
  //     }
  //
  //     final resData = response.data;
  //     final List list = resData['result'] ?? [];
  //
  //     final record = findTodayLatest(list);
  //     if (record == null) {
  //       _resetToday();
  //       return;
  //     }
  //
  //     final String inTimeStr = record['InTime'] ?? '';
  //     final String outTimeStr = record['OutTime'] ?? '';
  //
  //     if (outTimeStr.isEmpty) {
  //       hasCheckedIn.value = true;
  //       checkInTime.value = inTimeStr;
  //       checkOutTime.value = '';
  //       isTodayCompleted.value = false;
  //       return;
  //     }
  //
  //     hasCheckedIn.value = false;
  //     checkInTime.value = '';
  //     checkOutTime.value = outTimeStr;
  //     isTodayCompleted.value = true;
  //
  //   } catch (e) {
  //     _resetToday();
  //     print('Error fetching check-in status: $e');
  //   }
  // }




  // Future<void> fetchCheckinStatus() async {
  //   try {
  //     String user = LocalDbController.to.mobileNo;
  //
  //     var data = FormData.fromMap({'UserName': user});
  //     var dio = Dio();
  //
  //     var response = await dio.request(
  //       ApiUrl.getCheckinoutStatus,
  //       options: Options(method: 'POST'),
  //       data: data,
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print('Check-in Status Response>>>>>>>${response.data}');
  //       final resData = response.data;
  //
  //       if (resData != null &&
  //           resData['status'].toString() == '200' &&
  //           resData['result'] != null &&
  //           (resData['result'] as List).isNotEmpty) {
  //
  //         final record = resData['result'][0];
  //
  //         final String inTimeStr = record['InTime'] ?? '';
  //         final String outTimeStr = record['OutTime'] ?? '';
  //
  //         if (inTimeStr.isNotEmpty) {
  //           final DateTime inTime =
  //           DateFormat('d/M/yyyy hh:mm:ss a').parse(inTimeStr);
  //           final DateTime today = DateTime.now();
  //
  //           if (!isSameDay(inTime, today)) {
  //             hasCheckedIn.value = false;
  //             checkInTime.value = '';
  //             checkOutTime.value = '';
  //             isTodayCompleted.value = false;
  //             return;
  //           }
  //         }
  //
  //         if (inTimeStr.isNotEmpty && outTimeStr.isNotEmpty) {
  //           hasCheckedIn.value = false;
  //           checkInTime.value = '';
  //           checkOutTime.value = outTimeStr;
  //           isTodayCompleted.value = true;
  //         }
  //         else if (inTimeStr.isNotEmpty && outTimeStr.isEmpty) {
  //           hasCheckedIn.value = true;
  //           checkInTime.value = inTimeStr;
  //           checkOutTime.value = '';
  //           isTodayCompleted.value = false;
  //         }
  //         else {
  //           hasCheckedIn.value = false;
  //           checkInTime.value = '';
  //           checkOutTime.value = '';
  //           isTodayCompleted.value = false;
  //         }
  //
  //       } else {
  //       hasCheckedIn.value = false;
  //       checkInTime.value = '';
  //       checkOutTime.value = '';
  //       isTodayCompleted.value = false;
  //     }
  //     }
  //   } catch (e) {
  //     hasCheckedIn.value = false;
  //     checkInTime.value = '';
  //     checkOutTime.value = '';
  //     isTodayCompleted.value = false;
  //     print('Error fetching check-in status: $e');
  //   }
  // }

  // Future<void> fetchCheckinStatus() async {
  //   try {
  //     String user = LocalDbController.to.mobileNo;
  //     var data = FormData.fromMap({'UserName': user});
  //     var dio = Dio();
  //
  //     var response = await dio.request(
  //       '${ApiUrl.getCheckinoutStatus}',
  //       options: Options(method: 'POST'),
  //       data: data,
  //     );
  //
  //     if (response.statusCode == 200) {
  //       var resData = response.data;
  //
  //       if (resData != null &&
  //           resData['status'].toString() == '200' &&
  //           resData['result'] != null &&
  //           (resData['result'] as List).isNotEmpty) {
  //         List records = resData['result'];
  //
  //         // Try to get today’s record first
  //         var todayRecord = findTodayLatest(records);
  //
  //         if (todayRecord == null) {
  //           // No record today, use latest record overall (for last checkout)
  //           records.sort((a, b) {
  //             final aTime = parseApiDate(a['InTime']) ?? DateTime(2000);
  //             final bTime = parseApiDate(b['InTime']) ?? DateTime(2000);
  //             return bTime.compareTo(aTime);
  //           });
  //           todayRecord = records.first;
  //         }
  //
  //         // Now update the observables
  //         final inTime = todayRecord?['InTime'] ?? '';
  //         final outTime = todayRecord?['OutTime'] ?? '';
  //
  //         if (isSameDay(parseApiDate(inTime) ?? DateTime.now(), DateTime.now())) {
  //           // Record is today
  //           checkInTime.value = inTime;
  //           if (outTime.isNotEmpty) {
  //             hasCheckedIn.value = false;
  //             checkOutTime.value = outTime;
  //             isTodayCompleted.value = true;
  //           } else {
  //             hasCheckedIn.value = true;
  //             checkOutTime.value = '';
  //             isTodayCompleted.value = false;
  //           }
  //         } else {
  //           // Record is from previous day
  //           hasCheckedIn.value = false;
  //           checkInTime.value = '';
  //           checkOutTime.value = '';
  //           isTodayCompleted.value = false;
  //         }
  //       } else {
  //         hasCheckedIn.value = false;
  //         checkInTime.value = '';
  //         checkOutTime.value = '';
  //         isTodayCompleted.value = false;
  //       }
  //     } else {
  //       hasCheckedIn.value = false;
  //       checkInTime.value = '';
  //       checkOutTime.value = '';
  //       isTodayCompleted.value = false;
  //       print(response.statusMessage);
  //     }
  //   } catch (e) {
  //     hasCheckedIn.value = false;
  //     checkInTime.value = '';
  //     checkOutTime.value = '';
  //     isTodayCompleted.value = false;
  //     print('Error fetching check-in status: $e');
  //   }
  // }


  Future<void> fetchCheckinStatus() async {
    try {
      String user = LocalDbController.to.mobileNo;
      var data = FormData.fromMap({'UserName': user});
      var dio = Dio();

      print('Fetching check-in status for user: $user');

      var response = await dio.request(
        '${ApiUrl.getCheckinoutStatus}',
        options: Options(method: 'POST'),
        data: data,
      );
      print('check in status API>>>>>>${ApiUrl.getCheckinoutStatus}');

      if (response.statusCode == 200) {
        print('Check-in Status Response>>>>>>>${response.data}');
        var resData = response.data;

        if (resData != null &&
            resData['status'].toString() == '200' &&
            resData['result'] != null &&
            (resData['result'] as List).isNotEmpty) {

          var record = resData['result'][0];

          // Get AutoId
          final autoId = record['AutoId']?.toString() ?? '';

          print("AutoId >>>>> $autoId");

          // Save AutoId
          await LocalDbController.setAutoId(autoId);

          final inTime = record['InTime'] ?? '';
          final outTime = record['OutTime'] ?? '';

          // ── Date-guard: only treat this record as "today's" if InTime
          //    is actually from today.  If the most-recent record belongs
          //    to a previous day (e.g. yesterday's completed attendance),
          //    reset all flags so the user can check in fresh today.
          //    NOTE: if the date cannot be parsed (unknown format) we fall
          //    through and let the original in/out logic decide — we must
          //    NOT reset on a parse failure or today's completed record
          //    would wrongly show "Check In Now".
          if (inTime.isNotEmpty) {
            final recordDate = parseApiDate(inTime);
            if (recordDate != null && !isSameDay(recordDate, DateTime.now())) {
              print("📅 Last record ($inTime) is NOT today → resetting state for a fresh check-in.");
              _resetToday();
              return;
            }
          }

          // if (inTime.isNotEmpty && outTime.isEmpty) {
          //   // User has already checked in
          //   hasCheckedIn.value = true;
          //   checkInTime.value = inTime;
          //   checkOutTime.value = '';
          //
          //   // // Resume background service if it's not running
          //   // print("🏠 App startup/login: Checked in status detected. Resuming background service...");
          //   // try {
          //   //   await initializeBackgroundService();
          //   //   await LocalDbController.setIsBgServiceRunning(true);
          //   // } catch (e) {
          //   //   print("❌ Error resuming background service: $e");
          //   // }
          // } else {
          //   // User can check in
          //   hasCheckedIn.value = false;
          //   checkInTime.value = '';
          //   checkOutTime.value = outTime; // optional
          // }

          if (inTime.isNotEmpty && outTime.isEmpty) {
            // User has already checked in
            hasCheckedIn.value = true;
            checkInTime.value = inTime;
            checkOutTime.value = '';

            // Resume background service if it's not already running.
            // This is the source of truth (server status), not just the
            // locally cached "was running" flag.
            print("🏠 App startup/login: Checked-in status detected. Resuming background service...");
            try {
              final alreadyRunning = await FlutterBackgroundService().isRunning();
              if (!alreadyRunning) {
                await startWatermanTracking();
              } else {
                // Service is alive — just make sure the "should run" flag
                // and watchdogs agree, in case they got out of sync.
                await LocalDbController.setIsBgServiceRunning(true);
              }
            } catch (e) {
              print("❌ Error resuming background service: $e");
            }
          } else {
            // User has checked in AND checked out (or only checked out)
            hasCheckedIn.value = false;
            checkInTime.value = inTime;   // preserve so UI can show it
            checkOutTime.value = outTime;

            if (outTime.isNotEmpty) {
              print("🏠 Checked-out status detected (outTime = $outTime) → Stopping background service...");
              try {
                await stopWatermanTracking();
              } catch (e) {
                print("❌ Error stopping background service: $e");
              }
            }
          }

        } else {
          // No records at all → user can check in
          hasCheckedIn.value = false;
          checkInTime.value = '';
          checkOutTime.value = '';
        }
      } else {
        hasCheckedIn.value = false;
        checkInTime.value = '';
        checkOutTime.value = '';
        print(response.statusMessage);
      }
    } catch (e) {
      hasCheckedIn.value = false;
      checkInTime.value = '';
      checkOutTime.value = '';
      print('Error fetching check-in status: $e');
    }
  }



  // Future<void> fetchCheckinStatus() async {
  //   try {
  //     String user = LocalDbController.to.mobileNo;
  //
  //     var data = FormData.fromMap({'UserName': user});
  //     var dio = Dio();
  //
  //     var response = await dio.request(
  //       '${ApiUrl.getCheckinoutStatus}',
  //       options: Options(method: 'POST'),
  //       data: data,
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print(json.encode(response.data));
  //       print('Check-in Status Response>>>>>>>${response.data}');
  //
  //       var resData = response.data;
  //
  //       // Check if result exists and is not empty
  //       if (resData != null &&
  //           resData['status'].toString() == '200' &&
  //           resData['result'] != null &&
  //           (resData['result'] as List).isNotEmpty) {
  //         var record = resData['result'][0];
  //
  //         // Update observable variables
  //         // hasCheckedIn.value = true;
  //         // checkInTime.value = record['InTime'] ?? '';
  //         if ((record['OutTime'] ?? '').isNotEmpty) {
  //
  //           hasCheckedIn.value = false;
  //           checkInTime.value = '';
  //           checkOutTime.value = record['OutTime'] ?? '';
  //         } else {
  //
  //           hasCheckedIn.value = true;
  //           checkInTime.value = record['InTime'] ?? '';
  //           checkOutTime.value = '';
  //         }
  //       } else {
  //         hasCheckedIn.value = false;
  //         checkInTime.value = '';
  //       }
  //     } else {
  //       hasCheckedIn.value = false;
  //       checkInTime.value = '';
  //       print(response.statusMessage);
  //     }
  //   } catch (e) {
  //     hasCheckedIn.value = false;
  //     checkInTime.value = '';
  //     print('Error fetching check-in status: $e');
  //   }
  // }




  Future<void> fetchLastAttandances() async {
    String user = LocalDbController.to.mobileNo;
    try {
      isLoading(true);

      var data = FormData.fromMap({
        'MobileNo': user, // later replace with dynamic
        'Month': DateTime.now()
      });

      var dio = Dio();
      var response = await dio.request(
        //'http://${'103.113.32.126'}${ApiUrl.getLastAttandanceDetails}',
        '${ApiUrl.getLastAttandanceDetails}',
        options: Options(method: 'POST'),
        data: data,
      );
      print('last attendance>>>>>>${ApiUrl.getLastAttandanceDetails}');

      if (response.statusCode == 200) {
        print('Last Attandances Response>>>>>>>${response.data}');
        final model = GetLastAttandancesResponseModel.fromJson(response.data);
        lastAttendances.value = model.result ?? [];
      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      isLoading(false);
    }
  }


  Future<GetAttendanceFromId> getAttendanceFromId() async {
    String id = await LocalDbController.to.autoId2 ?? ''; // later replace with dynamic
    try {
      isLoading(true);

      var data = FormData.fromMap({
        'Id': id,
      });

      print('Getting attendance details for ID>>>>>: $id');

      var dio = Dio();
      var response = await dio.request(
        //'http://${'103.113.32.126'}${ApiUrl.getLastAttandanceDetails}',
        '${ApiUrl.GetAttendanceFromID}',
        options: Options(method: 'POST'),
        data: data,
      );

      if (response.statusCode == 200) {
        print('Get Attendance Data from id>>>>>${response.data}');

        return GetAttendanceFromId.fromJson(response.data);

      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      isLoading(false);
    }
    throw UnimplementedError();
  }





}
