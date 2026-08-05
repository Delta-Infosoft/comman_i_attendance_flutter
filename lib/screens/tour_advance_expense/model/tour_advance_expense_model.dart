class TourAdvanceExpenseItem {
  final String empId;
  final String employeeName;
  final String advanceAmount;
  final String remarks;
  final String requestDt;
  final String advanceExpenseId;

  TourAdvanceExpenseItem({
    required this.empId,
    required this.employeeName,
    required this.advanceAmount,
    required this.remarks,
    required this.requestDt,
    required this.advanceExpenseId,
  });

  factory TourAdvanceExpenseItem.fromJson(Map<String, dynamic> json) {
    return TourAdvanceExpenseItem(
      empId: json['EmpId']?.toString() ?? '',
      employeeName: json['Employee Name']?.toString() ?? '',
      advanceAmount: json['AdvanceAmount']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
      requestDt: json['RequestDt']?.toString() ?? '',
      advanceExpenseId: json['AdvanceExpenseId']?.toString() ?? '',
    );
  }
}
