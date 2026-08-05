import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';

class TourVoucherRepository {
  final Dio _dio = Dio();


  // Get Tour Vouchers API
  Future<TourVoucherResponse> getTourVouchers({
    required String mobileNo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Format dates to "dd-MMM-yyyy" format as per API requirement
      final DateFormat formatter = DateFormat('dd-MMM-yyyy');
      final String fromDtStr = fromDate != null ? formatter.format(fromDate) : '';
      final String toDtStr = toDate != null ? formatter.format(toDate) : '';

      // Print API details before call
      print('📡 API Name: TourExpenseView');
      print('🌐 URL: ${ApiUrl.tourExpenseView}');
      print('📋 Parameters:');
      print('   MobileNo: $mobileNo');
      print('   FromDt: $fromDtStr');
      print('   ToDt: $toDtStr');

      final formData = FormData.fromMap({
        'MobileNo': mobileNo,
        'FromDt': fromDtStr,
        'ToDt': toDtStr,
      });

      final response = await _dio.post(
        ApiUrl.tourExpenseView,
        data: formData,
        options: Options(
          method: 'POST',
          headers: {'Content-Type': 'multipart/form-data'},
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Print response status
      print('✅ Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Print raw response data
        print('📦 Raw Response Length: ${response.data.toString().length}');

        // Handle the response which contains JSON + HTML
        String responseString = response.data.toString();

        // Find the JSON part in the response
        // JSON starts with '{' and ends before '<!DOCTYPE'
        int jsonStart = responseString.indexOf('{');
        int htmlStart = responseString.indexOf('<!DOCTYPE');

        if (jsonStart != -1) {
          String jsonString;
          if (htmlStart != -1) {
            // Extract JSON part before HTML
            jsonString = responseString.substring(jsonStart, htmlStart).trim();
            print(
                '🔍 Extracted JSON (before HTML): ${jsonString.length} chars');
          } else {
            // No HTML found, use entire response
            jsonString = responseString.substring(jsonStart).trim();
          }

          // Clean the JSON string (remove any trailing characters)
          jsonString = jsonString.trim();

          // Ensure JSON ends properly
          if (!jsonString.endsWith('}')) {
            int lastBrace = jsonString.lastIndexOf('}');
            if (lastBrace != -1) {
              jsonString = jsonString.substring(0, lastBrace + 1);
            }
          }

          print('🧹 Cleaned JSON: ${jsonString.length} chars');
          print(
              '📄 JSON Preview: ${jsonString.substring(0, _min(200, jsonString.length))}...');

          try {
            // Parse the cleaned JSON
            final Map<String, dynamic> responseData = json.decode(jsonString);

            // Print parsed response summary
            print('✅ Parsed Response Successfully');
            print('📊 Status: ${responseData['status']}');
            print('💬 Message: ${responseData['message']}');
            print(
                '📈 Result Count: ${responseData['result'] is List ? (responseData['result'] as List).length : 0}');

            return TourVoucherResponse.fromJson(responseData);
          } catch (e) {
            print('❌ Error parsing cleaned JSON: $e');
            print('❌ JSON that failed: $jsonString');
            return TourVoucherResponse(
              status: "400",
              message: "Error parsing JSON: $e",
              result: [],
            );
          }
        } else {
          print('❌ No JSON found in response');
          print(
              '❌ Response starts with: ${responseString.substring(0, _min(100, responseString.length))}');
          return TourVoucherResponse(
            status: "400",
            message: "No valid JSON found in response",
            result: [],
          );
        }
      } else {
        print('❌ API Error: ${response.statusMessage}');
        return TourVoucherResponse(
          status: response.statusCode?.toString() ?? "500",
          message: response.statusMessage ?? "Unknown error",
          result: [],
        );
      }
    } catch (error) {
      print('❌ Exception in getTourVouchers: $error');
      print('❌ Error type: ${error.runtimeType}');
      return TourVoucherResponse(
        status: "500",
        message: "Network error: $error",
        result: [],
      );
    }
  }

  // Update Tour Expense API
  // Add this method to TourVoucherRepository class
  Future<UpdateTourExpenseResponse> updateTourExpense({
    required TourVoucherModel voucher,
    required String mobileNo,
  }) async {
    try {
      // Prepare request data
      final requestData = {

        'Designation': voucher.designation,
        'ToPlace': voucher.toPlace,
        'OtherExpenses': voucher.otherExpenses,
        'EndTime': voucher.endTime,
        'NightHault': voucher.nighHault.toString(),
        'ExpenseId': voucher.expenseId,
        'StartTime': voucher.startTime,
        'TotalExpenses': voucher.totalExpenses,
        'Lodging': voucher.lodging,
        'AutoChargesDetail': voucher.autoChargesDetail,
        'FareAmt': voucher.fareAmount,
        'EmpMobileNo': mobileNo,
        'OtherChargesDetails': voucher.otherChargesDetail,
        'FromPlace': voucher.fromPlace,
        'TravellingBy': voucher.travellingBy,
        'FromDate': _formatDate(voucher.travelDt),
        'ToDate': _formatDate(voucher.travelToDt ?? voucher.travelDt),
        'DepartmentId': voucher.deptId,
        'AutoCharges': voucher.autoCharges,
        'DailyAllowance': voucher.dailyAllowance,

      };

      print('📡 Calling UpdateTourExpense API');
      print('🌐 URL: ${ApiUrl.API_UpdateTourExpense}');
      print('📋 Request Data: $requestData');

      final formData = FormData.fromMap(requestData);

      final response = await _dio.post(
        ApiUrl.API_UpdateTourExpense,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.plain,
        ),
      );

      print('✅ Update Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseString = response.data.toString();

        // Extract JSON part before HTML
        String jsonPart = responseString;
        final htmlStartIndex = responseString.indexOf('<!DOCTYPE');
        if (htmlStartIndex != -1) {
          jsonPart = responseString.substring(0, htmlStartIndex).trim();
        } else {
          final htmlStartIndex2 = responseString.indexOf('<html');
          if (htmlStartIndex2 != -1) {
            jsonPart = responseString.substring(0, htmlStartIndex2).trim();
          }
        }

        if (jsonPart.isEmpty) {
          throw Exception('No JSON response found');
        }

        final jsonResponse = json.decode(jsonPart);
        print('✅ Tour expense updated successfully');
        return UpdateTourExpenseResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to update: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ UpdateTourExpense Error: $error');
      return UpdateTourExpenseResponse(
        status: "500",
        message: "Network error: $error",
        result: null,
      );
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Extract date part from "18-Nov-2025 00:00:00"
      if (dateString.contains(' ')) {
        return dateString.split(' ')[0];
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  int _min(int a, int b) => a < b ? a : b;
}
