// To parse this JSON data, do
//
//     final attandanceTextListResponseModel = attandanceTextListResponseModelFromJson(jsonString);

import 'dart:convert';

AttandanceTextListResponseModel attandanceTextListResponseModelFromJson(String str) => AttandanceTextListResponseModel.fromJson(json.decode(str));

String attandanceTextListResponseModelToJson(AttandanceTextListResponseModel data) => json.encode(data.toJson());

class AttandanceTextListResponseModel {
  String? status;
  String? message;
  List<AttandanceTextListResultData>? result;

  AttandanceTextListResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory AttandanceTextListResponseModel.fromJson(Map<String, dynamic> json) => AttandanceTextListResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<AttandanceTextListResultData>.from(json["result"]!.map((x) => AttandanceTextListResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class AttandanceTextListResultData {
  String? textListId;
  String? group;
  String? text;
  String? insertedOn;
  String? lastUpdatedOn;
  String? insertedByUserId;
  String? lastUpdatedByUserId;
  String? isGetInOutTime;

  AttandanceTextListResultData({
    this.textListId,
    this.group,
    this.text,
    this.insertedOn,
    this.lastUpdatedOn,
    this.insertedByUserId,
    this.lastUpdatedByUserId,
    this.isGetInOutTime,
  });

  factory AttandanceTextListResultData.fromJson(Map<String, dynamic> json) => AttandanceTextListResultData(
    textListId: json["TextListId"],
    group: json["Group"],
    text: json["Text"],
    insertedOn: json["InsertedOn"],
    lastUpdatedOn: json["LastUpdatedOn"],
    insertedByUserId: json["InsertedByUserId"],
    lastUpdatedByUserId: json["LastUpdatedByUserId"],
    isGetInOutTime: json["IsGetInOutTime"],
  );

  Map<String, dynamic> toJson() => {
    "TextListId": textListId,
    "Group": group,
    "Text": text,
    "InsertedOn": insertedOn,
    "LastUpdatedOn": lastUpdatedOn,
    "InsertedByUserId": insertedByUserId,
    "LastUpdatedByUserId": lastUpdatedByUserId,
    "IsGetInOutTime": isGetInOutTime,
  };
}
