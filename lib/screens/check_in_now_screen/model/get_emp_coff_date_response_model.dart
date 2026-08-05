// To parse this JSON data, do
//
//     final getEmpCoffDateResponseModel = getEmpCoffDateResponseModelFromJson(jsonString);

import 'dart:convert';

GetEmpCoffDateResponseModel getEmpCoffDateResponseModelFromJson(String str) => GetEmpCoffDateResponseModel.fromJson(json.decode(str));

String getEmpCoffDateResponseModelToJson(GetEmpCoffDateResponseModel data) => json.encode(data.toJson());

class GetEmpCoffDateResponseModel {
  String? status;
  String? message;
  List<EmpCoffResultData>? result;

  GetEmpCoffDateResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory GetEmpCoffDateResponseModel.fromJson(Map<String, dynamic> json) => GetEmpCoffDateResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<EmpCoffResultData>.from(json["result"]!.map((x) => EmpCoffResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class EmpCoffResultData {
  String? date;

  EmpCoffResultData({
    this.date,
  });

  factory EmpCoffResultData.fromJson(Map<String, dynamic> json) => EmpCoffResultData(
    date: json["Date"],
  );

  Map<String, dynamic> toJson() => {
    "Date": date,
  };
}
