// To parse this JSON data, do
//
//     final getMonthListResponseModel = getMonthListResponseModelFromJson(jsonString);

import 'dart:convert';

GetMonthListResponseModel getMonthListResponseModelFromJson(String str) => GetMonthListResponseModel.fromJson(json.decode(str));

String getMonthListResponseModelToJson(GetMonthListResponseModel data) => json.encode(data.toJson());

class GetMonthListResponseModel {
  String? status;
  String? message;
  List<MonthListResultData>? result;

  GetMonthListResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory GetMonthListResponseModel.fromJson(Map<String, dynamic> json) => GetMonthListResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<MonthListResultData>.from(json["result"]!.map((x) => MonthListResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class MonthListResultData {
  String? month;

  MonthListResultData({
    this.month,
  });

  factory MonthListResultData.fromJson(Map<String, dynamic> json) => MonthListResultData(
    month: json["Month"],
  );

  Map<String, dynamic> toJson() => {
    "Month": month,
  };
}
