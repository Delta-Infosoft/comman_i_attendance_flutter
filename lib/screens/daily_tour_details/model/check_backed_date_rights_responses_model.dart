// To parse this JSON data, do
//
//     final checkBackDatedRightsResponseModel = checkBackDatedRightsResponseModelFromJson(jsonString);



// To parse this JSON data, do
//
//     final checkBackDatedRightsRequestModel = checkBackDatedRightsRequestModelFromJson(jsonString);

import 'dart:convert';

CheckBackDatedRightsRequestModel checkBackDatedRightsRequestModelFromJson(String str) =>
    CheckBackDatedRightsRequestModel.fromJson(json.decode(str));

String checkBackDatedRightsRequestModelToJson(CheckBackDatedRightsRequestModel data) =>
    json.encode(data.toJson());

class CheckBackDatedRightsRequestModel {
  String? empId;

  CheckBackDatedRightsRequestModel({
    this.empId,
  });

  factory CheckBackDatedRightsRequestModel.fromJson(Map<String, dynamic> json) =>
      CheckBackDatedRightsRequestModel(
        empId: json["EmpId"],
      );

  Map<String, dynamic> toJson() => {
    "EmpId": empId,
  };
}



CheckBackDatedRightsResponseModel checkBackDatedRightsResponseModelFromJson(String str) => CheckBackDatedRightsResponseModel.fromJson(json.decode(str));

String checkBackDatedRightsResponseModelToJson(CheckBackDatedRightsResponseModel data) => json.encode(data.toJson());

class CheckBackDatedRightsResponseModel {
  String? status;
  String? message;
  List<CheckBackedDateResultData>? result;

  CheckBackDatedRightsResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory CheckBackDatedRightsResponseModel.fromJson(Map<String, dynamic> json) => CheckBackDatedRightsResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<CheckBackedDateResultData>.from(json["result"]!.map((x) => CheckBackedDateResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class CheckBackedDateResultData {
  String? noOfDays;
  String? fromPjcDate;
  String? toPjcDate;

  CheckBackedDateResultData({
    this.noOfDays,
    this.fromPjcDate,
    this.toPjcDate,
  });

  factory CheckBackedDateResultData.fromJson(Map<String, dynamic> json) => CheckBackedDateResultData(
    noOfDays: json["NoOfDays"],
    fromPjcDate: json["FromPJCDate"],
    toPjcDate: json["ToPJCDate"],
  );

  Map<String, dynamic> toJson() => {
    "NoOfDays": noOfDays,
    "FromPJCDate": fromPjcDate,
    "ToPJCDate": toPjcDate,
  };
}
