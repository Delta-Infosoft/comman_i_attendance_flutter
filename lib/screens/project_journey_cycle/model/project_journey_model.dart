// Model for Back Dated Rights API Response
import 'dart:ui';

import 'package:flutter/material.dart';

// Model for Back Dated Rights API Response
class BackDatedRightsResponse {
  final String status;
  final String message;
  final List<BackDatedRights> result;

  BackDatedRightsResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory BackDatedRightsResponse.fromJson(Map<String, dynamic> json) {
    return BackDatedRightsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List? ?? [])
          .map((item) => BackDatedRights.fromJson(item))
          .toList(),
    );
  }
}

class BackDatedRights {
  final String noOfDays;
  final String fromPJCDate;
  final String toPJCDate;

  BackDatedRights({
    required this.noOfDays,
    required this.fromPJCDate,
    required this.toPJCDate,
  });

  factory BackDatedRights.fromJson(Map<String, dynamic> json) {
    return BackDatedRights(
      noOfDays: json['NoOfDays']?.toString() ?? '0',
      fromPJCDate: json['FromPJCDate']?.toString() ?? '',
      toPJCDate: json['ToPJCDate']?.toString() ?? '',
    );
  }
}

// Model for Insert PJC API Response
class InsertPJCResponse {
  final String status;
  final String message;
  final InsertPJCResult result;

  InsertPJCResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory InsertPJCResponse.fromJson(Map<String, dynamic> json) {
    return InsertPJCResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: InsertPJCResult.fromJson(json['result'] ?? {}),
    );
  }
}

class InsertPJCResult {
  final String id;

  InsertPJCResult({
    required this.id,
  });

  factory InsertPJCResult.fromJson(Map<String, dynamic> json) {
    return InsertPJCResult(
      id: json['id']?.toString() ?? '',
    );
  }
}

// Model for PJC Request
class PJCCreateRequest {
  final String mobileNo;
  final bool nightHault;
  final String monthYear;
  final String date;
  final String place;
  final String notes;

  PJCCreateRequest({
    required this.mobileNo,
    required this.nightHault,
    required this.monthYear,
    required this.date,
    required this.place,
    required this.notes,
  });
}

// Daily Event Model for calendar events
class DailyEvent {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  DailyEvent({
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });
}

// models/project_journey_model.dart
class GetPJCResponse {
  final String status;
  final String message;
  final List<PJCData> result;

  GetPJCResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory GetPJCResponse.fromJson(Map<String, dynamic> json) {
    return GetPJCResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List? ?? [])
          .map((item) => PJCData.fromJson(item))
          .toList(),
    );
  }
}

class PJCData {
  final String pjcId;
  final String dt;
  final String empId;
  final String area;
  final String monthYr;
  final String tgtSalesAmt;
  final String projectedNewCust;
  final String projectedNewDealer;
  final String notes;
  final String place;
  final String lnNo;
  final String paymentCnt;
  final String orderCnt;
  final String newDealerAppointmentDtCnt;
  final String subDealerVisitDateCnt;
  final String newDealerSurveyDateCnt;
  final String pjcLnId;

  PJCData({
    required this.pjcId,
    required this.dt,
    required this.empId,
    required this.area,
    required this.monthYr,
    required this.tgtSalesAmt,
    required this.projectedNewCust,
    required this.projectedNewDealer,
    required this.notes,
    required this.place,
    required this.lnNo,
    required this.paymentCnt,
    required this.orderCnt,
    required this.newDealerAppointmentDtCnt,
    required this.subDealerVisitDateCnt,
    required this.newDealerSurveyDateCnt,
    required this.pjcLnId,
  });

  factory PJCData.fromJson(Map<String, dynamic> json) {
    return PJCData(
      pjcId: json['PJCId'] ?? '',
      dt: json['Dt'] ?? '',
      empId: json['EmpId'] ?? '',
      area: json['Area'] ?? '',
      monthYr: json['MonthYr'] ?? '',
      tgtSalesAmt: json['TgtSalesAmt'] ?? '',
      projectedNewCust: json['ProjectedNewCust'] ?? '',
      projectedNewDealer: json['ProjectedNewDealer'] ?? '',
      notes: json['Notes'] ?? '',
      place: json['Place'] ?? '',
      lnNo: json['LnNo'] ?? '',
      paymentCnt: json['PaymentCnt'] ?? '',
      orderCnt: json['OrderCnt'] ?? '',
      newDealerAppointmentDtCnt: json['NewDealerAppointmentDtCnt'] ?? '',
      subDealerVisitDateCnt: json['SubDealerVisitDateCnt'] ?? '',
      newDealerSurveyDateCnt: json['NewDealerSurveyDateCnt'] ?? '',
      pjcLnId: json['PJCLnId'] ?? '',
    );
  }
}

// models/project_journey_model.dart
class GetPJCEventResponse {
  final String status;
  final String message;
  final List<List<PJCEventData>> result;

  GetPJCEventResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory GetPJCEventResponse.fromJson(Map<String, dynamic> json) {
    return GetPJCEventResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List? ?? [])
          .map((item) => (item as List? ?? [])
              .map((event) => PJCEventData.fromJson(event))
              .toList())
          .toList(),
    );
  }
}

class PJCEventData {
  final String notes;
  final String place;
  final String pjcId;
  final String pjcLnId;

  PJCEventData({
    required this.notes,
    required this.place,
    required this.pjcId,
    required this.pjcLnId,
  });

  factory PJCEventData.fromJson(Map<String, dynamic> json) {
    return PJCEventData(
      notes: json['Notes'] ?? '',
      place: json['Place'] ?? '',
      pjcId: json['PJCId'] ?? '',
      pjcLnId: json['PJCLnId'] ?? '',
    );
  }
}
