class TourVoucherModel {
  String? expenseId;
  String? empId;
  String? designation;
  String? deptId;
  String? travelDt;
  String? travellingBy;
  String? fromPlace;
  String? toPlace;
  String? startTime;
  String? endTime;
  String? nighHault;
  String? fareAmount;
  String? autoCharges;
  String? lodging;
  String? dailyAllowance;
  String? otherExpenses;
  String? totalExpenses;
  String? insertedOn;
  String? lastUpdatedOn;
  String? insertedByUserId;
  String? lastUpdatedByUserId;
  String? travelToDt;
  String? approvedDisapproved;
  String? approvedDisapprovedOn;
  String? approvedDisapprovedbyUserId;
  String? l1ApproveDisapprovedOn;
  String? l1ApprovedDisapprovedByUserId;
  String? autoChargesDetail;
  String? otherChargesDetail;
  String? isGSTFareAmt;
  String? isGSTAutoCharges;
  String? isGSTLodging;
  String? isGSTOtherExpenses;
  String? photoPath;
  String? approvedDisapprovedRemarks;
  String? fareAmountDetail;
  String? name;
  String? tourReport;
  String? status;

  TourVoucherModel({
    this.expenseId,
    this.empId,
    this.designation,
    this.deptId,
    this.travelDt,
    this.travellingBy,
    this.fromPlace,
    this.toPlace,
    this.startTime,
    this.endTime,
    this.nighHault,
    this.fareAmount,
    this.autoCharges,
    this.lodging,
    this.dailyAllowance,
    this.otherExpenses,
    this.totalExpenses,
    this.insertedOn,
    this.lastUpdatedOn,
    this.insertedByUserId,
    this.lastUpdatedByUserId,
    this.travelToDt,
    this.approvedDisapproved,
    this.approvedDisapprovedOn,
    this.approvedDisapprovedbyUserId,
    this.l1ApproveDisapprovedOn,
    this.l1ApprovedDisapprovedByUserId,
    this.autoChargesDetail,
    this.otherChargesDetail,
    this.isGSTFareAmt,
    this.isGSTAutoCharges,
    this.isGSTLodging,
    this.isGSTOtherExpenses,
    this.photoPath,
    this.approvedDisapprovedRemarks,
    this.fareAmountDetail,
    this.name,
    this.tourReport,
    this.status,
  });

  factory TourVoucherModel.fromJson(Map<String, dynamic> json) {
    return TourVoucherModel(
      expenseId: json['ExpenseId']?.toString(),
      empId: json['EmpId']?.toString(),
      designation: json['Designation']?.toString(),
      deptId: json['DeptId']?.toString(),
      travelDt: json['TravelDt']?.toString(),
      travellingBy: json['TravellingBy']?.toString(),
      fromPlace: json['FromPlace']?.toString(),
      toPlace: json['ToPlace']?.toString(),
      startTime: json['StartTime']?.toString(),
      endTime: json['EndTime']?.toString(),
      nighHault: json['NighHault']?.toString(),
      fareAmount: json['FareAmount']?.toString(),
      autoCharges: json['AutoCharges']?.toString(),
      lodging: json['Lodging']?.toString(),
      dailyAllowance: json['DailyAllowance']?.toString(),
      otherExpenses: json['OtherExpenses']?.toString(),
      totalExpenses: json['TotalExpenses']?.toString(),
      insertedOn: json['InsertedOn']?.toString(),
      lastUpdatedOn: json['LastUpdatedOn']?.toString(),
      insertedByUserId: json['InsertedByUserId']?.toString(),
      lastUpdatedByUserId: json['LastUpdatedByUserId']?.toString(),
      travelToDt: json['TravelToDt']?.toString(),
      approvedDisapproved: json['ApprovedDisapproved']?.toString(),
      approvedDisapprovedOn: json['ApprovedDisapprovedOn']?.toString(),
      approvedDisapprovedbyUserId:
          json['ApprovedDisapprovedbyUserId']?.toString(),
      l1ApproveDisapprovedOn: json['L1ApproveDisapprovedOn']?.toString(),
      l1ApprovedDisapprovedByUserId:
          json['L1ApprovedDisapprovedByUserId']?.toString(),
      autoChargesDetail: json['AutoChargesDetail']?.toString(),
      otherChargesDetail: json['OtherChargesDetail']?.toString(),
      isGSTFareAmt: json['IsGSTFareAmt']?.toString(),
      isGSTAutoCharges: json['IsGSTAutoCharges']?.toString(),
      isGSTLodging: json['IsGSTLodging']?.toString(),
      isGSTOtherExpenses: json['IsGSTOtherExpenses']?.toString(),
      photoPath: json['PhotoPath']?.toString(),
      approvedDisapprovedRemarks:
          json['ApprovedDisapprovedRemarks']?.toString(),
      fareAmountDetail: json['FareAmountDetail']?.toString(),
      name: json['Name']?.toString(),
      tourReport: json['TourReport']?.toString(),
      status: json['Status']?.toString(),
    );
  }

  // Convert to Update Request format
  Map<String, dynamic> toUpdateRequest(String mobileNo) {
    return {
      'Designation': designation ?? '',
      'ToPlace': toPlace ?? '',
      'OtherExpenses': otherExpenses ?? '0',
      'EndTime': _convertTo12HourFormat(endTime) ?? '',
      'ExpenseId': expenseId ?? '',
      'NightHault': nighHault == 'True' ? 'true' : 'false',
      'StartTime': _convertTo12HourFormat(startTime) ?? '',
      'TotalExpenses': totalExpenses ?? '0',
      'Lodging': lodging ?? '0',
      'AutoChargesDetail': autoChargesDetail ?? '',
      'FareAmt': fareAmount ?? '0',
      'EmpMobileNo': mobileNo,
      'OtherChargesDetails': otherChargesDetail ?? '',
      'FromPlace': fromPlace ?? '',
      'TravellingBy': travellingBy ?? '',
      'FromDate': _formatDate(travelDt) ?? '',
      'ToDate': _formatDate(travelToDt ?? travelDt) ?? '',
      'DepartmentId': deptId ?? '',
      'AutoCharges': autoCharges ?? '0',
      'DailyAllowance': dailyAllowance ?? '0',
    };
  }

  String? _convertTo12HourFormat(String? time24h) {
    if (time24h == null || time24h.isEmpty) return null;

    try {
      // Handle formats like "18-Nov-2025 11:33:00" or "11:33:00"
      String timePart = time24h;
      if (time24h.contains(' ')) {
        timePart = time24h.split(' ')[1];
      }

      List<String> parts = timePart.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        String period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

        return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
      return time24h;
    } catch (e) {
      return time24h;
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Extract date part from "18-Nov-2025 00:00:00"
      if (dateString.contains(' ')) {
        return dateString.split(' ')[0];
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
}

class TourVoucherResponse {
  String? status;
  String? message;
  List<TourVoucherModel>? result;

  TourVoucherResponse({
    this.status,
    this.message,
    this.result,
  });

  factory TourVoucherResponse.fromJson(Map<String, dynamic> json) {
    List<TourVoucherModel> resultList = [];
    if (json['result'] != null && json['result'] is List) {
      for (var item in json['result']) {
        resultList.add(TourVoucherModel.fromJson(item));
      }
    }

    return TourVoucherResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      result: resultList,
    );
  }
}

class UpdateTourExpenseResponse {
  String? status;
  String? message;
  UpdateTourExpenseResult? result;

  UpdateTourExpenseResponse({
    this.status,
    this.message,
    this.result,
  });

  factory UpdateTourExpenseResponse.fromJson(Map<String, dynamic> json) {
    return UpdateTourExpenseResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      result: json['result'] != null
          ? UpdateTourExpenseResult.fromJson(json['result'])
          : null,
    );
  }
}

class UpdateTourExpenseResult {
  String? id;

  UpdateTourExpenseResult({
    this.id,
  });

  factory UpdateTourExpenseResult.fromJson(Map<String, dynamic> json) {
    return UpdateTourExpenseResult(
      id: json['Id']?.toString(),
    );
  }
}
