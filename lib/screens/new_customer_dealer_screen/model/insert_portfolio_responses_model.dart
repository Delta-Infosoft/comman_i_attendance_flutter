// To parse this JSON data, do
//
//     final insertPortfolioResponseModel = insertPortfolioResponseModelFromJson(jsonString);

import 'dart:convert';

InsertPortfolioResponseModel insertPortfolioResponseModelFromJson(String str) => InsertPortfolioResponseModel.fromJson(json.decode(str));

String insertPortfolioResponseModelToJson(InsertPortfolioResponseModel data) => json.encode(data.toJson());

class InsertPortfolioResponseModel {
  String? status;
  String? message;
  InsertPortfolioResultData? result;

  InsertPortfolioResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory InsertPortfolioResponseModel.fromJson(Map<String, dynamic> json) => InsertPortfolioResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? null : InsertPortfolioResultData.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result?.toJson(),
  };
}

class InsertPortfolioResultData {
  String? id;

  InsertPortfolioResultData({
    this.id,
  });

  factory InsertPortfolioResultData.fromJson(Map<String, dynamic> json) => InsertPortfolioResultData(
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
  };
}
