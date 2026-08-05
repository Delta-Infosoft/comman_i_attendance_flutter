import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../model/Insert_tour_voucher_model.dart';
import '../viewmodel/Insert_tour_voucher_repository.dart';

class TourScreenVoucherController extends GetxController {
  // Dependencies
  final TourVoucherRepository _repository = TourVoucherRepository();

  // State Observables
  final RxList<TravelByItem> travelOptions = <TravelByItem>[].obs;
  final Rx<TravelByItem?> selectedTravelOption = Rx<TravelByItem?>(null);
  final RxBool isLoading = false.obs;
  final RxInt noOfDays = 0.obs; // For date restriction
  final RxBool allowPJC = false.obs; // To lock/unlock form
  final RxBool isCheckingValidation = false.obs;
  final RxString newPJCId = ''.obs;
  final RxBool isLoadingNewPJCId = false.obs;
  final RxList<UploadedDocument> uploadedDocuments = <UploadedDocument>[].obs;
  final RxBool isUploadingDocument = false.obs;
  final RxBool isLoadingDocuments = false.obs;
  final RxBool isSubmittingForm = false.obs;
  final RxString submissionStatus = ''.obs;
  final RxString submissionMessage = ''.obs;

  /// true = 'P' (Present) → allow submit; false = 'A' (Absent) → block submit
  final RxBool isAttendancePresent = false.obs;

  // Data
  String empIdForBackDatedRights = '';

  // Computed Properties
  String get selectedTravelText => selectedTravelOption.value?.text ?? '';
  bool get isTravelOptionSelected => selectedTravelOption.value != null;

  // Lifecycle
  @override
  void onInit() {
    super.onInit();
    _fetchTravelOptions();
  }

  // ---------------------------------------------------------------------------
  // Date Methods
  // ---------------------------------------------------------------------------

  /// Check if a date is allowed based on back-dated rights
  bool isDateAllowed(DateTime date) {
    if (noOfDays.value == 0) return true;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfSelectedDate = DateTime(date.year, date.month, date.day);

    // Cannot select future dates
    if (startOfSelectedDate.isAfter(startOfToday)) return false;

    // Calculate minimum allowed date
    final minDate = now.subtract(Duration(days: noOfDays.value));
    final startOfMinDate = DateTime(minDate.year, minDate.month, minDate.day);

    return !startOfSelectedDate.isBefore(startOfMinDate);
  }

  // ---------------------------------------------------------------------------
  // API Methods
  // ---------------------------------------------------------------------------

  /// 1. Get back-dated rights when date picker opens
  Future<void> getBackDatedRights() async {
    try {
      _logInfo('Getting back dated rights...');

      // Get empId from LocalDbController if not already set
      String empId = empIdForBackDatedRights;
      if (empId.isEmpty) {
        final localDb = Get.find<LocalDbController>();
        empId = localDb.empId;
        empIdForBackDatedRights = empId;
      }

      if (empId.isEmpty) {
        _logWarning('EmpId is empty, cannot fetch back-dated rights');
        return;
      }

      final days = await _repository.getBackDatedRights(empId);
      noOfDays.value = days;
      _logSuccess('Back dated rights set to: ${noOfDays.value} days');
    } catch (e) {
      _logError('Failed to get back dated rights', e);
      noOfDays.value = 0;
    }
  }

  /// 2. & 3. Check entry validation + Get allow tour without PJC
  Future<bool> checkTourValidation({
    required String mobileNo,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      isCheckingValidation.value = true;
      _logInfo('Starting tour validation process...');

      // Step 2a: Call Check Entry Validation API for PJC
      final pjcEmpId = await _repository.checkEntryValidation(
        mobileNo: mobileNo,
        type: 'CHECK_PJC',
        fromDate: fromDate,
        toDate: toDate,
        currentDate: fromDate,
      );

      _logInfo('Extracted EmpId from PJC Check: "$pjcEmpId"');

      // Step 2b: Call Check Entry Validation API for Daily Tour Details
      final dtdEmpId = await _repository.checkEntryValidation(
        mobileNo: mobileNo,
        type: 'CHECK_DAILY_TOUR_DETAILS',
        fromDate: fromDate,
        toDate: toDate,
        currentDate: fromDate,
      );

      _logInfo('Extracted EmpId from DTD Check: "$dtdEmpId"');

      // Validation successful only if both return a valid EmpId
      if (pjcEmpId.isNotEmpty && dtdEmpId.isNotEmpty) {
        empIdForBackDatedRights = pjcEmpId;
        _logSuccess('Both PJC and DTD found! Validation successful.');
        allowPJC.value = true;
        return true;
      }

      _logWarning('Validation failed: PJC="$pjcEmpId", DTD="$dtdEmpId"');

      // Step 3: Call Get Allow Tour Without PJC API as fallback
      // Use stored empId from local database if available
      final storedEmpId = Get.find<LocalDbController>().empId;
      final isAllowed = await _repository.getAllowTourWithoutPJC(storedEmpId);
      _logSuccess('Fallback validation result: AllowPJC = $isAllowed');

      allowPJC.value = isAllowed;
      return isAllowed;
    } catch (e) {
      _logError('Validation error', e);
      allowPJC.value = false;
      return false;
    } finally {
      isCheckingValidation.value = false;
    }
  }

  /// Calls API_CheckAttendanceStatus.aspx for the given date.
  /// Updates [isAttendancePresent] and returns true if AttnStatus == 'P'.
  Future<bool> checkAttendanceStatus({
    required String mobileNo,
    required String date,
  }) async {
    try {
      _logInfo('checkAttendanceStatus → MobileNo: $mobileNo, Date: $date');
      final isPresent = await _repository.checkAttendanceStatus(
        mobileNo: mobileNo,
        date: date,
      );
      isAttendancePresent.value = isPresent;
      _logInfo('AttnStatus isPresent: $isPresent');
      return isPresent;
    } catch (e) {
      _logError('checkAttendanceStatus error', e);
      isAttendancePresent.value = false;
      return false;
    }
  }

  /// 4. Get travel options
  Future<void> _fetchTravelOptions() async {
    try {
      isLoading.value = true;
      final options = await _repository.getTravelOptions();
      travelOptions.value = options;
    } catch (e) {
      _logError('Failed to load travel options', e);
      travelOptions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 5. Get new ID for PJC
  Future<void> getNewIdForPJC() async {
    try {
      isLoadingNewPJCId.value = true;
      _logInfo('Getting new ID for PJC...');

      final String? id = await _repository.getNewIdForPJC();

      if (id != null && id.isNotEmpty) {
        newPJCId.value = id;
        _logSuccess('New PJC ID set: $id');
      } else {
        newPJCId.value = '';
        _logWarning('Failed to get new PJC ID');
      }
    } catch (e) {
      _logError('Error getting new PJC ID', e);
      newPJCId.value = '';
    } finally {
      isLoadingNewPJCId.value = false;
    }
  }

  /// Upload document
  Future<String?> uploadDocument({
    required File file,
    required String userId,
    required String recordId,
  }) async {
    try {
      isUploadingDocument.value = true;

      final attachmentType = _getAttachmentType(file.path);
      _logInfo('Uploading document: ${file.path}');

      final response = await _repository.uploadDocument(
        file: file,
        attachmentType: attachmentType,
        userId: userId,
        recordId: recordId,
      );

      if (response.status == '200') {
        _logSuccess(
            'Document uploaded successfully! ID: ${response.result.id}');

        // Refresh document list after upload
        await getUploadedDocuments(
          attachmentType: attachmentType,
          recordId: recordId,
        );

        return response.result.id;
      }

      return null;
    } catch (e) {
      _logError('Error uploading document', e);
      _showErrorSnackbar('Upload Failed', 'Failed to upload document');
      return null;
    } finally {
      isUploadingDocument.value = false;
    }
  }

  /// Get uploaded documents with fallback logic
  Future<void> getUploadedDocuments({
    required String recordId,
    required String attachmentType,
  }) async {
    try {
      isLoadingDocuments.value = true;
      _logInfo('Getting uploaded documents for RecordId: $recordId');

      UploadedDocListResponse response;

      try {
        // First try with "TravelVoucher"
        response = await _repository.getUploadedDocList(
          attachmentType: '',
          recordId: recordId,
        );
      } catch (e) {
        _logWarning('First attempt failed, trying alternative');
        response = await _repository.getUploadedDocList(
          recordId: recordId,
          attachmentType: '',
        );
      }

      _logInfo('API Response Status: ${response.status}');
      _logInfo('API Response Message: ${response.message}');

      if (response.status == '200') {
        uploadedDocuments.value = response.result;
        _logSuccess('Found ${uploadedDocuments.length} uploaded documents');

        // Log document details
        if (uploadedDocuments.isNotEmpty) {
          for (var doc in uploadedDocuments) {
            _logInfo('Document: ${doc.fileName} (${doc.file1})');
          }
        }
      } else {
        uploadedDocuments.clear();
        _logWarning('No documents found or API error: ${response.message}');
      }
    } catch (e) {
      _logError('Error getting uploaded documents', e);
      uploadedDocuments.clear();
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Insert tour expense
  Future<InsertTourExpenseResponse?> insertTourExpense({
    required InsertTourExpenseRequest request,
  }) async {
    try {
      isSubmittingForm.value = true;
      _logInfo('Calling InsertTourExpense API...');

      // Log request data
      _logRequestData(request);

      final response = await _repository.insertTourExpense(request: request);

      _logInfo('API Response Received:');
      _logInfo('  Status: ${response.status}');
      _logInfo('  Message: ${response.message}');
      _logInfo('  Result ID: ${response.result.id}');

      if (response.status == '200') {
        _logSuccess('Tour expense saved successfully!');
        return response;
      } else {
        // _logError('API returned error status: ${response.status}');
        return null;
      }
    } catch (e) {
      _handleInsertTourExpenseError(e);
      return null;
    } finally {
      isSubmittingForm.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  /// Get formatted current date as dd-MMM-yyyy

  /// Determine attachment type from file extension
  String _getAttachmentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    final Map<String, String> typeMapping = {
      'jpg': 'Image',
      'jpeg': 'Image',
      'png': 'Image',
      'gif': 'Image',
      'bmp': 'Image',
      'pdf': 'PDF',
      'doc': 'Word Document',
      'docx': 'Word Document',
      'xls': 'Excel Sheet',
      'xlsx': 'Excel Sheet',
      'txt': 'Text File',
    };

    return typeMapping[extension] ?? 'Other';
  }

  // ---------------------------------------------------------------------------
  // UI Methods
  // ---------------------------------------------------------------------------

  void setSelectedTravelOption(TravelByItem? value) {
    selectedTravelOption.value = value;
  }

  void resetValidation() {
    allowPJC.value = false;
  }

  // ---------------------------------------------------------------------------
  // Logging & Error Handling
  // ---------------------------------------------------------------------------

  void _logInfo(String message) => print('ℹ️ $message');
  void _logSuccess(String message) => print('✅ $message');
  void _logWarning(String message) => print('⚠️ $message');
  void _logError(String context, Object error) => print('❌ $context: $error');

  void _logRequestData(InsertTourExpenseRequest request) {
    final formData = request.toJson();
    _logInfo('Request Data (FormData format):');
    formData.forEach((key, value) => _logInfo('  $key: "$value"'));
  }

  void _handleInsertTourExpenseError(Object e) {
    _logError('Error in insertTourExpense controller', e);
    _logError('Error type', e.runtimeType);

    if (e is DioException) {
      _logError('DioException details', '''
        Type: ${e.type}
        Message: ${e.message}
        Response: ${e.response?.data}
        Status: ${e.response?.statusCode}
      ''');
    }
  }

  void _showErrorSnackbar(String title, String message) {
    CustomSnackBar.show(
      message: message,
      isError: true,
    );
  }

  final RxBool isDeletingDocument = false.obs;

  Future<bool> deleteDocument({
    required String recordId,
    required String fuId,
    required String attachmentType,
  }) async {
    try {
      isDeletingDocument.value = true;
      _logInfo('Deleting document → RecordId: "", FUId: $fuId');

      final success = await _repository.deleteUploadedDocument(
        recordId: '',
        fuId: fuId,
      );

      if (success) {
        _logSuccess('Document deleted successfully');
        // Refresh document list using the actual record ID
        await getUploadedDocuments(
          attachmentType: attachmentType,
          recordId: recordId,
        );
        CustomSnackBar.show(
          message: 'Document deleted successfully',
        );
      } else {
        _logWarning('Delete failed or returned non-200');
        _showErrorSnackbar('Delete Failed', 'Could not delete the document');
      }

      return success;
    } catch (e) {
      _logError('Error deleting document', e);
      _showErrorSnackbar('Delete Failed', 'Failed to delete document');
      return false;
    } finally {
      isDeletingDocument.value = false;
    }
  }
}
