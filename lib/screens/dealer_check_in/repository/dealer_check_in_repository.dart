import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../flavor_config.dart';
import '../model/dealer_check_in_model.dart';

class DealerCheckInRepository {
  String get baseUrl => FlavorConfig.instance.baseUrl;

  /// Helper to clean HTML or unexpected response wrapping
  String _cleanResponse(String responseBody) {
    try {
      int firstBrace = responseBody.indexOf('{');
      int lastBrace = responseBody.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        return responseBody.substring(firstBrace, lastBrace + 1);
      }
    } catch (_) {}
    return responseBody;
  }

  /// 1. Fetch Dealer Categories
  Future<List<DealerCategoryModel>> fetchDealerCategories() async {
    try {
      final uri = Uri.parse("${baseUrl}API_TextListsForViewer.aspx");
      var request = http.MultipartRequest('POST', uri);
      request.fields['Type'] = 'Weekly';
      request.fields['DeptId'] = '';

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      final cleanedJson = _cleanResponse(responseBody);
      final data = json.decode(cleanedJson);

      if (data['result'] is List) {
        return (data['result'] as List)
            .map((e) => DealerCategoryModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching dealer categories: $e");
    }
    return [];
  }

  /// 2. Fetch Dealer Names for dropdown when required category selected
  Future<List<DealerNameItemModel>> fetchDealerNames({
    required String empId,
    required String dealerType,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}API_GetDealerAndDistributor.aspx");
      var request = http.MultipartRequest('POST', uri);
      request.fields['EmpId'] = empId;
      request.fields['DealerType'] = dealerType;

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      final cleanedJson = _cleanResponse(responseBody);
      final data = json.decode(cleanedJson);

      // status 209 = "No Record Found" — treat as empty list, not an error
      if (data['status'] == '209' || data['status'] == 209) {
        debugPrint("No dealers found for type: $dealerType");
        return [];
      }

      if (data['result'] is List) {
        return (data['result'] as List)
            .map((e) => DealerNameItemModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching dealer names: $e");
    }
    return [];
  }

  /// 3. Check Dealer Check-In/Out Status
  Future<List<DealerCheckInStatusItem>> checkDealerStatus({
    required String mobileNo,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}API_CheckDealerInOutStatus.aspx");
      var request = http.MultipartRequest('POST', uri);
      request.fields['Username'] = mobileNo;

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      final cleanedJson = _cleanResponse(responseBody);
      final data = json.decode(cleanedJson);

      if (data['result'] is List) {
        return (data['result'] as List)
            .map((e) => DealerCheckInStatusItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Error checking dealer status: $e");
    }
    return [];
  }

  /// 4. Submit Dealer Check-In / Check-Out
  Future<Map<String, dynamic>> submitDealerCheckInOut({
    required String dealerCategory,
    required String mobileNo,
    required String dealerCategoryId,
    required String dealerName,
    required String dealerId,
    required String lat,
    required String long,
    required String remarks,
    required String inTime,
    required String outTime,
    File? photoFile,
    File? frontPhotoFile,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}API_DealerCheckInOut.aspx");
      var request = http.MultipartRequest('POST', uri);

      // Verify if dealerId is a valid GUID format.
      // If it is not (e.g. it is a fallback name like "Ajay Machinery Store,Rohtak"),
      // we must send an empty string to avoid SQL conversion errors.
      final isGuid = RegExp(r'^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$').hasMatch(dealerId);
      final cleanDealerId = isGuid ? dealerId : '';

      request.fields['DealerCategory'] = dealerCategory;
      request.fields['MobileNo'] = mobileNo;
      request.fields['DealerCategoryId'] = dealerCategoryId;
      request.fields['DealerName'] = dealerName;
      request.fields['DealerId'] = cleanDealerId;
      request.fields['Lat'] = lat;
      request.fields['Long'] = long;
      request.fields['Remarks'] = remarks;
      request.fields['InTime'] = inTime;
      request.fields['OutTime'] = outTime;

      if (photoFile != null && await photoFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('PhotoPath', photoFile.path),
        );
      }

      if (frontPhotoFile != null && await frontPhotoFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('PhotoPath2', frontPhotoFile.path),
        );
      }

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      final cleanedJson = _cleanResponse(responseBody);

      debugPrint("Submit DealerCheckInOut Response: $cleanedJson");
      final data = json.decode(cleanedJson);

      return data is Map<String, dynamic>
          ? data
          : {"status": "200", "message": "Success", "result": data};
    } catch (e) {
      debugPrint("Error submitting dealer check-in/out: $e");
      return {"status": "500", "message": "Error: $e"};
    }
  }

  /// 5. Fetch Map Details for a specific Date and Mobile Number
  Future<List<MapDetailItem>> fetchMapDetails({
    required String mobileNo,
    required String date,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}API_MapDetails.aspx");
      var request = http.MultipartRequest('POST', uri);
      request.fields['MobileNo'] = mobileNo;
      request.fields['Date'] = date;

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      final cleanedJson = _cleanResponse(responseBody);
      final data = json.decode(cleanedJson);

      if (data['result'] is List) {
        final resultList = data['result'] as List;
        if (resultList.isNotEmpty) {
          if (resultList.first is List) {
            return (resultList.first as List)
                .map((e) => MapDetailItem.fromJson(e))
                .toList();
          } else {
            return resultList
                .map((e) => MapDetailItem.fromJson(e))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching map details: $e");
    }
    return [];
  }
}
