import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/view/daily_tour_details_screen.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/view/project_journey_cycle.dart';
import '../../../constant/api_url/api_url.dart';
import '../../project_journey_cycle/model/project_journey_model.dart';
import '../../project_journey_cycle/view/create_project_journey_cycle.dart';
import '../model/DTD_model.dart';
import '../viewmodel/DTD_repository.dart';
import 'package:http/http.dart' as http;

class DTDController extends GetxController {
  final DTDRepository repository;

  DTDController({required this.repository});

  final RxBool isLoading = false.obs;
  final RxBool isFormEnabled = false.obs;
  final RxList<PJCResult> pjcResults = <PJCResult>[].obs;

  /// true = 'P' (Present) → allow submit; false = 'A' (Absent) → block submit
  final RxBool isAttendancePresent = false.obs;

  var errorMessage = ''.obs;
  var backDatedRights = Rxn<BackDatedRights>();


  // Districts related observables
  final RxList<District> districts = <District>[].obs;
  final RxBool isLoadingDistricts = false.obs;
  final RxString districtErrorMessage = ''.obs;

  var selectedDate = Rxn<DateTime>();
  var startTime = Rxn<TimeOfDay>();
  var endTime = Rxn<TimeOfDay>();

  // Dealer categories related observables
  final RxList<TextListItem> dealerCategories = <TextListItem>[].obs;
  final RxBool isLoadingDealerCategories = false.obs;
  final RxString dealerCategoryErrorMessage = ''.obs;
  final RxMap<String, DateTime?> followUpDates = <String, DateTime?>{}.obs;
  final TextEditingController paymentAmountController = TextEditingController();

  // Weekly Details related observables
  final RxList<dynamic> weeklyDetailsData = <dynamic>[].obs;
  final RxString weeklyDetailsMessage = ''.obs;
  final RxBool isLoadingWeeklyDetails = false.obs;
  final Rxn<DateTime> filterFromDate = Rxn<DateTime>();
  final Rxn<DateTime> filterToDate = Rxn<DateTime>();

  // Method to get logged-in user's mobile number
  String get _userMobileNo {
    // TODO: Replace with your actual user session management
    return LocalDbController.to.mobileNo; // This should come from your login system
  }

  @override
  void onInit() {
    super.onInit();
    print('🔄 DTDController initialized');
    loadDistricts();
    loadDealerCategories();
    fetchWeeklyDetailsForDisplay();
  }

  Future<void> loadDistricts() async {
    try {
      isLoadingDistricts.value = true;
      districtErrorMessage.value = '';
      print('🔄 Loading districts...');

      final districtsList = await repository.getDistricts();
      districts.assignAll(districtsList);

      if (districts.isEmpty) {
        districtErrorMessage.value = 'No districts found';
      } else {
        districtErrorMessage.value = '';
        print('✅ Loaded ${districts.length} districts');
      }
    } catch (e) {
      print('❌ Error loading districts: $e');
      districtErrorMessage.value = 'Failed to load districts';
      districts.clear();
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  Future<void> loadDealerCategories() async {
    try {
      isLoadingDealerCategories.value = true;
      dealerCategoryErrorMessage.value = '';
      print('🔄 Loading dealer categories...');

      final categoriesList = await repository.getDealerCategories();
      dealerCategories.assignAll(categoriesList);

      if (dealerCategories.isEmpty) {
        dealerCategoryErrorMessage.value = 'No dealer categories found';
        _addFallbackCategories();
      } else {
        dealerCategoryErrorMessage.value = '';
        print('✅ Loaded ${dealerCategories.length} dealer categories');
      }
    } catch (e) {
      print('❌ Error loading dealer categories: $e');
      dealerCategoryErrorMessage.value = 'Failed to load dealer categories';
      _addFallbackCategories();
    } finally {
      isLoadingDealerCategories.value = false;
    }
  }

  void _addFallbackCategories() {
    print('🔄 Adding fallback dealer categories...');
    dealerCategories.assignAll([
      TextListItem(textListId: '1', text: 'Borer'),
      TextListItem(textListId: '2', text: 'Company Dealer'),
      TextListItem(textListId: '3', text: 'Competitor Dealer'),
      TextListItem(textListId: '4', text: 'Distributor'),
      TextListItem(textListId: '5', text: 'End Customer'),
      TextListItem(textListId: '6', text: 'Government'),
    ]);
  }

  Future<void> checkEntryValidation({
    required String date,
    required String mobileNo,
    bool showLoader = true,
  }) async {
    try {
      if (showLoader) {
        isLoading.value = true;
        isFormEnabled.value = false;
      }

      final req = CheckEntryValidationRequest(
        mobileNo: mobileNo,
        type: 'CHECK_PJC',
        date: date,
      );

      final res = await repository.checkEntryValidation(req);

      if (res.status == '200' && res.result.isNotEmpty) {
        // PJC found for this date!
        print("✅ PJC found for $date. Enabling form.");
        isFormEnabled.value = true;
        pjcResults.assignAll(res.result);
        
        // Also update empId context if needed
        String empId = res.result.first.empId;
        print("🔥 EmpId from CheckEntryValidation = $empId");
      } else {
        // No PJC found or error status
        print("⚠️ No PJC found for $date. Checking AllowPJC fallback...");
        final empId = Get.find<LocalDbController>().empId;
        await _checkAllowTourWithoutPJC(empId);
      }
    } catch (e) {
      print("❌ Error in checkEntryValidation: $e");
      final empId = Get.find<LocalDbController>().empId;
      await _checkAllowTourWithoutPJC(empId);
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  /// Calls API_CheckAttendanceStatus.aspx and updates [isAttendancePresent].
  /// Returns true if status is 'P', false if 'A' or on any error.
  Future<bool> checkAttendanceStatus({
    required String mobileNo,
    required String date,
  }) async {
    try {
      print('🔄 checkAttendanceStatus → MobileNo: $mobileNo, Date: $date');
      final req = CheckAttendanceStatusRequest(
        mobileNo: mobileNo,
        date: date,
      );
      final res = await repository.checkAttendanceStatus(req);
      print('📋 AttnStatus: ${res.result.isNotEmpty ? res.result.first.attnStatus : "N/A"}');
      isAttendancePresent.value = res.isPresent;
      return res.isPresent;
    } catch (e) {
      print('❌ Error in checkAttendanceStatus: $e');
      isAttendancePresent.value = false;
      return false;
    }
  }

  // Future<void> checkEntryValidation({
  //   required String date,
  //   required String mobileNo,
  // }) async {
  //   try {
  //     isLoading.value = true;
  //     isFormEnabled.value = false;
  //
  //     final userMobile = _userMobileNo;
  //     final request = CheckEntryValidationRequest(
  //       mobileNo: userMobile,
  //       type: 'CHECK_PJC',
  //       date: date,
  //     );
  //
  //     final response = await repository.checkEntryValidation(request);
  //
  //     if (response.status == '200') {
  //       isFormEnabled.value = true;
  //       pjcResults.value = response.result;
  //       print('✅ Entry validation successful');
  //     } else {
  //       await _checkAllowTourWithoutPJC();
  //     }
  //   } catch (e) {
  //     await _checkAllowTourWithoutPJC();
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }


  // Future<BackDatedRightsResponse> getBackDatedRights(String empId) async {
  //   try {
  //     print('Starting getBackDatedRights API call');
  //
  //     final url = '${ApiUrl.GetBack_DatedRights}?EmpId=$empId';
  //     print('URL: $url');
  //
  //     final response =
  //     await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
  //
  //     print('Response Status: ${response.statusCode}');
  //     print('Response Body: ${response.body}');
  //
  //     if (response.statusCode == 200) {
  //       print('✅ API call successful, processing response...${response}');
  //       try {
  //         String responseBody = response.body;
  //         if (responseBody.contains('{') && responseBody.contains('}')) {
  //           final jsonStart = responseBody.indexOf('{');
  //           final jsonEnd = responseBody.lastIndexOf('}') + 1;
  //           responseBody = responseBody.substring(jsonStart, jsonEnd);
  //         }
  //
  //         final Map<String, dynamic> responseData = json.decode(responseBody);
  //         print('BAck Date Rights Parsed Response>>>>>>>>>>: $responseData');
  //
  //         final backDatedRightsResponse =
  //         BackDatedRightsResponse.fromJson(responseData);
  //
  //         if (backDatedRightsResponse.status == "200") {
  //           print('Back-dated rights loaded successfully');
  //           return backDatedRightsResponse;
  //         } else {
  //           throw Exception(
  //               'API returned error: ${backDatedRightsResponse.message}');
  //         }
  //       } catch (e) {
  //         print('JSON Parse Error: $e');
  //         throw Exception('Failed to parse API response: $e');
  //       }
  //     } else {
  //       print('API ERROR: HTTP ${response.statusCode}');
  //       throw Exception(
  //           'Failed to load back-dated rights: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('API EXCEPTION: $e');
  //     rethrow;
  //   }
  // }

  Future<void> fetchBackDatedRights() async {
    try {
      isLoading(true);
      errorMessage('');

      print('Fetching back-dated rights from API...');

      final empId = Get.find<LocalDbController>().empId;
      final response = await repository.getBackDatedRightsWithFallback(empId);

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

  Future<void> _checkAllowTourWithoutPJC(String empId) async {
    try {
      final req = AllowTourWithoutPJCRequest(empId: empId);
      final res = await repository.getAllowTourWithoutPJC(req);

      if (res.status == "200" &&
          res.result.isNotEmpty &&
          res.result.first["AllowPJC"] == "True") {
        print("✅ AllowPJC = TRUE → Unlock Form");
        isFormEnabled.value = true;
        return;
      }

      print("❌ AllowPJC = FALSE → Show warning");
      isFormEnabled.value = false;
      _showCautionSnackbar(Get.context!);
    } catch (e) {
      print("❌ Error in AllowPJC");
      isFormEnabled.value = false;
      _showCautionSnackbar(Get.context!);
    }
  }

  void _showCautionSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please complete your Project Journey Cycle first',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent.withOpacity(.9),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to JourneyCalendarScreen only when OK is tapped

            Get.off(() => CreateJourneyScreen());
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (context) => JourneyCalendarScreen(),
            //   ),
            // );
          },
        ),
      ),
    );
  }

  // Future<void> _checkAllowTourWithoutPJC() async {
  //   try {
  //     final request = AllowTourWithoutPJCRequest(empId: '999');
  //     final response = await repository.getAllowTourWithoutPJC(request);
  //     _showCautionSnackbar(Get.context!);
  //
  //     // Replace Get.offAll() with Get.off()
  //     Get.off(() => JourneyCalendarScreen());
  //   } catch (e) {
  //     _showCautionSnackbar(Get.context!);
  //
  //     // Replace Get.offAll() with Get.off()
  //     Get.off(() => JourneyCalendarScreen());
  //   }
  // }
  //
  // void _showCautionSnackbar(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: const Text(
  //         'Please complete your Project Journey Cycle first',
  //         style: TextStyle(color: Colors.white),
  //       ),
  //       backgroundColor: const Color(0xFFFFA000).withOpacity(.9),
  //       duration: const Duration(seconds: 5),
  //       behavior: SnackBarBehavior.floating,
  //       margin: const EdgeInsets.all(12),
  //       action: SnackBarAction(
  //         label: 'OK',
  //         textColor: Colors.white,
  //         onPressed: () {
  //           // Navigate when OK is pressed
  //           Navigator.of(context).push(
  //             MaterialPageRoute(
  //               builder: (context) => JourneyCalendarScreen(),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  // void _showCautionSnackbar(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: const Text(
  //         'Please complete your Project Journey Cycle first',
  //         style: TextStyle(color: Colors.white),
  //       ),
  //       backgroundColor: const Color(0xFFFFA000).withOpacity(.9),
  //       duration: const Duration(seconds: 3),
  //       behavior: SnackBarBehavior.floating,
  //       margin: const EdgeInsets.all(12),
  //     ),
  //   );
  // }

  Future<void> submitWeeklyTourDetail(Map<String, dynamic> formData) async {
    try {
      isLoading.value = true;
      print('🔄 Submitting Weekly Tour Detail...');

      final request = _convertFormDataToRequest(formData);
      final response = await repository.insertWeeklyTourDetail(request);

      if (response.status == '200') {
        print('✅ Weekly Tour Detail saved successfully!');
        Get.back(result: true); // Signal to caller (e.g. Check-Out flow) that form was submitted
        _showSuccessSnackbar();
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      _showErrorSnackbar('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessSnackbar() {
    CustomSnackBar.show(
      message: 'Form submitted successfully!',
    );
  }

  void _showErrorSnackbar(String message) {
    CustomSnackBar.show(
      message: message,
      isError: true,
      duration: const Duration(seconds: 4),
    );
  }

  WeeklyTourDetailRequest _convertFormDataToRequest(
      Map<String, dynamic> formData) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final startTime = formData['startTime'] as TimeOfDay;
    final endTime = formData['endTime'] as TimeOfDay;

    final followUpFor = formData['followUpFor'] as Map<String, bool>;
    final followUpDates = formData['followUpDates'] as Map<String, String>;

    final dealerCategoryName = formData['dealerCategory'] ?? '';
    final dealerCategoryId = _getDealerCategoryId(dealerCategoryName);
    final userMobile = _userMobileNo;

    return WeeklyTourDetailRequest(
      endTime:
          '${endTime.hourOfPeriod}:${endTime.minute.toString().padLeft(2, '0')} ${endTime.period == DayPeriod.am ? 'AM' : 'PM'}',
      paymentFollowUpDt: followUpDates['Payment Discussion'] ?? '',
      isDiscountDiscussion:
          followUpFor['Discount Discussion'] == true ? '1' : '0',
      subDealerVisitDate: followUpDates['Sub Dealer Visit'] ?? '',
      isSalesPromotionalActivity:
          followUpFor['Sales Promotional Activity'] == true ? '1' : '0',
      isNewDealerSurvey: followUpFor['New Dealer Survey'] == true ? '1' : '0',
      empMobileNo: userMobile,
      isSubDealerVisit: followUpFor['Sub Dealer Visit'] == true ? '1' : '0',
      newDealerSurveyDate: followUpDates['New Dealer Survey'] ?? '',
      pointDiscussion: formData['commonDiscussion'] ?? '',
      dealerName: formData['dealerName'] ?? '',
      isServiceOrRepairing:
          followUpFor['Service Or Repairing'] == true ? '1' : '0',
      mobileNo: userMobile,
      toPlace: formData['toPlace'] ?? '',
      paymentFollowUpAmount: formData['paymentAmount'] ?? '0',
      startTime:
          '${startTime.hourOfPeriod}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.period == DayPeriod.am ? 'AM' : 'PM'}',
      isNewDealerAppointment:
          followUpFor['New Dealer Appointment'] == true ? '1' : '0',
      typeTextListId: dealerCategoryId,
      isPaymentFollowUp: followUpFor['Payment Discussion'] == true ? '1' : '0',
      isOrderFollowUp: followUpFor['Order Discussion'] == true ? '1' : '0',
      date: dateFormat.format(formData['date']),
      businessCenter: formData['marketCentreName'] ?? '',
      area: formData['taluka'] ?? '',
      fromPlace: formData['fromPlace'] ?? '',
      isStockPlanning: followUpFor['Stock Planning'] == true ? '1' : '0',
      isSchemeDiscussion: followUpFor['Scheme Discussion'] == true ? '1' : '0',
      orderFollowUpDt: followUpDates['Order Discussion'] ?? '',
      newDealerAppointmentDt: followUpDates['New Dealer Appointment'] ?? '',
      district: formData['district'] ?? '',
    );
  }

  String _getDealerCategoryId(String categoryName) {
    if (categoryName.isEmpty) return '1aa5f007-b1ac-4db4-ba5c-a9196e0c6d81';
    try {
      final category =
          dealerCategories.firstWhere((cat) => cat.text == categoryName);
      return category.textListId.isNotEmpty
          ? category.textListId
          : '1aa5f007-b1ac-4db4-ba5c-a9196e0c6d81';
    } catch (e) {
      return '1aa5f007-b1ac-4db4-ba5c-a9196e0c6d81';
    }
  }

  Future<void> submitDTDForm(Map<String, dynamic> formData) async {
    if (!isFormEnabled.value) {
      _showErrorSnackbar('Please complete validation first');
      return;
    }

    try {
      final Map<String, String> formattedFollowUpDates = {};
      followUpDates.forEach((key, value) {
        if (value != null) {
          final followUpFor = formData['followUpFor'] as Map<String, bool>;
          if (followUpFor[key] == true) {
            formattedFollowUpDates[key] =
                DateFormat('dd-MMM-yyyy').format(value);
          }
        }
      });

      formData['followUpDates'] = formattedFollowUpDates;
      formData['paymentAmount'] = paymentAmountController.text.isNotEmpty
          ? paymentAmountController.text
          : '0';

      await submitWeeklyTourDetail(formData);
      await fetchWeeklyDetailsForDisplay();
    } catch (e) {
      _showErrorSnackbar('Failed to submit tour details: $e');
    }
  }

  Future<void> fetchWeeklyDetailsForDisplay({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      isLoadingWeeklyDetails.value = true;
      weeklyDetailsMessage.value = '';
      weeklyDetailsData.clear(); // Clear previous data

      final userMobile = _userMobileNo;

      print('🔄 Fetching tours with range: $fromDate to $toDate');
      print('📱 User Mobile: $userMobile');

      final weeklyDetailsResponse = await repository.getWeeklyDetails(
        mobileNo: userMobile,
        fromDate: fromDate ?? '',
        toDate: toDate ?? '',
      );

      print(
          '📊 API Response: ${weeklyDetailsResponse['status']} - ${weeklyDetailsResponse['message']}');

      if (weeklyDetailsResponse['status'] == 'success') {
        final List<dynamic> results = weeklyDetailsResponse['result'] ?? [];
        weeklyDetailsData.assignAll(results);

        if (results.isNotEmpty) {
          weeklyDetailsMessage.value = 'Total tours: ${results.length}';
          print('✅ SUCCESS: Loaded ${results.length} tour records');

          // Debug: Print first tour data
          if (results.isNotEmpty) {
            print('🔍 First tour data: ${results.first}');
          }
        } else {
          // Check if it's server limit message
          String message = weeklyDetailsResponse['message'] ?? '';
          if (message.contains('server cannot display')) {
            weeklyDetailsMessage.value = 'Data exists but server limit reached';
            print('📝 SERVER LIMIT: Data available but cannot be displayed');
          } else {
            weeklyDetailsMessage.value = 'No tours found';
            print('📝 INFO: No tour records found');
          }
        }
      } else {
        // Error case
        weeklyDetailsMessage.value =
            weeklyDetailsResponse['message'] ?? 'Unknown error occurred';
        print('❌ ERROR: ${weeklyDetailsResponse['message']}');
      }
    } catch (e) {
      print('❌ EXCEPTION in fetchWeeklyDetails: $e');
      weeklyDetailsMessage.value = 'Failed to load data: $e';
      weeklyDetailsData.clear();
    } finally {
      isLoadingWeeklyDetails.value = false;
    }
  }

  Future<void> refreshWeeklyDetails() async {
    final fromStr = filterFromDate.value != null
        ? DateFormat('dd-MMM-yyyy').format(filterFromDate.value!)
        : '';
    final toStr = filterToDate.value != null
        ? DateFormat('dd-MMM-yyyy').format(filterToDate.value!)
        : '';
    await fetchWeeklyDetailsForDisplay(fromDate: fromStr, toDate: toStr);
  }

  void resetForm() {
    followUpDates.clear();
    paymentAmountController.clear();
    isFormEnabled.value = false;
    pjcResults.clear();
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../model/DTD_model.dart';
// import '../viewmodel/DTD_repository.dart';

// class DTDController extends GetxController {
//   final DTDRepository repository;

//   DTDController({required this.repository});

//   final RxBool isLoading = false.obs;
//   final RxBool isFormEnabled = false.obs;
//   final RxList<PJCResult> pjcResults = <PJCResult>[].obs;

//   // Method to check entry validation when date is selected
//   Future<void> checkEntryValidation({
//     required String mobileNo,
//     required String date,
//   }) async {
//     try {
//       isLoading.value = true;
//       isFormEnabled.value = false;

//       final request = CheckEntryValidationRequest(
//         mobileNo: mobileNo,
//         type: 'CHECK_PJC',
//         date: date,
//       );

//       final response = await repository.checkEntryValidation(request);

//       if (response.status == '200') {
//         // Success - allow user to fill form
//         isFormEnabled.value = true;
//         pjcResults.value = response.result;
//       } else {
//         // First API failed, call second API
//         await _checkAllowTourWithoutPJC();
//       }
//     } catch (e) {
//       // If first API fails, try second API
//       await _checkAllowTourWithoutPJC();
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> _checkAllowTourWithoutPJC() async {
//     try {
//       // Replace '999' with actual employee ID from your storage
//       final request = AllowTourWithoutPJCRequest(empId: '999');
//       final response = await repository.getAllowTourWithoutPJC(request);

//       // Show caution snackbar and navigate to PJC
//       _showCautionSnackbar();
//       _navigateToPJCScreen();
//     } catch (e) {
//       // Even if API fails, show message and navigate
//       _showCautionSnackbar();
//       _navigateToPJCScreen();
//     }
//   }

//   void _showCautionSnackbar() {
//     Get.snackbar(
//       'Caution',
//       'Please complete your Project Journey Cycle first',
//       backgroundColor: Color(0xFFFFA000).withOpacity(.9),
//       colorText: Colors.white,
//       duration: Duration(seconds: 3),
//       snackPosition: SnackPosition.BOTTOM,
//       margin: EdgeInsets.only(bottom: 50, left: 10, right: 10),
//     );
//   }

//   void _navigateToPJCScreen() {
//     // Navigate to Project Journey Cycle screen after short delay
//     Future.delayed(Duration(milliseconds: 500), () {
//       Get.offAllNamed('/project-journey-cycle');
//     });
//   }

//   // Method to submit DTD form
//   Future<void> submitDTDForm(Map<String, dynamic> formData) async {
//     if (!isFormEnabled.value) {
//       Get.snackbar(
//         'Error',
//         'Please complete validation first',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     try {
//       isLoading.value = true;
//       // Add your DTD submission logic here
//       await Future.delayed(Duration(seconds: 2));

//       Get.snackbar(
//         'Success',
//         'Tour details submitted successfully!',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );

//       Get.back();
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to submit tour details: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void resetForm() {
//     isFormEnabled.value = false;
//     pjcResults.clear();
//   }
// }
