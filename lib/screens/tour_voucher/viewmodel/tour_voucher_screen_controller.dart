import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';
import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/tour_voucher_screen_repository.dart';

class TourVoucherController extends GetxController {
  final TourVoucherRepository _repository = TourVoucherRepository();

  // Reactive state
  var isLoading = false.obs;
  var isUpdating = false.obs;
  var tourVouchers = <TourVoucherModel>[].obs;
  var errorMessage = ''.obs;
  var updateMessage = ''.obs;

  // Selected voucher for editing
  var selectedVoucher = Rxn<TourVoucherModel>();

  // Date range - allow all past and future dates (nullable to support clearing)
  final Rxn<DateTime> fromDate = Rxn<DateTime>();
  final Rxn<DateTime> toDate = Rxn<DateTime>();
  final Rxn<DateTime> _preservedFromDate = Rxn<DateTime>();
  final Rxn<DateTime> _preservedToDate = Rxn<DateTime>();
  final RxBool _shouldUsePreservedDates = false.obs;

  // Preserve dates method
  void preserveSelectedDates(DateTime? fromDateVal, DateTime? toDateVal) {
    _preservedFromDate.value = fromDateVal;
    _preservedToDate.value = toDateVal;
    _shouldUsePreservedDates.value = true;
  }

  // Restore dates method
  void restorePreservedDates() {
    if (_shouldUsePreservedDates.value) {
      fromDate.value = _preservedFromDate.value;
      toDate.value = _preservedToDate.value;
      _shouldUsePreservedDates.value = false;
    }
  }

  // Store logged-in mobile number
  String get loggedInMobileNo {
    // Replace this with your actual logged-in user's mobile number
    return LocalDbController.to.mobileNo; // Default for testing
  }

  // Fetch tour vouchers based on selected dates
  Future<void> fetchTourVouchers() async {
    restorePreservedDates();
    try {
      isLoading(true);
      errorMessage('');

      print('🔄 Fetching tour vouchers...');
      print('📱 MobileNo: ${LocalDbController.to.mobileNo}');
      print('📅 FromDate: ${fromDate.value}');
      print('📅 ToDate: ${toDate.value}');

      final response = await _repository.getTourVouchers(
        mobileNo: LocalDbController.to.mobileNo,
        fromDate: fromDate.value,
        toDate: toDate.value,
      );

      if (response.status == "200" && response.result != null) {
        tourVouchers.assignAll(response.result!);
        print('✅ Successfully fetched ${tourVouchers.length} vouchers');
        errorMessage(''); // Clear any previous error
      } else {
        errorMessage(response.message ?? 'Failed to fetch data');
        print('❌ Error: ${response.message}');
        tourVouchers.clear();
      }
    } catch (e) {
      errorMessage('Error: $e');
      print('❌ Exception: $e');
      tourVouchers.clear();
    } finally {
      isLoading(false);
    }
  }

  // Update tour voucher
  Future<bool> updateTourVoucher(TourVoucherModel voucher) async {
    try {
      isUpdating(true);
      updateMessage('');

      print('✏️ Updating tour voucher...');
      print('📋 ExpenseId: ${voucher.expenseId}');
      print('💰 Total: ${voucher.totalExpenses}');

      final response = await _repository.updateTourExpense(
        voucher: voucher,
        mobileNo: loggedInMobileNo,
      );

      if (response.status == "200") {
        updateMessage('Voucher updated successfully!');
        print('✅ Voucher updated successfully');

        // Refresh the list
        await fetchTourVouchers();
        return true;
      } else {
        updateMessage(response.message ?? 'Failed to update voucher');
        print('❌ Update failed: ${response.message}');
        return false;
      }
    } catch (e) {
      updateMessage('Error: $e');
      print('❌ Exception in update: $e');
      return false;
    } finally {
      isUpdating(false);
    }
  }

  // Set selected voucher for editing
  void setSelectedVoucher(TourVoucherModel voucher) {
    selectedVoucher.value = voucher;
  }

  // Clear selected voucher
  void clearSelectedVoucher() {
    selectedVoucher.value = null;
  }

  // Update a field in selected voucher
  void updateSelectedVoucherField(String field, dynamic value) {
    final voucher = selectedVoucher.value;
    if (voucher == null) return;

    switch (field) {
      case 'fromPlace':
        voucher.fromPlace = value.toString();
        break;
      case 'toPlace':
        voucher.toPlace = value.toString();
        break;
      case 'travellingBy':
        voucher.travellingBy = value.toString();
        break;
      case 'fareAmount':
        voucher.fareAmount = value.toString();
        _recalculateTotal(voucher);
        break;
      case 'lodging':
        voucher.lodging = value.toString();
        _recalculateTotal(voucher);
        break;
      case 'dailyAllowance':
        voucher.dailyAllowance = value.toString();
        _recalculateTotal(voucher);
        break;
      case 'otherExpenses':
        voucher.otherExpenses = value.toString();
        _recalculateTotal(voucher);
        break;
      case 'autoChargesDetail':
        voucher.autoChargesDetail = value.toString();
        break;
      case 'otherChargesDetail':
        voucher.otherChargesDetail = value.toString();
        break;
      case 'nighHault':
        if (value is bool) {
          voucher.nighHault = value ? 'True' : 'False';
        } else {
          voucher.nighHault = value.toString();
        }
        break;
    }

    selectedVoucher.refresh();
  }

  // Recalculate total expenses
  void _recalculateTotal(TourVoucherModel voucher) {
    try {
      double fare = double.tryParse(voucher.fareAmount ?? '0') ?? 0;
      double lodging = double.tryParse(voucher.lodging ?? '0') ?? 0;
      double allowance = double.tryParse(voucher.dailyAllowance ?? '0') ?? 0;
      double other = double.tryParse(voucher.otherExpenses ?? '0') ?? 0;
      double autoCharges = double.tryParse(voucher.autoCharges ?? '0') ?? 0;

      double total = fare + lodging + allowance + other + autoCharges;
      voucher.totalExpenses = total.toStringAsFixed(2);
    } catch (e) {
      print('❌ Error calculating total: $e');
    }
  }

  // Update from date - allow all dates
  void updateFromDate(DateTime newDate) {
    fromDate.value = newDate;
    if (toDate.value != null && fromDate.value!.isAfter(toDate.value!)) {
      toDate.value = fromDate.value;
    }
    // Auto-fetch when date changes
    fetchTourVouchers();
  }

  // Update to date - allow all dates
  void updateToDate(DateTime newDate) {
    toDate.value = newDate;
    if (fromDate.value != null && toDate.value!.isBefore(fromDate.value!)) {
      fromDate.value = toDate.value;
    }
    // Auto-fetch when date changes
    fetchTourVouchers();
  }

  // Format date for display
  String formatDateForDisplay(DateTime? date) {
    if (date == null) return 'All';
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  // Parse API date string to DateTime

  DateTime? parseApiDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final formats = [
      "MM/dd/yyyy hh:mm:ss a", // Primary
      "M/d/yyyy hh:mm:ss a",   // 3/16/2026 12:00:00 AM
      "M/d/yyyy HH:mm:ss",     // 3/16/2026 11:32:05
      "dd/MMM/yyyy HH:mm:ss a", // 16/Mar/2026 12:00:00 AM
      "dd-MMM-yyyy HH:mm:ss a", // 16-Mar-2026 12:00:00 AM
      "dd/MMM/yyyy hh:mm:ss a", // 16/Mar/2026 12:00:00 AM
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(dateStr);
      } catch (_) {
        continue;
      }
    }

    print('❌ No matching format for input -> $dateStr');
    return null;
  }

  // DateTime? parseApiDate(String dateStr) {
  //   try {
  //     // Match MM/dd/yyyy hh:mm:ss a format
  //     return DateFormat("MM/dd/yyyy hh:mm:ss a").parse(dateStr);
  //   } catch (e) {
  //     print('❌ Error parsing date: $dateStr - $e');
  //     return null;
  //   }
  // }

  // Parse API time string
  String? parseApiTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      // Handle formats like "18-Nov-2025 11:33:00"
      final parts = timeString.split(' ');
      if (parts.length >= 2) {
        final timePart = parts[1];
        final timeComponents = timePart.split(':');
        if (timeComponents.length >= 2) {
          final hour = int.parse(timeComponents[0]);
          final minute = timeComponents[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
        }
      }
      return null;
    } catch (e) {
      print('❌ Error parsing time: $timeString - $e');
      return null;
    }
  }

  // Helper method to get month number from abbreviation
  int _getMonthNumber(String monthAbbr) {
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12
    };
    return months[monthAbbr] ?? 1;
  }

  // Initialize - fetch data when controller is created
  @override
  void onInit() {
    super.onInit();
    // Fetch initial data
    fetchTourVouchers();
  }
}
