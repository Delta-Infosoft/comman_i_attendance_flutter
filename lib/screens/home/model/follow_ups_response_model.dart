// To parse this JSON data, do
//
//     final followUpsResponseModel = followUpsResponseModelFromJson(jsonString);

import 'dart:convert';

FollowUpsResponseModel followUpsResponseModelFromJson(String str) => FollowUpsResponseModel.fromJson(json.decode(str));

String followUpsResponseModelToJson(FollowUpsResponseModel data) => json.encode(data.toJson());

class FollowUpsResponseModel {
  String? status;
  String? message;
  List<List<FollowUpsResultData>>? result;

  FollowUpsResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory FollowUpsResponseModel.fromJson(Map<String, dynamic> json) => FollowUpsResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<List<FollowUpsResultData>>.from(json["result"]!.map((x) => List<FollowUpsResultData>.from(x.map((x) => FollowUpsResultData.fromJson(x))))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => List<dynamic>.from(x.map((x) => x.toJson())))),
  };
}

class FollowUpsResultData {
  String? partyName;
  String? remarks;
  String? orderFollowUpDt;

  FollowUpsResultData({
    this.partyName,
    this.remarks,
    this.orderFollowUpDt,
  });

  factory FollowUpsResultData.fromJson(Map<String, dynamic> json) => FollowUpsResultData(
    partyName: json["PartyName"],
    remarks: json["Remarks"],
    orderFollowUpDt: json["OrderFollowUpDt"],
  );

  Map<String, dynamic> toJson() => {
    "PartyName": partyName,
    "Remarks": remarks,
    "OrderFollowUpDt": orderFollowUpDt,
  };
}
