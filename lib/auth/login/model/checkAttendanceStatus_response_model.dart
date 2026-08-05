// To parse this JSON data, do
//
//     final checkAttendanceStatusResponseModel = checkAttendanceStatusResponseModelFromJson(jsonString);

import 'dart:convert';

CheckAttendanceStatusResponseModel checkAttendanceStatusResponseModelFromJson(String str) => CheckAttendanceStatusResponseModel.fromJson(json.decode(str));

String checkAttendanceStatusResponseModelToJson(CheckAttendanceStatusResponseModel data) => json.encode(data.toJson());

class CheckAttendanceStatusResponseModel {
  String? status;
  String? message;
  List<CheckAttendanceResultData>? result;

  CheckAttendanceStatusResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory CheckAttendanceStatusResponseModel.fromJson(Map<String, dynamic> json) => CheckAttendanceStatusResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<CheckAttendanceResultData>.from(json["result"]!.map((x) => CheckAttendanceResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class CheckAttendanceResultData {
  String? attnStatus;

  CheckAttendanceResultData({
    this.attnStatus,
  });

  factory CheckAttendanceResultData.fromJson(Map<String, dynamic> json) => CheckAttendanceResultData(
    attnStatus: json["AttnStatus"],
  );

  Map<String, dynamic> toJson() => {
    "AttnStatus": attnStatus,
  };
}
