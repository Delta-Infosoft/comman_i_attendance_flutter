// tour_expense_model.dart
class TourExpenseModel {
  final String expenseId;
  final String fromDate;
  final String toDate;
  final List<Person> persons;
  final String transportType;
  final String totalAmount;
  String status;
  final String remarks;

  TourExpenseModel({
    required this.expenseId,
    required this.fromDate,
    required this.toDate,
    required this.persons,
    required this.transportType,
    required this.totalAmount,
    required this.status,
    required this.remarks,
  });

  factory TourExpenseModel.fromJson(Map<String, dynamic> json) {
    // Adjust this parsing based on your actual API response structure
    return TourExpenseModel(
      expenseId: json['ExpenseId'] ?? '',
      fromDate: json['FromDate'] ?? '',
      toDate: json['ToDate'] ?? '',
      persons: (json['Persons'] as List? ?? [])
          .map((person) => Person.fromJson(person))
          .toList(),
      transportType: json['TransportType'] ?? 'Bike',
      totalAmount: json['TotalAmount'] ?? '0',
      status: json['Status'] ?? 'Pending',
      remarks: json['Remarks'] ?? '',
    );
  }
}

class Person {
  final String name;
  final String time;

  Person({required this.name, required this.time});

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['Name'] ?? '',
      time: json['Time'] ?? '',
    );
  }
}
