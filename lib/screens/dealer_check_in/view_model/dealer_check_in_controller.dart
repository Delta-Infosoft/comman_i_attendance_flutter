import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../helper/image_watermark_helper.dart';
import '../model/dealer_check_in_model.dart';
import '../repository/dealer_check_in_repository.dart';
import '../view/dual_camera_screen.dart';
import '../../daily_tour_details/view/create_daily_tour_details_screen.dart';
import '../../home/view/home_screen.dart';

class DealerCheckInController extends GetxController {
  final DealerCheckInRepository _repository = DealerCheckInRepository();

  var isLoadingCategories = false.obs;
  var isLoadingDealerNames = false.obs;
  var isCheckingStatus = false.obs;
  var isSubmitting = false.obs;
  var isCapturingPhoto = false.obs;

  var categories = <DealerCategoryModel>[].obs;
  var selectedCategory = Rxn<DealerCategoryModel>();

  var dealerNameList = <DealerNameItemModel>[].obs;
  var selectedDealerItem = Rxn<DealerNameItemModel>();
  var isManualDealerName = true.obs;

  final dealerNameController = TextEditingController();
  final remarkController = TextEditingController();

  var photoFile = Rxn<File>();
  var frontPhotoFile = Rxn<File>();
  var currentAddress = ''.obs;
  var formattedDateTime = ''.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  // Status tracking
  var isCheckedIn = false.obs;
  var activeCheckInItem = Rxn<DealerCheckInStatusItem>();
  var todayStatusList = <DealerCheckInStatusItem>[].obs;

  String get mobileNo => LocalDbController.to.mobileNo;
  String get empId {
    final storedId = LocalDbController.to.empId;
    return storedId.isNotEmpty ? storedId : '101';
  }

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    dealerNameController.dispose();
    remarkController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    await fetchCategories();
    await checkStatus();
  }

  /// 1. Fetch Categories from API
  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final list = await _repository.fetchDealerCategories();
      categories.value = list;
      // Do NOT auto-select any category — user must choose manually
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Category Selection Handler
  /// Per API spec: only "Company Dealer" and "Distributor" trigger Dealer Name dropdown.
  /// All other categories use manual text entry.
  Future<void> onCategorySelected(DealerCategoryModel category) async {
    selectedCategory.value = category;
    selectedDealerItem.value = null;
    dealerNameController.clear();
    dealerNameList.clear();

    final catText = category.text.trim();

    // Exact match for API-backed dealer name lookup
    final requiresDropdown =
        catText == 'Company Dealer' ||
        catText == 'Distributor' ||
        catText == 'New Dealer/Distributor Appointment';

    if (requiresDropdown) {
      isManualDealerName.value = false;
      await fetchDealerNames(catText);
    } else {
      isManualDealerName.value = true;
    }
  }

  /// 2. Fetch Dealer Names from API
  Future<void> fetchDealerNames(String dealerType) async {
    isLoadingDealerNames.value = true;
    try {
      final names = await _repository.fetchDealerNames(
        empId: empId,
        dealerType: dealerType,
      );
      dealerNameList.value = names;
    } finally {
      isLoadingDealerNames.value = false;
    }
  }

  /// 3. Check Dealer Check-In/Out Status
  /// Reads status from server and pre-fills form fields when user is checked in,
  /// so the screen does not appear blank when they re-open it.
  Future<void> checkStatus() async {
    isCheckingStatus.value = true;
    try {
      final list = await _repository.checkDealerStatus(mobileNo: mobileNo);
      todayStatusList.value = list;

      // Find any record where OutTime is empty (still checked-in)
      final activeItem = list.firstWhereOrNull((item) => item.isCheckedIn);

      if (activeItem != null) {
        isCheckedIn.value = true;
        activeCheckInItem.value = activeItem;

        // ── Pre-fill form fields from the active check-in data ──
        // Dealer Name
        dealerNameController.text = activeItem.dealerName.isNotEmpty
            ? activeItem.dealerName
            : activeItem.dealerCategory;

        // Remarks
        remarkController.text = activeItem.remarks;

        // Dealer Category — match from already-loaded categories list
        if (categories.isNotEmpty && activeItem.dealerCategoryId.isNotEmpty) {
          final matchedCat = categories.firstWhereOrNull(
            (c) => c.textListId == activeItem.dealerCategoryId,
          );
          if (matchedCat != null) {
            selectedCategory.value = matchedCat;
            // Set manual entry mode since we pre-filled name directly
            isManualDealerName.value = true;
          } else if (activeItem.dealerCategory.isNotEmpty) {
            // Fallback: match by category text
            final matchedByText = categories.firstWhereOrNull(
              (c) => c.text.trim().toLowerCase() ==
                     activeItem.dealerCategory.trim().toLowerCase(),
            );
            if (matchedByText != null) {
              selectedCategory.value = matchedByText;
              isManualDealerName.value = true;
            }
          }
        }
      } else {
        isCheckedIn.value = false;
        activeCheckInItem.value = null;
      }
    } finally {
      isCheckingStatus.value = false;
    }
  }

  /// Capture Photo with Dual Camera (Rear + Front) & GPS Watermark
  Future<void> captureGpsPhoto(BuildContext context) async {
    try {
      isCapturingPhoto.value = true;

      // 1. Check GPS location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackBar.warning("GPS Disabled", "Please turn on GPS location service.");
        isCapturingPhoto.value = false;
        return;
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppSnackBar.error("Permission Denied", "Location permission is required.");
          isCapturingPhoto.value = false;
          return;
        }
      }

      // 3. Launch Dual Camera screen (captures Rear first, then Front sequentially)
      final result = await Get.to<Map<String, String>>(() => const DualCameraScreen());

      if (result == null || result['back'] == null || result['back']!.isEmpty) {
        isCapturingPhoto.value = false;
        return;
      }

      final backFile = File(result['back']!);
      final frontFile = result['front'] != null && result['front']!.isNotEmpty
          ? File(result['front']!)
          : null;

      // 4. Retrieve current location & address
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = position.latitude;
      longitude.value = position.longitude;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? place.subLocality ?? '';
          final locality = place.locality ?? place.subAdministrativeArea ?? '';
          currentAddress.value = [street, locality].where((s) => s.isNotEmpty).join(', ');
        }
      } catch (_) {}

      if (currentAddress.value.isEmpty) {
        currentAddress.value =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      }

      formattedDateTime.value =
          DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now());

      // 5. Merge Rear & Front photos into 1 image and watermark with Location + Timestamp
      final mergedFile = await ImageWatermarkHelper.mergePhotosWithWatermark(
        backPhoto: backFile,
        frontPhoto: frontFile,
        address: currentAddress.value,
        dateTime: formattedDateTime.value,
      );

      photoFile.value = mergedFile;
      frontPhotoFile.value = frontFile;

    } catch (e) {
      AppSnackBar.error("Capture Error", "Failed to capture photo: $e");
    } finally {
      isCapturingPhoto.value = false;
    }
  }

  /// Main Button Press (Check-In or Check-Out)
  Future<void> handleMainActionButton(BuildContext context) async {
    if (isCheckedIn.value) {
      await _handleCheckOutFlow(context);
    } else {
      await _handleCheckInSubmit(context);
    }
  }

  /// Perform Check-In
  Future<void> _handleCheckInSubmit(BuildContext context) async {
    if (selectedCategory.value == null) {
      AppSnackBar.warning("Category Required", "Please select a Dealer Category.");
      return;
    }

    String finalDealerName = isManualDealerName.value
        ? dealerNameController.text.trim()
        : (selectedDealerItem.value?.dealerName ?? dealerNameController.text.trim());

    if (finalDealerName.isEmpty) {
      AppSnackBar.warning("Dealer Name Required", "Please select or enter the Dealer Name.");
      return;
    }

    if (photoFile.value == null) {
      AppSnackBar.warning("Photo Required", "Please capture a GPS photo for Check-In.");
      return;
    }

    // Ensure GPS position
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        latitude.value = position.latitude;
        longitude.value = position.longitude;
      } catch (_) {}
    }

    isSubmitting.value = true;
    try {
      final nowStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now());

      final res = await _repository.submitDealerCheckInOut(
        dealerCategory: selectedCategory.value!.text,
        mobileNo: mobileNo,
        dealerCategoryId: selectedCategory.value!.textListId,
        dealerName: finalDealerName,
        dealerId: selectedDealerItem.value?.dealerId ?? '',
        lat: latitude.value.toString(),
        long: longitude.value.toString(),
        remarks: remarkController.text.trim(),
        inTime: nowStr,
        outTime: '', // Check-In -> empty OutTime
        photoFile: photoFile.value,
        frontPhotoFile: frontPhotoFile.value,
      );
      print('CHeck in photo>>>>>>: ${photoFile.value}');

      if (res['status'] == "200" || res['status'] == 200) {
        AppSnackBar.success("Check-In Successful", "Client Check-In recorded successfully.");
        // Navigate back to Home screen after successful Check-In
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAll(() => const HomeScreen());
      } else {
        AppSnackBar.error("Check-In Failed", res['message'] ?? "Failed to save check-in.");
      }
    } catch (e) {
      AppSnackBar.error("Error", "Check-in failed: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Perform Check-Out Flow
  Future<void> _handleCheckOutFlow(BuildContext context) async {
    // Ensure GPS position even if photo was not captured
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        latitude.value = position.latitude;
        longitude.value = position.longitude;
      } catch (_) {}
    }

    final active = activeCheckInItem.value;

    // Use server-confirmed data from activeCheckInItem as the authoritative source.
    // Fall back to form fields only if no active item found.
    final catText = active?.dealerCategory.isNotEmpty == true
        ? active!.dealerCategory
        : (selectedCategory.value?.text ?? '');
    final catId = active?.dealerCategoryId.isNotEmpty == true
        ? active!.dealerCategoryId
        : (selectedCategory.value?.textListId ?? '');
    final nameText = active?.dealerName.isNotEmpty == true
        ? active!.dealerName
        : dealerNameController.text.trim();
    final dealerIdText = active?.dealerId ?? selectedDealerItem.value?.dealerId ?? '';

    // Build tourData to pre-fill Daily Tour Details screen
    final tourData = {
      'date': DateTime.now(),          // Today's date pre-filled
      'dealerCategory': catText,       // From active check-in
      'dealerName': nameText,          // From active check-in
      'mobileNo': mobileNo,
      'startTime': TimeOfDay.now(),
      'endTime': TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24),
    };

    // ── Step 2: Open Daily Tour Details screen pre-filled. ──
    // User MUST complete and submit the form before Check-Out proceeds.
    final result = await Get.to<bool>(
      () => CreateEditTourScreen(tourData: tourData),
    );

    // If user did not submit (pressed back without saving), abort Check-Out
    if (result != true) {
      AppSnackBar.info(
        "Daily Tour Required",
        "Please complete and submit the Daily Tour Details form to proceed with Check-Out.",
        context: context,
      );
      return;
    }

    // ── Step 3: Submit Check-Out to API ──
    isSubmitting.value = true;
    try {
      final nowStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now());

      final res = await _repository.submitDealerCheckInOut(
        dealerCategory: catText,
        mobileNo: mobileNo,
        dealerCategoryId: catId,
        dealerName: nameText,
        dealerId: dealerIdText,
        lat: latitude.value.toString(),
        long: longitude.value.toString(),
        remarks: remarkController.text.trim(),
        inTime: '', // Check-Out -> empty InTime
        outTime: nowStr,
        photoFile: photoFile.value,
        frontPhotoFile: frontPhotoFile.value,
      );

      if (res['status'] == "200" || res['status'] == 200) {
        AppSnackBar.success("Check-Out Successful", "Client Check-Out completed successfully.");
        // Navigate back to Home screen after successful Check-Out
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAll(() => const HomeScreen());
      } else {
        AppSnackBar.error("Check-Out Failed", res['message'] ?? "Failed to save check-out.");
      }
    } catch (e) {
      AppSnackBar.error("Error", "Check-out failed: $e");
    } finally {
      isSubmitting.value = false;
    }
  }
}
