// To parse this JSON data, do
//
//     final selectPortfolioResponseModel = selectPortfolioResponseModelFromJson(jsonString);

import 'dart:convert';

SelectPortfolioResponseModel selectPortfolioResponseModelFromJson(String str) => SelectPortfolioResponseModel.fromJson(json.decode(str));

String selectPortfolioResponseModelToJson(SelectPortfolioResponseModel data) => json.encode(data.toJson());

class SelectPortfolioResponseModel {
  String? status;
  String? message;
  List<SelectPortfolioResultData>? result;

  SelectPortfolioResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory SelectPortfolioResponseModel.fromJson(Map<String, dynamic> json) => SelectPortfolioResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<SelectPortfolioResultData>.from(json["result"]!.map((x) => SelectPortfolioResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class SelectPortfolioResultData {
  String? portfolioId;
  String? dt;
  String? companyName;
  String? city;
  String? contactPersonName;
  String? contactPersonMobileNo;
  String? contactPersonEmailId;
  dynamic lat;
  dynamic long;
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
  String? photoPathShow;
  String? photoPathShow1;
  String? photoPathShow2;
  String? photoPathShow3;
  String? photoPathShow4;

  SelectPortfolioResultData({
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
    this.photoPathShow,
    this.photoPathShow1,
    this.photoPathShow2,
    this.photoPathShow3,
    this.photoPathShow4,
  });

  factory SelectPortfolioResultData.fromJson(Map<String, dynamic> json) => SelectPortfolioResultData(
    portfolioId: json["PortfolioId"],
    dt: json["Dt"],
    companyName: json["CompanyName"],
    city: json["City"],
    contactPersonName: json["ContactPersonName"],
    contactPersonMobileNo: json["ContactPersonMobileNo"],
    contactPersonEmailId: json["ContactPersonEmailId"],
    lat: json["Lat"],
    long: json["Long"],
    remarks: json["Remarks"],
    photoPath: json["PhotoPath"],
    insertedOn: json["InsertedOn"],
    lastUpdatedOn: json["LastUpdatedOn"],
    insertedByUserId: json["InsertedByUserId"],
    lastUpdatedByUserId: json["LastUpdatedByUserId"],
    photoPath1: json["PhotoPath1"],
    photoPath2: json["PhotoPath2"],
    photoPath3: json["PhotoPath3"],
    photoPath4: json["PhotoPath4"],
    photoPathShow: json["PhotoPathShow"],
    photoPathShow1: json["PhotoPathShow1"],
    photoPathShow2: json["PhotoPathShow2"],
    photoPathShow3: json["PhotoPathShow3"],
    photoPathShow4: json["PhotoPathShow4"],
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
    "PhotoPathShow": photoPathShow,
    "PhotoPathShow1": photoPathShow1,
    "PhotoPathShow2": photoPathShow2,
    "PhotoPathShow3": photoPathShow3,
    "PhotoPathShow4": photoPathShow4,
  };
}
