// ─── Attendance Status Models ───────────────────────────────────────────────

class CheckAttendanceStatusRequest {
  final String mobileNo;
  final String date;

  CheckAttendanceStatusRequest({
    required this.mobileNo,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'MobileNo': mobileNo,
      'Date': date,
    };
  }
}

class AttendanceStatusResult {
  final String attnStatus;

  AttendanceStatusResult({required this.attnStatus});

  factory AttendanceStatusResult.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusResult(
      attnStatus: json['AttnStatus'] ?? '',
    );
  }
}

class CheckAttendanceStatusResponse {
  final String status;
  final String message;
  final List<AttendanceStatusResult> result;

  CheckAttendanceStatusResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory CheckAttendanceStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckAttendanceStatusResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => AttendanceStatusResult.fromJson(item))
              .toList() ??
          [],
    );
  }

  /// Returns true only when the first result has AttnStatus == 'P'
  bool get isPresent =>
      result.isNotEmpty && result.first.attnStatus.toUpperCase() == 'P';
}

// ─── Entry Validation Models ─────────────────────────────────────────────────

class CheckEntryValidationRequest {
  final String mobileNo;
  final String type;
  final String date;

  CheckEntryValidationRequest({
    required this.mobileNo,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'MobileNo': mobileNo,
      'Type': type,
      'Date': date,
    };
  }
}

class CheckEntryValidationResponse {
  final String status;
  final String message;
  final List<PJCResult> result;

  CheckEntryValidationResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory CheckEntryValidationResponse.fromJson(Map<String, dynamic> json) {
    return CheckEntryValidationResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => PJCResult.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class PJCResult {
  final String pjcId;
  final String empId;

  PJCResult({
    required this.pjcId,
    required this.empId,
  });

  factory PJCResult.fromJson(Map<String, dynamic> json) {
    return PJCResult(
      pjcId: json['PJCId'] ?? '',
      empId: json['EmpId'] ?? '',
    );
  }
}

class AllowTourWithoutPJCRequest {
  final String empId;

  AllowTourWithoutPJCRequest({required this.empId});

  Map<String, dynamic> toJson() {
    return {
      'EmpId': empId,
    };
  }
}

class AllowTourWithoutPJCResponse {
  final String status;
  final String message;
  final List<dynamic> result;

  AllowTourWithoutPJCResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory AllowTourWithoutPJCResponse.fromJson(Map<String, dynamic> json) {
    return AllowTourWithoutPJCResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: json['result'] ?? [],
    );
  }
}

class District {
  final String district;

  District({required this.district});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      district: json['District'] ?? json['district'] ?? '',
    );
  }
}

class DistrictResponse {
  final String status;
  final String message;
  final List<District> result;

  DistrictResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory DistrictResponse.fromJson(Map<String, dynamic> json) {
    return DistrictResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => District.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class TextListItem {
  final String textListId;
  final String text;

  TextListItem({
    required this.textListId,
    required this.text,
  });

  factory TextListItem.fromJson(Map<String, dynamic> json) {
    return TextListItem(
      textListId: json['TextListId'] ?? json['textListId'] ?? '',
      text: json['Text'] ?? json['text'] ?? '',
    );
  }
}

class TextListResponse {
  final String status;
  final String message;
  final List<TextListItem> result;

  TextListResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory TextListResponse.fromJson(Map<String, dynamic> json) {
    return TextListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => TextListItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class WeeklyTourDetailRequest {
  final String endTime;
  final String paymentFollowUpDt;
  final String isDiscountDiscussion;
  final String subDealerVisitDate;
  final String isSalesPromotionalActivity;
  final String isNewDealerSurvey;
  final String empMobileNo;
  final String isSubDealerVisit;
  final String newDealerSurveyDate;
  final String pointDiscussion;
  final String dealerName;
  final String isServiceOrRepairing;
  final String mobileNo;
  final String toPlace;
  final String paymentFollowUpAmount;
  final String startTime;
  final String isNewDealerAppointment;
  final String typeTextListId;
  final String isPaymentFollowUp;
  final String isOrderFollowUp;
  final String date;
  final String businessCenter;
  final String area;
  final String fromPlace;
  final String isStockPlanning;
  final String isSchemeDiscussion;
  final String orderFollowUpDt;
  final String newDealerAppointmentDt;
  final String district;

  WeeklyTourDetailRequest({
    required this.endTime,
    required this.paymentFollowUpDt,
    required this.isDiscountDiscussion,
    required this.subDealerVisitDate,
    required this.isSalesPromotionalActivity,
    required this.isNewDealerSurvey,
    required this.empMobileNo,
    required this.isSubDealerVisit,
    required this.newDealerSurveyDate,
    required this.pointDiscussion,
    required this.dealerName,
    required this.isServiceOrRepairing,
    required this.mobileNo,
    required this.toPlace,
    required this.paymentFollowUpAmount,
    required this.startTime,
    required this.isNewDealerAppointment,
    required this.typeTextListId,
    required this.isPaymentFollowUp,
    required this.isOrderFollowUp,
    required this.date,
    required this.businessCenter,
    required this.area,
    required this.fromPlace,
    required this.isStockPlanning,
    required this.isSchemeDiscussion,
    required this.orderFollowUpDt,
    required this.newDealerAppointmentDt,
    required this.district,
  });

  Map<String, dynamic> toJson() {
    return {
      'EndTime': endTime,
      'PaymentFollowUpDt': paymentFollowUpDt,
      'IsDiscountDiscussion': isDiscountDiscussion,
      'SubDealerVisitDate': subDealerVisitDate,
      'IsSalesPromotionalActivity': isSalesPromotionalActivity,
      'IsNewDealerSurvey': isNewDealerSurvey,
      'EmpMobileNo': empMobileNo,
      'IsSubDealerVisit': isSubDealerVisit,
      'NewDealerSurveyDate': newDealerSurveyDate,
      'PointDiscussion': pointDiscussion,
      'DealerName': dealerName,
      'IsServiceOrRepairing': isServiceOrRepairing,
      'MobileNo': mobileNo,
      'ToPlace': toPlace,
      'PaymentFollowUpAmount': paymentFollowUpAmount,
      'StartTime': startTime,
      'IsNewDealerAppointment': isNewDealerAppointment,
      'TypeTextListId': typeTextListId,
      'IsPaymentFollowUp': isPaymentFollowUp,
      'IsOrderFollowUp': isOrderFollowUp,
      'Date': date,
      'BusinessCenter': businessCenter,
      'Area': area,
      'FromPlace': fromPlace,
      'IsStockPlanning': isStockPlanning,
      'IsSchemeDiscussion': isSchemeDiscussion,
      'OrderFollowUpDt': orderFollowUpDt,
      'NewDealerAppointmentDt': newDealerAppointmentDt,
      'District': district,
    };
  }
}

class WeeklyTourDetailResponse {
  final String status;
  final String message;
  final WeeklyTourDetailResult result;

  WeeklyTourDetailResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory WeeklyTourDetailResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyTourDetailResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: WeeklyTourDetailResult.fromJson(json['result'] ?? {}),
    );
  }
}

class WeeklyTourDetailResult {
  final String id;

  WeeklyTourDetailResult({required this.id});

  factory WeeklyTourDetailResult.fromJson(Map<String, dynamic> json) {
    return WeeklyTourDetailResult(
      id: json['Id'] ?? json['id'] ?? '',
    );
  }
}
// class CheckEntryValidationRequest {
//   final String mobileNo;
//   final String type;
//   final String date;

//   CheckEntryValidationRequest({
//     required this.mobileNo,
//     required this.type,
//     required this.date,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'MobileNo': mobileNo,
//       'Type': type,
//       'Date': date,
//     };
//   }
// }

// class CheckEntryValidationResponse {
//   final String status;
//   final String message;
//   final List<PJCResult> result;

//   CheckEntryValidationResponse({
//     required this.status,
//     required this.message,
//     required this.result,
//   });

//   factory CheckEntryValidationResponse.fromJson(Map<String, dynamic> json) {
//     return CheckEntryValidationResponse(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       result: (json['result'] as List<dynamic>?)
//               ?.map((item) => PJCResult.fromJson(item))
//               .toList() ??
//           [],
//     );
//   }
// }

// class PJCResult {
//   final String id;
//   final String projectName;

//   PJCResult({
//     required this.id,
//     required this.projectName,
//   });

//   factory PJCResult.fromJson(Map<String, dynamic> json) {
//     return PJCResult(
//       id: json['Id'] ?? json['id'] ?? '',
//       projectName: json['ProjectName'] ?? json['projectName'] ?? '',
//     );
//   }
// }

// class AllowTourWithoutPJCRequest {
//   final String empId;

//   AllowTourWithoutPJCRequest({required this.empId});

//   Map<String, dynamic> toJson() {
//     return {
//       'EmpId': empId,
//     };
//   }
// }

// class AllowTourWithoutPJCResponse {
//   final String status;
//   final String message;
//   final List<dynamic> result;

//   AllowTourWithoutPJCResponse({
//     required this.status,
//     required this.message,
//     required this.result,
//   });

//   factory AllowTourWithoutPJCResponse.fromJson(Map<String, dynamic> json) {
//     return AllowTourWithoutPJCResponse(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       result: json['result'] ?? [],
//     );
//   }
// }

// class District {
//   final String district;

//   District({required this.district});

//   factory District.fromJson(Map<String, dynamic> json) {
//     return District(
//       district: json['District'] ?? json['district'] ?? '',
//     );
//   }
// }

// class DistrictResponse {
//   final String status;
//   final String message;
//   final List<District> result;

//   DistrictResponse({
//     required this.status,
//     required this.message,
//     required this.result,
//   });

//   factory DistrictResponse.fromJson(Map<String, dynamic> json) {
//     return DistrictResponse(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       result: (json['result'] as List<dynamic>?)
//               ?.map((item) => District.fromJson(item))
//               .toList() ??
//           [],
//     );
//   }
// }

// class TextListItem {
//   final String textListId;
//   final String text;

//   TextListItem({
//     required this.textListId,
//     required this.text,
//   });

//   factory TextListItem.fromJson(Map<String, dynamic> json) {
//     return TextListItem(
//       textListId: json['TextListId'] ?? json['textListId'] ?? '',
//       text: json['Text'] ?? json['text'] ?? '',
//     );
//   }
// }

// class TextListResponse {
//   final String status;
//   final String message;
//   final List<TextListItem> result;

//   TextListResponse({
//     required this.status,
//     required this.message,
//     required this.result,
//   });

//   factory TextListResponse.fromJson(Map<String, dynamic> json) {
//     return TextListResponse(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       result: (json['result'] as List<dynamic>?)
//               ?.map((item) => TextListItem.fromJson(item))
//               .toList() ??
//           [],
//     );
//   }
// }

// class WeeklyTourDetailRequest {
//   final String endTime;
//   final String paymentFollowUpDt;
//   final String isDiscountDiscussion;
//   final String subDealerVisitDate;
//   final String isSalesPromotionalActivity;
//   final String isNewDealerSurvey;
//   final String empMobileNo;
//   final String isSubDealerVisit;
//   final String newDealerSurveyDate;
//   final String pointDiscussion;
//   final String dealerName;
//   final String isServiceOrRepairing;
//   final String mobileNo;
//   final String toPlace;
//   final String paymentFollowUpAmount;
//   final String startTime;
//   final String isNewDealerAppointment;
//   final String typeTextListId;
//   final String isPaymentFollowUp;
//   final String isOrderFollowUp;
//   final String date;
//   final String businessCenter;
//   final String area;
//   final String fromPlace;
//   final String isStockPlanning;
//   final String isSchemeDiscussion;
//   final String orderFollowUpDt;
//   final String newDealerAppointmentDt;
//   final String district;

//   WeeklyTourDetailRequest({
//     required this.endTime,
//     required this.paymentFollowUpDt,
//     required this.isDiscountDiscussion,
//     required this.subDealerVisitDate,
//     required this.isSalesPromotionalActivity,
//     required this.isNewDealerSurvey,
//     required this.empMobileNo,
//     required this.isSubDealerVisit,
//     required this.newDealerSurveyDate,
//     required this.pointDiscussion,
//     required this.dealerName,
//     required this.isServiceOrRepairing,
//     required this.mobileNo,
//     required this.toPlace,
//     required this.paymentFollowUpAmount,
//     required this.startTime,
//     required this.isNewDealerAppointment,
//     required this.typeTextListId,
//     required this.isPaymentFollowUp,
//     required this.isOrderFollowUp,
//     required this.date,
//     required this.businessCenter,
//     required this.area,
//     required this.fromPlace,
//     required this.isStockPlanning,
//     required this.isSchemeDiscussion,
//     required this.orderFollowUpDt,
//     required this.newDealerAppointmentDt,
//     required this.district,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'EndTime': endTime,
//       'PaymentFollowUpDt': paymentFollowUpDt,
//       'IsDiscountDiscussion': isDiscountDiscussion,
//       'SubDealerVisitDate': subDealerVisitDate,
//       'IsSalesPromotionalActivity': isSalesPromotionalActivity,
//       'IsNewDealerSurvey': isNewDealerSurvey,
//       'EmpMobileNo': empMobileNo,
//       'IsSubDealerVisit': isSubDealerVisit,
//       'NewDealerSurveyDate': newDealerSurveyDate,
//       'PointDiscussion': pointDiscussion,
//       'DealerName': dealerName,
//       'IsServiceOrRepairing': isServiceOrRepairing,
//       'MobileNo': mobileNo,
//       'ToPlace': toPlace,
//       'PaymentFollowUpAmount': paymentFollowUpAmount,
//       'StartTime': startTime,
//       'IsNewDealerAppointment': isNewDealerAppointment,
//       'TypeTextListId': typeTextListId,
//       'IsPaymentFollowUp': isPaymentFollowUp,
//       'IsOrderFollowUp': isOrderFollowUp,
//       'Date': date,
//       'BusinessCenter': businessCenter,
//       'Area': area,
//       'FromPlace': fromPlace,
//       'IsStockPlanning': isStockPlanning,
//       'IsSchemeDiscussion': isSchemeDiscussion,
//       'OrderFollowUpDt': orderFollowUpDt,
//       'NewDealerAppointmentDt': newDealerAppointmentDt,
//       'District': district,
//     };
//   }
// }

// class WeeklyTourDetailResponse {
//   final String status;
//   final String message;
//   final WeeklyTourDetailResult result;

//   WeeklyTourDetailResponse({
//     required this.status,
//     required this.message,
//     required this.result,
//   });

//   factory WeeklyTourDetailResponse.fromJson(Map<String, dynamic> json) {
//     return WeeklyTourDetailResponse(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       result: WeeklyTourDetailResult.fromJson(json['result'] ?? {}),
//     );
//   }
// }

// class WeeklyTourDetailResult {
//   final String id;

//   WeeklyTourDetailResult({required this.id});

//   factory WeeklyTourDetailResult.fromJson(Map<String, dynamic> json) {
//     return WeeklyTourDetailResult(
//       id: json['Id'] ?? json['id'] ?? '',
//     );
//   }
// }