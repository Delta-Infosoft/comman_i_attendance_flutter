// To parse this JSON data, do
//
//     final userValidResponseModel = userValidResponseModelFromJson(jsonString);

import 'dart:convert';

UserValidResponseModel userValidResponseModelFromJson(String str) => UserValidResponseModel.fromJson(json.decode(str));

String userValidResponseModelToJson(UserValidResponseModel data) => json.encode(data.toJson());

class UserValidResponseModel {
  String? status;
  String? message;
  List<Result>? result;

  UserValidResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory UserValidResponseModel.fromJson(Map<String, dynamic> json) => UserValidResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<Result>.from(json["result"]!.map((x) => Result.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class Result {
  String? autoId;
  String? mobileNo;
  String? imeiCode;
  dynamic isApproved;
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

  Result({
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
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
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
  };
}
