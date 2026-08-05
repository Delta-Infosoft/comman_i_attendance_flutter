// To parse this JSON data, do
//
//     final getAttendanceFromId = getAttendanceFromIdFromJson(jsonString);

import 'dart:convert';

GetAttendanceFromId getAttendanceFromIdFromJson(String str) => GetAttendanceFromId.fromJson(json.decode(str));

String getAttendanceFromIdToJson(GetAttendanceFromId data) => json.encode(data.toJson());

class GetAttendanceFromId {
  String? status;
  String? message;
  List<GetAttendanceFromIdResultData>? result;

  GetAttendanceFromId({
    this.status,
    this.message,
    this.result,
  });

  factory GetAttendanceFromId.fromJson(Map<String, dynamic> json) => GetAttendanceFromId(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<GetAttendanceFromIdResultData>.from(json["result"]!.map((x) => GetAttendanceFromIdResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class GetAttendanceFromIdResultData {
  String? autoId;
  String? mobileNo;
  String? inTime;
  String? outTime;
  String? status;
  String? remarks;
  String? lat;
  String? long;
  String? gpsStatus;
  String? netStatus;
  String? insertedOn;
  String? lastUpdatedOn;
  String? insertedByUserId;
  String? lastUpdatedByUserId;
  String? photoPath;
  String? fromKm;
  String? toKm;
  String? photoPath2;
  String? isMissPunch;
  String? gpsPhotoPath;
  String? statusMsgShow;
  String? today;
  String? isGetInOutTime;

  GetAttendanceFromIdResultData({
    this.autoId,
    this.mobileNo,
    this.inTime,
    this.outTime,
    this.status,
    this.remarks,
    this.lat,
    this.long,
    this.gpsStatus,
    this.netStatus,
    this.insertedOn,
    this.lastUpdatedOn,
    this.insertedByUserId,
    this.lastUpdatedByUserId,
    this.photoPath,
    this.fromKm,
    this.toKm,
    this.photoPath2,
    this.isMissPunch,
    this.gpsPhotoPath,
    this.statusMsgShow,
    this.today,
    this.isGetInOutTime,
  });

  factory GetAttendanceFromIdResultData.fromJson(Map<String, dynamic> json) => GetAttendanceFromIdResultData(
    autoId: json["AutoId"],
    mobileNo: json["MobileNo"],
    inTime: json["InTime"],
    outTime: json["OutTime"],
    status: json["Status"],
    remarks: json["Remarks"],
    lat: json["Lat"],
    long: json["Long"],
    gpsStatus: json["GPSStatus"],
    netStatus: json["NetStatus"],
    insertedOn: json["InsertedOn"],
    lastUpdatedOn: json["LastUpdatedOn"],
    insertedByUserId: json["InsertedByUserId"],
    lastUpdatedByUserId: json["LastUpdatedByUserId"],
    photoPath: json["PhotoPath"],
    fromKm: json["FromKM"],
    toKm: json["ToKM"],
    photoPath2: json["PhotoPath2"],
    isMissPunch: json["IsMissPunch"],
    gpsPhotoPath: json["GPSPhotoPath"],
    statusMsgShow: json["StatusMsgShow"],
    today: json["Today"],
    isGetInOutTime: json["IsGetInOutTime"],
  );

  Map<String, dynamic> toJson() => {
    "AutoId": autoId,
    "MobileNo": mobileNo,
    "InTime": inTime,
    "OutTime": outTime,
    "Status": status,
    "Remarks": remarks,
    "Lat": lat,
    "Long": long,
    "GPSStatus": gpsStatus,
    "NetStatus": netStatus,
    "InsertedOn": insertedOn,
    "LastUpdatedOn": lastUpdatedOn,
    "InsertedByUserId": insertedByUserId,
    "LastUpdatedByUserId": lastUpdatedByUserId,
    "PhotoPath": photoPath,
    "FromKM": fromKm,
    "ToKM": toKm,
    "PhotoPath2": photoPath2,
    "IsMissPunch": isMissPunch,
    "GPSPhotoPath": gpsPhotoPath,
    "StatusMsgShow": statusMsgShow,
    "Today": today,
    "IsGetInOutTime": isGetInOutTime,
  };
}
