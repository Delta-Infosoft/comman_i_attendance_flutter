// To parse this JSON data, do
//
//     final attandanceInOutResponseModel = attandanceInOutResponseModelFromJson(jsonString);

import 'dart:convert';

AttandanceInOutResponseModel attandanceInOutResponseModelFromJson(String str) => AttandanceInOutResponseModel.fromJson(json.decode(str));

String attandanceInOutResponseModelToJson(AttandanceInOutResponseModel data) => json.encode(data.toJson());

class AttandanceInOutResponseModel {
  String? status;
  String? message;
  AttandanceInOutResultData? result;

  AttandanceInOutResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory AttandanceInOutResponseModel.fromJson(Map<String, dynamic> json) => AttandanceInOutResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? null : AttandanceInOutResultData.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result?.toJson(),
  };
}

class AttandanceInOutResultData {
  String? id;

  AttandanceInOutResultData({
    this.id,
  });

  factory AttandanceInOutResultData.fromJson(Map<String, dynamic> json) => AttandanceInOutResultData(
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
  };
}
