// To parse this JSON data, do
//
//     final getLastAttandancesResponseModel = getLastAttandancesResponseModelFromJson(jsonString);

import 'dart:convert';

GetLastAttandancesResponseModel getLastAttandancesResponseModelFromJson(String str) => GetLastAttandancesResponseModel.fromJson(json.decode(str));

String getLastAttandancesResponseModelToJson(GetLastAttandancesResponseModel data) => json.encode(data.toJson());

class GetLastAttandancesResponseModel {
  String? status;
  String? message;
  List<GetLastAttandancesResultData>? result;

  GetLastAttandancesResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory GetLastAttandancesResponseModel.fromJson(Map<String, dynamic> json) => GetLastAttandancesResponseModel(
    status: json["status"],
    message: json["message"],
    result: json["result"] == null ? [] : List<GetLastAttandancesResultData>.from(json["result"]!.map((x) => GetLastAttandancesResultData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class GetLastAttandancesResultData {
  String? inTime;
  String? outTime;
  String? status;
  Remarks? remarks;
  String? autoId;

  GetLastAttandancesResultData({
    this.inTime,
    this.outTime,
    this.status,
    this.remarks,
    this.autoId,
  });

  factory GetLastAttandancesResultData.fromJson(Map<String, dynamic> json) => GetLastAttandancesResultData(
    inTime: json["InTime"],
    outTime: json["OutTime"],
    status: json["Status"],
    remarks: remarksValues.map[json["Remarks"]],
    autoId: json["AutoId"],
  );

  Map<String, dynamic> toJson() => {
    "InTime": inTime,
    "OutTime": outTime,
    "Status": status,
    "Remarks": remarksValues.reverse[remarks],
    "AutoId": autoId,
  };
}

enum Remarks {
  EMPTY,
  TEST
}

final remarksValues = EnumValues({
  "": Remarks.EMPTY,
  "test": Remarks.TEST
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
