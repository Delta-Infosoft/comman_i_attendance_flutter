// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'project_journey_repository.dart';
// import '../model/project_journey_model.dart';

// class JourneyCycleController extends GetxController {
//   final ProjectJourneyRepository _repository = ProjectJourneyRepository();

//   // Reactive variables
//   var isLoading = true.obs;
//   var errorMessage = ''.obs;
//   var backDatedRights = Rxn<BackDatedRights>();
//   var selectedDate = DateTime.now().obs;

//   // PJC creation variables
//   var isCreatingPJC = false.obs;
//   var createPJCMessage = ''.obs;
//   var createPJCSuccess = false.obs;

//   // PJC Data variables
//   var isFetchingPJC = false.obs;
//   var pjcData = <PJCData>[].obs;
//   var pjcErrorMessage = ''.obs;

//   // PJC Event variables
//   var isFetchingPJCEvent = false.obs;
//   var pjcEventData = <List<PJCEventData>>[].obs;
//   var pjcEventErrorMessage = ''.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     print('JourneyCycleController Initialized');
//   }

//   // Date restrictions based on API response
//   DateTime get minSelectableDate => DateTime.now();

//   DateTime? get maxSelectableDate {
//     if (backDatedRights.value != null) {
//       final noOfDays = int.tryParse(backDatedRights.value!.noOfDays) ?? 0;
//       return DateTime.now().add(Duration(days: noOfDays));
//     }
//     return null;
//   }

//   int get allowedDays {
//     if (backDatedRights.value != null) {
//       return int.tryParse(backDatedRights.value!.noOfDays) ?? 0;
//     }
//     return 0;
//   }

//   bool isDateSelectable(DateTime date) {
//     final today = DateTime.now();
//     final yesterday = today.subtract(const Duration(days: 1));

//     // Disable past dates
//     if (date
//         .isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day))) {
//       return false;
//     }

//     // Enable dates from today up to maxSelectableDate
//     if (maxSelectableDate != null) {
//       return date.isBefore(maxSelectableDate!) ||
//           isSameDay(date, maxSelectableDate!);
//     }

//     return true;
//   }

//   bool isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   // STEP 1: Fetch back-dated rights
//   Future<void> fetchBackDatedRights() async {
//     try {
//       isLoading(true);
//       errorMessage('');

//       print('Fetching back-dated rights from API...');

//       final response = await _repository.getBackDatedRightsWithFallback('999');

//       if (response.status == "200" && response.result.isNotEmpty) {
//         backDatedRights.value = response.result.first;
//         print('Back-dated rights loaded successfully');
//         print('Allowed Days: ${backDatedRights.value?.noOfDays}');
//       } else {
//         errorMessage.value = response.message;
//         print('Failed to load back-dated rights: ${response.message}');
//       }
//     } catch (e) {
//       errorMessage.value = e.toString();
//       print('Error in fetchBackDatedRights: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   // STEP 2: Fetch PJC data for calendar
//   Future<void> fetchPJCData(String mobileNo, DateTime focusedDate) async {
//     try {
//       isFetchingPJC(true);
//       pjcErrorMessage('');

//       print('Fetching PJC data for month: $focusedDate');

//       final monthYear = DateFormat('MMM yyyy').format(focusedDate);
//       print('MonthYear for API: $monthYear');

//       final response = await _repository.getPJC(mobileNo, monthYear);

//       if (response.status == "200") {
//         pjcData.clear();
//         pjcData.addAll(response.result);
//         print('PJC data fetched successfully: ${pjcData.length} records');

//         // Print all events for debugging
//         for (final pjc in pjcData) {
//           print(
//               'PJC Event - Place: "${pjc.place}", Notes: "${pjc.notes}", Date: ${pjc.dt}');
//         }
//       } else {
//         pjcErrorMessage.value = response.message;
//         print('Failed to fetch PJC: ${response.message}');
//       }
//     } catch (e) {
//       pjcErrorMessage.value = e.toString();
//       print('Error fetching PJC data: $e');
//     } finally {
//       isFetchingPJC(false);
//     }
//   }

//   // STEP 3: Fetch PJC Event data for specific date - FIXED
//   Future<void> fetchPJCEventData(String mobileNo, DateTime date) async {
//     try {
//       isFetchingPJCEvent(true);
//       pjcEventErrorMessage('');

//       print('Fetching PJC Event data for date: $date');

//       final formattedDate = DateFormat('dd-MMM-yyyy').format(date);
//       print('Date for API: $formattedDate');
//       print('MobileNo for API: $mobileNo');

//       final response =
//           await _repository.getPJCEventWithFallback(mobileNo, formattedDate);

//       print('PJC Event API Response Status: ${response.status}');
//       print('PJC Event API Response Message: ${response.message}');
//       print('PJC Event API Result Length: ${response.result.length}');

//       if (response.status == "200") {
//         pjcEventData.assignAll(response.result);
//         print('PJC Event data fetched successfully');

//         // Print all events for debugging
//         for (int i = 0; i < response.result.length; i++) {
//           final eventList = response.result[i];
//           print('Event Array $i: ${eventList.length} events');
//           for (final event in eventList) {
//             print('  - Place: "${event.place}", Notes: "${event.notes}"');
//           }
//         }
//       } else {
//         pjcEventErrorMessage.value = response.message;
//         print('Failed to fetch PJC Event: ${response.message}');
//       }
//     } catch (e) {
//       pjcEventErrorMessage.value = e.toString();
//       print('Error fetching PJC Event data: $e');
//     } finally {
//       isFetchingPJCEvent(false);
//     }
//   }

//   // STEP 4: Create PJC and refresh data
//   Future<bool> createPJC({
//     required DateTime date,
//     required String station,
//     required String agenda,
//     required String mobileNo,
//   }) async {
//     try {
//       print('START: createPJC method called');
//       isCreatingPJC(true);
//       createPJCMessage('');
//       createPJCSuccess(false);

//       print('Form Data:');
//       print('Date: $date');
//       print('Station: $station');
//       print('Agenda: $agenda');
//       print('MobileNo: $mobileNo');

//       if (!isDateSelectable(date)) {
//         print('Date not selectable');
//         createPJCMessage.value = 'Selected date is not within allowed range';
//         return false;
//       }

//       final monthYear = DateFormat('MMM yyyy').format(date);
//       final formattedDate = DateFormat('dd-MMM-yyyy').format(date);

//       final request = PJCCreateRequest(
//         mobileNo: mobileNo,
//         nightHault: false,
//         monthYear: monthYear,
//         date: formattedDate,
//         place: station,
//         notes: agenda,
//       );

//       print('Calling API_InsertPJC...');
//       final response = await _repository.insertPJC(request);

//       print('API Response:');
//       print('Status: ${response.status}');
//       print('Message: ${response.message}');

//       if (response.status == "200") {
//         print('SUCCESS: PJC Created');
//         createPJCSuccess(true);
//         createPJCMessage.value = response.message;

//         // Refresh PJC data to show new entry
//         print('Refreshing PJC data after creation...');
//         await fetchPJCData(mobileNo, date);

//         // ✅ FIXED: Also fetch PJC Event data for the created date
//         print('Fetching PJC Event data for the created date...');
//         await fetchPJCEventData(mobileNo, date);

//         return true;
//       } else {
//         print('FAILED: PJC Creation failed');
//         createPJCSuccess(false);
//         createPJCMessage.value = response.message;
//         return false;
//       }
//     } catch (e) {
//       print('ERROR in createPJC: $e');
//       createPJCSuccess(false);
//       createPJCMessage.value = e.toString();
//       return false;
//     } finally {
//       isCreatingPJC(false);
//     }
//   }

//   // Get events for specific date
//   List<PJCData> getEventsForDate(DateTime date) {
//     final events = pjcData.where((pjc) {
//       try {
//         String dateString = pjc.dt;
//         if (dateString.contains(' ')) {
//           dateString = dateString.split(' ')[0];
//         }

//         final apiDate = DateFormat('dd-MMM-yyyy').parse(dateString);
//         return isSameDay(apiDate, date);
//       } catch (e) {
//         print('Error parsing date for PJC: ${pjc.dt}, Error: $e');
//         return false;
//       }
//     }).toList();

//     print('Found ${events.length} events for date: $date');
//     return events;
//   }

//   // Get events from PJC Event data for specific date
//   List<PJCEventData> getPJCEventsForDate(DateTime date) {
//     final allEvents = <PJCEventData>[];
//     for (final eventList in pjcEventData) {
//       allEvents.addAll(eventList);
//     }
//     print('Total PJC Events for all dates: ${allEvents.length}');
//     return allEvents;
//   }

//

// void resetToCurrentDate() {}

// void resetToCurrentDate() {}

// void resetToCurrentDate() {}  // Update selected date
//   void updateSelectedDate(DateTime newDate) {
//     if (isDateSelectable(newDate)) {
//       selectedDate.value = newDate;
//       print('Selected date updated to: $newDate');
//     } else {
//       print('Date $newDate is not selectable');
//       Get.snackbar(
//         'Date Not Available',
//         'You can only select dates from today to next $allowedDays days',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
//   }

//   // Reset PJC creation state
//   void resetPJCCreationState() {
//     isCreatingPJC(false);
//     createPJCMessage('');
//     createPJCSuccess(false);
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/flavor_config.dart';
import 'project_journey_repository.dart';
import '../model/project_journey_model.dart';

class JourneyCycleController extends GetxController {
  final ProjectJourneyRepository _repository = ProjectJourneyRepository();

  // Reactive variables
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var backDatedRights = Rxn<BackDatedRights>();
  var selectedDate = DateTime.now().obs;
  var nightHold = false.obs;

  // PJC creation variables
  var isCreatingPJC = false.obs;
  var createPJCMessage = ''.obs;
  var createPJCSuccess = false.obs;

  // PJC Data variables
  var isFetchingPJC = false.obs;
  var pjcData = <PJCData>[].obs;
  var pjcErrorMessage = ''.obs;

  // PJC Event variables
  var isFetchingPJCEvent = false.obs;
  var pjcEventData = <List<PJCEventData>>[].obs;
  var pjcEventErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('JourneyCycleController Initialized');
  }

  // ✅ ADD THIS METHOD: Reset to current date
  void resetToCurrentDate() {
    selectedDate.value = DateTime.now();
    print('Reset selected date to current: ${selectedDate.value}');
  }

  // Date restrictions based on API response
  DateTime get minSelectableDate {
    if (backDatedRights.value != null) {
      if (FlavorConfig.instance.flavor == AppFlavor.singla) {
        final fromPJC = int.tryParse(backDatedRights.value!.fromPJCDate) ?? 1;
        final now = DateTime.now();
        return DateTime(now.year, now.month, fromPJC);
      }
      final noOfDays = int.tryParse(backDatedRights.value!.noOfDays ?? "0") ?? 0;
      // Subtract allowed days from today
      return DateTime.now().subtract(Duration(days: noOfDays < 0 ? 0 : noOfDays));
    }
    return DateTime.now();
  }

  DateTime? get maxSelectableDate {
    if (backDatedRights.value != null) {
      if (FlavorConfig.instance.flavor == AppFlavor.singla) {
        final toPJC = int.tryParse(backDatedRights.value!.toPJCDate) ?? 31;
        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final targetDay = toPJC > lastDay ? lastDay : toPJC;
        return DateTime(now.year, now.month, targetDay);
      }
      final noOfDays = int.tryParse(backDatedRights.value!.noOfDays) ?? 0;
      return DateTime.now().add(Duration(days: noOfDays));
    }
    return null;
  }

  int get allowedDays {
    if (backDatedRights.value != null) {
      return int.tryParse(backDatedRights.value!.noOfDays) ?? 0;
    }
    return 0;
  }

  bool isDateSelectable(DateTime date) {
    final minDate = DateTime(minSelectableDate.year, minSelectableDate.month, minSelectableDate.day);
    final maxDate = maxSelectableDate != null 
        ? DateTime(maxSelectableDate!.year, maxSelectableDate!.month, maxSelectableDate!.day)
        : DateTime.now().add(const Duration(days: 365));

    // Disable dates before minDate
    if (date.isBefore(minDate)) {
      return false;
    }

    // Disable dates after maxDate
    if (date.isAfter(maxDate)) {
      return false;
    }

    return true;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // STEP 1: Fetch back-dated rights
  Future<void> fetchBackDatedRights() async {
    try {
      isLoading(true);
      errorMessage('');

      print('Fetching back-dated rights from API...');
      
      final empId = Get.find<LocalDbController>().empId;
      final response = await _repository.getBackDatedRightsWithFallback(empId);

      if (response.status == "200" && response.result.isNotEmpty) {
        backDatedRights.value = response.result.first;
        print('Back-dated rights loaded successfully');
        print('Allowed Days: ${backDatedRights.value?.noOfDays}');
      } else {
        errorMessage.value = response.message;
        print('Failed to load back-dated rights: ${response.message}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error in fetchBackDatedRights: $e');
    } finally {
      isLoading(false);
    }
  }

  // STEP 2: Fetch PJC data for calendar
  Future<void> fetchPJCData(String mobileNo, DateTime focusedDate) async {
    try {
      isLoading(true);
      isFetchingPJC(true);
      pjcErrorMessage('');

      print('Fetching PJC data for month: $focusedDate');

      final monthYear = DateFormat('MMM yyyy').format(focusedDate);
      print('MonthYear for API: $monthYear');

      final response = await _repository.getPJC(mobileNo, monthYear);

      if (response.status == "200") {
        pjcData.clear();
        pjcData.addAll(response.result);
        print('PJC data fetched successfully: ${pjcData.length} records');

        // Print all events for debugging
        for (final pjc in pjcData) {
          print(
              'PJC Event - Place: "${pjc.place}", Notes: "${pjc.notes}", Date: ${pjc.dt}');
        }
      } else {
        pjcErrorMessage.value = response.message;
        print('Failed to fetch PJC: ${response.message}');
      }
    } catch (e) {
      pjcErrorMessage.value = e.toString();
      print('Error fetching PJC data: $e');
    } finally {
      isLoading(false);
      isFetchingPJC(false);
    }
  }

  // STEP 3: Fetch PJC Event data for specific date
  Future<void> fetchPJCEventData(String mobileNo, DateTime date) async {
    try {
      isFetchingPJCEvent(true);
      pjcEventErrorMessage('');

      print('Fetching PJC Event data for date: $date');

      final formattedDate = DateFormat('dd-MMM-yyyy').format(date);
      print('Date for API: $formattedDate');
      print('MobileNo for API: $mobileNo');

      final response =
          await _repository.getPJCEventWithFallback(mobileNo, formattedDate);

      print('PJC Event API Response Status: ${response.status}');
      print('PJC Event API Response Message: ${response.message}');
      print('PJC Event API Result Length: ${response.result.length}');

      if (response.status == "200") {
        pjcEventData.assignAll(response.result);
        print('PJC Event data fetched successfully');

        // Print all events for debugging
        for (int i = 0; i < response.result.length; i++) {
          final eventList = response.result[i];
          print('Event Array $i: ${eventList.length} events');
          for (final event in eventList) {
            print('  - Place: "${event.place}", Notes: "${event.notes}"');
          }
        }
      } else {
        pjcEventErrorMessage.value = response.message;
        print('Failed to fetch PJC Event: ${response.message}');
      }
    } catch (e) {
      pjcEventErrorMessage.value = e.toString();
      print('Error fetching PJC Event data: $e');
    } finally {
      isFetchingPJCEvent(false);
    }
  }

  // STEP 4: Create PJC and refresh data
  Future<bool> createPJC({
    required DateTime date,
    required String station,
    required String agenda,
    required String mobileNo,
  }) async {
    try {
      print('START: createPJC method called');
      isCreatingPJC(true);
      createPJCMessage('');
      createPJCSuccess(false);

      print('Form Data:');
      print('Date: $date');
      print('Station: $station');
      print('Agenda: $agenda');
      print('MobileNo: $mobileNo');

      if (!isDateSelectable(date)) {
        print('Date not selectable');
        createPJCMessage.value = 'Selected date is not within allowed range';
        return false;
      }

      final monthYear = DateFormat('MMM yyyy').format(date);
      final formattedDate = DateFormat('dd-MMM-yyyy').format(date);

      final request = PJCCreateRequest(
        mobileNo: mobileNo,
        nightHault: nightHold.value,
        monthYear: monthYear,
        date: formattedDate,
        place: station,
        notes: agenda,
      );

      print('Calling API_InsertPJC...');
      final response = await _repository.insertPJC(request);

      print('API Response:');
      print('Status: ${response.status}');
      print('Message: ${response.message}');

      if (response.status == "200") {
        print('SUCCESS: PJC Created');
        createPJCSuccess(true);
        createPJCMessage.value = response.message;

        // Refresh PJC data to show new entry
        print('Refreshing PJC data after creation...');
        await fetchPJCData(mobileNo, date);

        // Also fetch PJC Event data for the created date
        print('Fetching PJC Event data for the created date...');
        await fetchPJCEventData(mobileNo, date);

        return true;
      } else {
        print('FAILED: PJC Creation failed');
        createPJCSuccess(false);
        createPJCMessage.value = response.message;
        return false;
      }
    } catch (e) {
      print('ERROR in createPJC: $e');
      createPJCSuccess(false);
      createPJCMessage.value = e.toString();
      return false;
    } finally {
      isCreatingPJC(false);
    }
  }

  // Get events for specific date
  List<PJCData> getEventsForDate(DateTime date) {
    final events = pjcData.where((pjc) {
      try {
        String dateString = pjc.dt.trim();

        // Remove time if present
        if (dateString.contains(' ')) {
          dateString = dateString.split(' ')[0];
        }

        DateTime apiDate;

        // Try MM/dd/yyyy (e.g. 12/25/2025)
        if (dateString.contains('/')) {
          apiDate = DateFormat('MM/dd/yyyy').parse(dateString);
        }
        // Try dd-MMM-yyyy (e.g. 25-Dec-2025)
        else {
          apiDate = DateFormat('dd-MMM-yyyy').parse(dateString);
        }

        return isSameDay(apiDate, date);
      } catch (e) {
        print('Error parsing date for PJC: ${pjc.dt}, Error: $e');
        return false;
      }
    }).toList();

    print('Found ${events.length} events for date: $date');
    return events;
  }

  // List<PJCData> getEventsForDate(DateTime date) {
  //   final events = pjcData.where((pjc) {
  //     try {
  //       String dateString = pjc.dt;
  //       if (dateString.contains(' ')) {
  //         dateString = dateString.split(' ')[0];
  //       }
  //
  //       final apiDate = DateFormat('dd-MMM-yyyy').parse(dateString);
  //       return isSameDay(apiDate, date);
  //     } catch (e) {
  //       print('Error parsing date for PJC: ${pjc.dt}, Error: $e');
  //       return false;
  //     }
  //   }).toList();
  //
  //   print('Found ${events.length} events for date: $date');
  //   return events;
  // }

  // Update selected date
  void updateSelectedDate(DateTime newDate) {
    if (isDateSelectable(newDate)) {
      selectedDate.value = newDate;
      print('Selected date updated to: $newDate');
    } else {
      print('Date $newDate is not selectable');
      CustomSnackBar.show(
        message: 'You can only select dates from today to next $allowedDays days',
        isError: true,
      );
    }
  }

  // Reset PJC creation state
  void resetPJCCreationState() {
    isCreatingPJC(false);
    createPJCMessage('');
    createPJCSuccess(false);
  }
}
