// tour_expense_repository_alternative.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waterman_iattandance/constant/api_url/api_url.dart';

class TourExpenseRepositoryAlternative {

  Future<dynamic> fetchTourExpenseData({
    required String mobileNo,
    required String fromDate,
    required String toDate,
  }) async {

    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrl.tourVoucherApprovalList),
      );

      request.fields['MobileNo'] = mobileNo;
      request.fields['FromDt'] = fromDate;
      request.fields['ToDt'] = toDate;

      request.headers['Accept'] = 'application/json';

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();

      print("Status Code: ${response.statusCode}");
      print("Raw Response: $responseBody");

      /// 🔥 CLEAN RESPONSE (REMOVE HTML PART)
      final cleanedBody = _cleanResponse(responseBody);

      print("Cleaned JSON: $cleanedBody");

      final jsonData = json.decode(cleanedBody);

      return jsonData;

    } catch (e) {

      print("Repository Error: $e");

      return {
        "status": "500",
        "message": "Exception occurred",
        "result": []
      };
    }
  }

  Future<Map<String, dynamic>> submitApproval({
    required String empId,
    required String expenseId,
    required String status,
    required String remarks,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrl.API_TourExpenseUpdateApprovalStatus),
      );

      request.fields['Remarks'] = remarks;
      request.fields['ExpenseId'] = expenseId;
      request.fields['EmpId'] = empId;
      request.fields['ApprovalStatus'] = status == 'Approved' ? 'A' : 'D';

      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Submit Status Code: ${response.statusCode}");
      print("Submit Raw Response: $responseBody");

      final cleanedBody = _cleanResponse(responseBody);
      final jsonData = json.decode(cleanedBody);

      return jsonData;
    } catch (e) {
      print("Repository Submit Error: $e");
      return {
        "status": "500",
        "message": "Exception occurred during submission",
        "result": []
      };
    }
  }

  /// 🔥 THIS METHOD REMOVES HTML FROM ASP.NET RESPONSE
  String _cleanResponse(String response) {

    String cleaned = response.replaceAll('\ufeff', '');

    int jsonStart = cleaned.indexOf('{');
    int jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1) {
      return cleaned.substring(jsonStart, jsonEnd + 1);
    }

    return cleaned;
  }
}