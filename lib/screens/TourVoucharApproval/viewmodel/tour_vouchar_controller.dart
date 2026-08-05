import 'package:flutter/material.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/TourVoucharApproval/model/tour_vouchar_model.dart';
import 'package:waterman_iattandance/screens/TourVoucharApproval/viewmodel/tour_vouchar_repository.dart';

class TourExpenseController extends ChangeNotifier {

  final TourExpenseRepositoryAlternative _repository =
  TourExpenseRepositoryAlternative();

  List<TourExpenseModel> _tourExpenses = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedFromDate = '';
  String _selectedToDate = '';

  List<TourExpenseModel> get tourExpenses => _tourExpenses;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void updateSelectedDates(String fromDate, String toDate) {
    _selectedFromDate = fromDate;
    _selectedToDate = toDate;
  }

  Future<void> fetchTourExpenseData(String mobileNo) async {

    if (_selectedFromDate.isEmpty || _selectedToDate.isEmpty) {
      _errorMessage = "Please select both dates";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {

      final response = await _repository.fetchTourExpenseData(
        mobileNo: mobileNo,
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
      );

      print("API RESPONSE : $response");

      if (response["status"] == "200") {

        List data = response["result"];

        _tourExpenses = data.map<TourExpenseModel>((item) {

          return TourExpenseModel(
            expenseId: item["ExpenseId"]?.toString() ?? "",
            fromDate: item["TravelDt"] ?? "",
            toDate: item["TravelToDt"] ?? "",
            persons: [
              Person(
                name: item["FromPlace"] ?? "",
                time: item["StartTime"] ?? "",
              ),
              Person(
                name: item["ToPlace"] ?? "",
                time: item["EndTime"] ?? "",
              )
            ],
            transportType: item["TravellingBy"] ?? "",
            totalAmount: item["TotalExpenses"] ?? "0",
            status: item["ApprovedDisapproved"] ?? "Pending",
            remarks: item["OtherChargesDetail"] ?? "",
          );

        }).toList();

        print("Parsed list length: ${_tourExpenses.length}");

      } else {

        _errorMessage = response["message"] ?? "No data found";
        _tourExpenses = [];

      }

    } catch (e) {

      print("Controller Error: $e");
      _errorMessage = "Failed to load data";

    }

    _isLoading = false;
    notifyListeners();
  }

  void updateExpenseStatus(int index, String newStatus) {
    if (index >= 0 && index < _tourExpenses.length) {
      _tourExpenses[index].status = newStatus;
      notifyListeners();
    }
  }

  Future<void> submitTourApproval(int index) async {
    if (index < 0 || index >= _tourExpenses.length) return;

    final expense = _tourExpenses[index];
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final empId = LocalDbController.to.empId;

      final response = await _repository.submitApproval(
        empId: empId,
        expenseId: expense.expenseId,
        status: expense.status,
        remarks: expense.remarks,
      );

      if (response["status"] == "200") {
        // Success
        _errorMessage = "Submitted successfully";
        _tourExpenses.removeAt(index);
      } else {
        _errorMessage = response["message"] ?? "Submission failed";
      }
    } catch (e) {
      print("Submission Error: $e");
      _errorMessage = "Failed to submit approval";
    }

    _isLoading = false;
    notifyListeners();
  }
}