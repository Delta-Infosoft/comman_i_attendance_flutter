// To parse this JSON data, do
//
//     final loginWithFcmIdResponseModel = loginWithFcmIdResponseModelFromJson(jsonString);

import 'dart:convert';

LoginWithFcmIdResponseModel loginWithFcmIdResponseModelFromJson(String str) => LoginWithFcmIdResponseModel.fromJson(json.decode(str));

String loginWithFcmIdResponseModelToJson(LoginWithFcmIdResponseModel data) => json.encode(data.toJson());

class LoginWithFcmIdResponseModel {
  String? status;
  String? message;
  List<LoginResultData>? result;

  LoginWithFcmIdResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory LoginWithFcmIdResponseModel.fromJson(Map<String, dynamic> json) => LoginWithFcmIdResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<LoginResultData>.from(json["result"]!.map((x) => LoginResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class LoginResultData {
  String? autoId;
  String? mobileNo;
  String? imeiCode;
  String? isApproved;
  String? approvedDateTime;
  String? fcmId;
  String? lastLoginDateTime;
  String? lastLogOutDateTime;
  String? remarks;
  String? companyName;
  String? insertedOn;
  String? lastUpdatedOn;
  String? insertedByUserId;
  String? lastUpdatedByUserId;
  String? usersName;
  String? isAutoSignOut;
  String? isAllowTourRights;
  String? departmentId;
  String? empId;
  String? isDisable;
  String? lat;
  String? long;
  String? isAllowGeoFencing;
  String? backDatedRights;
  String? isValidationWork;
  String? salesPersonCode;
  String? fromTime;
  String? toTime;
  String? expenseRight;
  String? isAllowPjcwoValidation;

  LoginResultData({
    this.autoId,
    this.mobileNo,
    this.imeiCode,
    this.isApproved,
    this.approvedDateTime,
    this.fcmId,
    this.lastLoginDateTime,
    this.lastLogOutDateTime,
    this.remarks,
    this.companyName,
    this.insertedOn,
    this.lastUpdatedOn,
    this.insertedByUserId,
    this.lastUpdatedByUserId,
    this.usersName,
    this.isAutoSignOut,
    this.isAllowTourRights,
    this.departmentId,
    this.empId,
    this.isDisable,
    this.lat,
    this.long,
    this.isAllowGeoFencing,
    this.backDatedRights,
    this.isValidationWork,
    this.salesPersonCode,
    this.fromTime,
    this.toTime,
    this.expenseRight,
    this.isAllowPjcwoValidation,
  });

  factory LoginResultData.fromJson(Map<String, dynamic> json) => LoginResultData(
    autoId: json["AutoId"],
    mobileNo: json["MobileNo"],
    imeiCode: json["IMEICode"],
    isApproved: json["IsApproved"],
    approvedDateTime: json["ApprovedDateTime"],
    fcmId: json["FCMId"],
    lastLoginDateTime: json["LastLoginDateTime"],
    lastLogOutDateTime: json["LastLogOutDateTime"],
    remarks: json["Remarks"],
    companyName: json["CompanyName"],
    insertedOn: json["InsertedOn"],
    lastUpdatedOn: json["LastUpdatedOn"],
    insertedByUserId: json["InsertedByUserId"],
    lastUpdatedByUserId: json["LastUpdatedByUserId"],
    usersName: json["UsersName"],
    isAutoSignOut: json["IsAutoSignOut"],
    isAllowTourRights: json["IsAllowTourRights"],
    departmentId: json["DepartmentId"],
    empId: json["EmpID"],
    isDisable: json["IsDisable"],
    lat: json["Lat"],
    long: json["Long"],
    isAllowGeoFencing: json["IsAllowGeoFencing"],
    backDatedRights: json["BackDatedRights"],
    isValidationWork: json["isValidationWork"],
    salesPersonCode: json["SalesPersonCode"],
    fromTime: json["FromTime"],
    toTime: json["ToTime"],
    expenseRight: json["ExpenseRight"],
    isAllowPjcwoValidation: json["IsAllowPJCWOValidation"],
  );

  Map<String, dynamic> toJson() => {
    "AutoId": autoId,
    "MobileNo": mobileNo,
    "IMEICode": imeiCode,
    "IsApproved": isApproved,
    "ApprovedDateTime": approvedDateTime,
    "FCMId": fcmId,
    "LastLoginDateTime": lastLoginDateTime,
    "LastLogOutDateTime": lastLogOutDateTime,
    "Remarks": remarks,
    "CompanyName": companyName,
    "InsertedOn": insertedOn,
    "LastUpdatedOn": lastUpdatedOn,
    "InsertedByUserId": insertedByUserId,
    "LastUpdatedByUserId": lastUpdatedByUserId,
    "UsersName": usersName,
    "IsAutoSignOut": isAutoSignOut,
    "IsAllowTourRights": isAllowTourRights,
    "DepartmentId": departmentId,
    "EmpID": empId,
    "IsDisable": isDisable,
    "Lat": lat,
    "Long": long,
    "IsAllowGeoFencing": isAllowGeoFencing,
    "BackDatedRights": backDatedRights,
    "isValidationWork": isValidationWork,
    "SalesPersonCode": salesPersonCode,
    "FromTime": fromTime,
    "ToTime": toTime,
    "ExpenseRight": expenseRight,
    "IsAllowPJCWOValidation": isAllowPjcwoValidation,
  };
}
