import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../model/tour_advance_expense_model.dart';
import '../repository/tour_advance_expense_repository.dart';

class TourAdvanceExpenseController extends GetxController {
  final TourAdvanceExpenseRepository _repository =
      TourAdvanceExpenseRepository();

  // ── List screen state ───────────────────────────────────────────────
  var isLoading = false.obs;
  var expenseList = <TourAdvanceExpenseItem>[].obs;

  // Date range filter (default: today for both)
  var fromDate = DateTime.now().obs;
  var toDate = DateTime.now().obs;

  // ── Form state ──────────────────────────────────────────────────────
  var isSubmitting = false.obs;
  var requestDate = DateTime.now().obs;   // selected date in the Add/Edit form

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final remarkController = TextEditingController();

  /// The item being edited (null = add mode)
  TourAdvanceExpenseItem? editingItem;

  // ── Request-date formatted ──────────────────────────────────────────
  String get requestDtFormatted =>
      DateFormat('dd-MMM-yyyy').format(requestDate.value);

  // ── User info ───────────────────────────────────────────────────────
  String get empId => LocalDbController.to.empId;
  String get userName => LocalDbController.to.usersName;

  // ── Formatted date helpers ──────────────────────────────────────────
  String get fromDtFormatted =>
      DateFormat('dd-MMM-yyyy').format(fromDate.value);
  String get toDtFormatted => DateFormat('dd-MMM-yyyy').format(toDate.value);

  @override
  void onInit() {
    super.onInit();
    fetchList();
  }

  @override
  void onClose() {
    amountController.dispose();
    remarkController.dispose();
    super.onClose();
  }

  // ── Fetch List ───────────────────────────────────────────────────────
  Future<void> fetchList() async {
    isLoading.value = true;
    try {
      final result = await _repository.fetchExpenses(
        fromDt: fromDtFormatted,
        toDt: toDtFormatted,
      );
      expenseList.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Date setters (date picker is shown in the view) ──────────────────
  void setFromDate(DateTime picked) {
    fromDate.value = picked;
    if (toDate.value.isBefore(picked)) toDate.value = picked;
    fetchList();
  }

  void setToDate(DateTime picked) {
    toDate.value = picked;
    fetchList();
  }

  // ── Request date setter (shown in view) ─────────────────────────────
  void setRequestDate(DateTime picked) {
    requestDate.value = picked;
  }

  // ── Open Add Form ─────────────────────────────────────────────────────
  void openAddForm() {
    editingItem = null;
    requestDate.value = DateTime.now();
    amountController.clear();
    remarkController.clear();
  }

  // ── Open Edit Form ────────────────────────────────────────────────────
  void openEditForm(TourAdvanceExpenseItem item) {
    editingItem = item;
    // Parse request date from the record
    try {
      requestDate.value =
          DateFormat('M/d/yyyy h:mm:ss a').parse(item.requestDt);
    } catch (_) {
      try {
        requestDate.value = DateTime.parse(item.requestDt);
      } catch (_) {
        requestDate.value = DateTime.now();
      }
    }
    // Parse amount — remove trailing zeros
    try {
      final amount = double.parse(item.advanceAmount);
      amountController.text = amount == amount.truncate()
          ? amount.toInt().toString()
          : amount.toString();
    } catch (_) {
      amountController.text = item.advanceAmount;
    }
    remarkController.text = item.remarks;
  }

  // ── Submit (Insert or Update) ─────────────────────────────────────────
  Future<void> submitForm() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSubmitting.value = true;
    try {
      final dateStr = requestDtFormatted;   // uses the date picker value
      Map<String, dynamic> res;

      if (editingItem == null) {
        // INSERT
        res = await _repository.insertExpense(
          empId: empId,
          requestDt: dateStr,
          advanceAmount: amountController.text.trim(),
          remarks: remarkController.text.trim(),
        );
      } else {
        // UPDATE
        res = await _repository.updateExpense(
          advanceExpenseId: editingItem!.advanceExpenseId,
          empId: empId,
          requestDt: dateStr,
          advanceAmount: amountController.text.trim(),
          remarks: remarkController.text.trim(),
        );
      }

      if (res['status'] == '200' || res['status'] == 200) {
        AppSnackBar.success(
          editingItem == null ? 'Expense Added' : 'Expense Updated',
          editingItem == null
              ? 'Tour advance expense saved successfully.'
              : 'Tour advance expense updated successfully.',
        );
        Get.back(); // Close form
        await fetchList(); // Refresh list
      } else {
        AppSnackBar.error(
          'Failed',
          res['message'] ?? 'Could not save expense.',
        );
      }
    } catch (e) {
      AppSnackBar.error('Error', 'Something went wrong: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
