import 'dart:convert';

class DealerCategoryModel {
  final String textListId;
  final String text;

  DealerCategoryModel({
    required this.textListId,
    required this.text,
  });

  factory DealerCategoryModel.fromJson(Map<String, dynamic> json) {
    return DealerCategoryModel(
      textListId: json['TextListId'] ?? json['textListId'] ?? '',
      text: json['Text'] ?? json['text'] ?? '',
    );
  }
}

class DealerNameItemModel {
  final String dealerId;
  final String dealerName;

  DealerNameItemModel({
    required this.dealerId,
    required this.dealerName,
  });

  factory DealerNameItemModel.fromJson(Map<String, dynamic> json) {
    String name = '';
    if (json['Name'] != null) {
      name = json['Name'].toString().trim();
    } else if (json['DealerName'] != null) {
      name = json['DealerName'].toString().trim();
    } else if (json['Text'] != null) {
      name = json['Text'].toString().trim();
    } else if (json['text'] != null) {
      name = json['text'].toString().trim();
    } else if (json['name'] != null) {
      name = json['name'].toString().trim();
    }

    String id = '';
    if (json['DealerId'] != null) {
      id = json['DealerId'].toString().trim();
    } else if (json['DealerID'] != null) {
      id = json['DealerID'].toString().trim();
    } else if (json['Id'] != null) {
      id = json['Id'].toString().trim();
    } else if (json['id'] != null) {
      id = json['id'].toString().trim();
    } else {
      id = name;
    }

    if (id.isEmpty && name.isNotEmpty) {
      id = name;
    }

    return DealerNameItemModel(
      dealerId: id,
      dealerName: name,
    );
  }
}

class DealerCheckInStatusItem {
  final String dealerCheckInId;
  final String mobileNo;
  final String inTime;
  final String outTime;
  final String remarks;
  final String lat;
  final String long;
  final String insertedOn;
  final String lastUpdatedOn;
  final String insertedByUserId;
  final String lastUpdatedByUserId;
  final String gpsPhotoPath;
  final String dealerCategoryId;
  final String dealerCategory;
  final String dealerId;
  final String dealerName;
  final String statusMsgShow;
  final String today;

  DealerCheckInStatusItem({
    required this.dealerCheckInId,
    required this.mobileNo,
    required this.inTime,
    required this.outTime,
    required this.remarks,
    required this.lat,
    required this.long,
    required this.insertedOn,
    required this.lastUpdatedOn,
    required this.insertedByUserId,
    required this.lastUpdatedByUserId,
    required this.gpsPhotoPath,
    required this.dealerCategoryId,
    required this.dealerCategory,
    required this.dealerId,
    required this.dealerName,
    required this.statusMsgShow,
    required this.today,
  });

  factory DealerCheckInStatusItem.fromJson(Map<String, dynamic> json) {
    return DealerCheckInStatusItem(
      dealerCheckInId: json['DealerCheckInId']?.toString() ?? '',
      mobileNo: json['MobileNo']?.toString() ?? '',
      inTime: json['InTime']?.toString() ?? '',
      outTime: json['OutTime']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
      lat: json['Lat']?.toString() ?? '',
      long: json['Long']?.toString() ?? '',
      insertedOn: json['InsertedOn']?.toString() ?? '',
      lastUpdatedOn: json['LastUpdatedOn']?.toString() ?? '',
      insertedByUserId: json['InsertedByUserId']?.toString() ?? '',
      lastUpdatedByUserId: json['LastUpdatedByUserId']?.toString() ?? '',
      gpsPhotoPath: json['GPSPhotoPath']?.toString() ?? '',
      dealerCategoryId: json['DealerCategoryId']?.toString() ?? '',
      dealerCategory: json['DealerCategory']?.toString() ?? '',
      dealerId: json['DealerId']?.toString() ?? '',
      dealerName: json['DealerName']?.toString() ?? '',
      statusMsgShow: json['StatusMsgShow']?.toString() ?? '',
      today: json['Today']?.toString() ?? '',
    );
  }

  /// Active check-in = today's record (Today=="1") with InTime set and OutTime empty
  bool get isCheckedIn => today == '1' && inTime.isNotEmpty && outTime.isEmpty;
}

class MapDetailItem {
  final String lat;
  final String long;
  final String type;
  final String insertedOn;

  MapDetailItem({
    required this.lat,
    required this.long,
    required this.type,
    required this.insertedOn,
  });

  factory MapDetailItem.fromJson(Map<String, dynamic> json) {
    return MapDetailItem(
      lat: json['Lat']?.toString() ?? '',
      long: json['Long']?.toString() ?? '',
      type: json['Type']?.toString() ?? '',
      insertedOn: json['InsertedOn']?.toString() ?? '',
    );
  }
}
