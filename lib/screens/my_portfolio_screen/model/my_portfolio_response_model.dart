// To parse this JSON data, do
//
//     final myPortfolioViewResponseModel = myPortfolioViewResponseModelFromJson(jsonString);

import 'dart:convert';

MyPortfolioViewResponseModel myPortfolioViewResponseModelFromJson(String str) => MyPortfolioViewResponseModel.fromJson(json.decode(str));

String myPortfolioViewResponseModelToJson(MyPortfolioViewResponseModel data) => json.encode(data.toJson());

class MyPortfolioViewResponseModel {
  String? status;
  String? message;
  List<MyPortfolioViewResultData>? result;

  MyPortfolioViewResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory MyPortfolioViewResponseModel.fromJson(Map<String, dynamic> json) => MyPortfolioViewResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<MyPortfolioViewResultData>.from(json["result"]!.map((x) => MyPortfolioViewResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class MyPortfolioViewResultData {
  String? portfolioId;
  String? dt;
  String? companyName;
  String? city;
  String? contactPersonName;
  String? contactPersonMobileNo;
  String? contactPersonEmailId;
  String? lat;
  String? long;
  String? remarks;
  String? photoPath;
  String? insertedOn;
  String? lastUpdatedOn;
  String? insertedByUserId;
  String? lastUpdatedByUserId;
  String? photoPath1;
  String? photoPath2;
  String? photoPath3;
  String? photoPath4;
  UsersName? usersName;

  MyPortfolioViewResultData({
    this.portfolioId,
    this.dt,
    this.companyName,
    this.city,
    this.contactPersonName,
    this.contactPersonMobileNo,
    this.contactPersonEmailId,
    this.lat,
    this.long,
    this.remarks,
    this.photoPath,
    this.insertedOn,
    this.lastUpdatedOn,
    this.insertedByUserId,
    this.lastUpdatedByUserId,
    this.photoPath1,
    this.photoPath2,
    this.photoPath3,
    this.photoPath4,
    this.usersName,
  });

  factory MyPortfolioViewResultData.fromJson(Map<String, dynamic> json) => MyPortfolioViewResultData(
    portfolioId: json["PortfolioId"] ?? '',
    dt: json["Dt"] ?? '',
    companyName: json["CompanyName"] ?? '',
    city: json["City"] ?? '',
    contactPersonName: json["ContactPersonName"] ?? '',
    contactPersonMobileNo: json["ContactPersonMobileNo"] ?? '',
    contactPersonEmailId: json["ContactPersonEmailId"] ?? '',
    lat: json["Lat"] ?? '',
    long: json["Long"] ?? '',
    remarks: json["Remarks"] ?? '',
    photoPath: json["PhotoPath"] ?? '',
    insertedOn: json["InsertedOn"] ?? '',
    lastUpdatedOn: json["LastUpdatedOn"] ?? '',
    insertedByUserId: json["InsertedByUserId"] ?? '',
    lastUpdatedByUserId: json["LastUpdatedByUserId"] ?? '',
    photoPath1: json["PhotoPath1"] ?? '',
    photoPath2: json["PhotoPath2"] ?? '',
    photoPath3: json["PhotoPath3"] ?? '',
    photoPath4: json["PhotoPath4"] ?? '',
    usersName: usersNameValues.map[json["UsersName"]],
  );

  Map<String, dynamic> toJson() => {
    "PortfolioId": portfolioId,
    "Dt": dt,
    "CompanyName": companyName,
    "City": city,
    "ContactPersonName": contactPersonName,
    "ContactPersonMobileNo": contactPersonMobileNo,
    "ContactPersonEmailId": contactPersonEmailId,
    "Lat": lat,
    "Long": long,
    "Remarks": remarks,
    "PhotoPath": photoPath,
    "InsertedOn": insertedOn,
    "LastUpdatedOn": lastUpdatedOn,
    "InsertedByUserId": insertedByUserId,
    "LastUpdatedByUserId": lastUpdatedByUserId,
    "PhotoPath1": photoPath1,
    "PhotoPath2": photoPath2,
    "PhotoPath3": photoPath3,
    "PhotoPath4": photoPath4,
    "UsersName": usersNameValues.reverse[usersName],
  };
}

enum UsersName {
  DELTA_USER
}

final usersNameValues = EnumValues({
  "Delta User": UsersName.DELTA_USER
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
