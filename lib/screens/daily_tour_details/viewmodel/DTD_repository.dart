import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/model/check_backed_date_rights_responses_model.dart';
import '../../project_journey_cycle/model/project_journey_model.dart';
import '../model/DTD_model.dart';

class DTDRepository {

  Future<CheckEntryValidationResponse> checkEntryValidation(
      CheckEntryValidationRequest request) async {
    try {
      print('🔄 Checking Entry Validation...');
      final response = await http.post(
        Uri.parse('${ApiUrl.checkEntryValidation}'),
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CheckEntryValidationResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to check entry validation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking entry validation: $e');
    }
  }

  Future<CheckAttendanceStatusResponse> checkAttendanceStatus(
      CheckAttendanceStatusRequest request) async {
    try {
      print('🔄 Checking Attendance Status...');
      final response = await http.post(
        Uri.parse(ApiUrl.checkAttendanceStatus),
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📋 Attendance Status Response: $data');
        return CheckAttendanceStatusResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to check attendance status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking attendance status: $e');
    }
  }

  Future<BackDatedRightsResponse> getBackDatedRightsWithFallback(
      String empId) async {
    try {
      return await getBackDatedRights(empId);
    } catch (e) {
      print('API failed, using fallback data for back-dated rights: $e');
      return BackDatedRightsResponse(
        status: "200",
        message: "Fallback Data",
        result: [
          BackDatedRights(
            noOfDays: "0",
            fromPJCDate: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
            toPJCDate: DateFormat('dd-MMM-yyyy')
                .format(DateTime.now()),
          )
        ],
      );
    }
  }

  Future<BackDatedRightsResponse> getBackDatedRights(String empId) async {
    try {
      print('Starting getBackDatedRights API call');

      final url = '${ApiUrl.GetBack_DatedRights}';
      print('URL: $url');

      final response = await http.post(
        Uri.parse(url),
        body: {'EmpId': empId},
      ).timeout(const Duration(seconds: 30));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API call successful, processing response...${response}');
        try {
          String responseBody = response.body;
          if (responseBody.contains('{') && responseBody.contains('}')) {
            final jsonStart = responseBody.indexOf('{');
            final jsonEnd = responseBody.lastIndexOf('}') + 1;
            responseBody = responseBody.substring(jsonStart, jsonEnd);
          }

          final Map<String, dynamic> responseData = json.decode(responseBody);
          print('BAck Date Rights Parsed Response>>>>>>>>>>: $responseData');

          final backDatedRightsResponse =
          BackDatedRightsResponse.fromJson(responseData);

          if (backDatedRightsResponse.status == "200") {
            print('Back-dated rights loaded successfully');
            return backDatedRightsResponse;
          } else {
            throw Exception(
                'API returned error: ${backDatedRightsResponse.message}');
          }
        } catch (e) {
          print('JSON Parse Error: $e');
          throw Exception('Failed to parse API response: $e');
        }
      } else {
        print('API ERROR: HTTP ${response.statusCode}');
        throw Exception(
            'Failed to load back-dated rights: ${response.statusCode}');
      }
    } catch (e) {
      print('API EXCEPTION: $e');
      rethrow;
    }
  }


  Future<AllowTourWithoutPJCResponse> getAllowTourWithoutPJC(
      AllowTourWithoutPJCRequest request) async {
    try {
      print('🔄 Getting Allow Tour Without PJC...');
      final response = await http.post(
        Uri.parse('${ApiUrl.getAllowedTourWithoutPJC}'),
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AllowTourWithoutPJCResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to get allow tour without PJC: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting allow tour without PJC: $e');
    }
  }

  Future<List<District>> getDistricts() async {
    try {
      print('🔄 Fetching Districts...');
      final response = await http.get(
        Uri.parse('${ApiUrl.districtList}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        String jsonString = _extractJsonFromResponse(responseBody);

        if (jsonString.isEmpty) {
          throw Exception('No JSON data found in response');
        }

        final Map<String, dynamic> jsonResponse = json.decode(jsonString);
        final districtResponse = DistrictResponse.fromJson(jsonResponse);

        final uniqueDistricts = districtResponse.result.toSet().toList()
          ..sort((a, b) => a.district.compareTo(b.district));

        return uniqueDistricts;
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load districts: $e');
    }
  }

  Future<List<TextListItem>> getDealerCategories() async {
    try {
      print('🔄 Fetching Dealer Categories...');
      final response = await http.post(
        Uri.parse('${ApiUrl.dealerCategoryList}'),
        body: {'Type': 'Weekly', 'DeptId': ''},
      );

      if (response.statusCode == 200) {

        final responseBody = response.body.trim();
        String jsonString = _extractJsonFromResponse(responseBody);

        if (jsonString.isEmpty) {
          throw Exception('No JSON data found in response');
        }

        final Map<String, dynamic> jsonResponse = json.decode(jsonString);
        print('Dealer Categories Parsed Response>>>>>>>>>>: ${jsonResponse}');
        final textListResponse = TextListResponse.fromJson(jsonResponse);


        final uniqueCategories = textListResponse.result.toSet().toList()
          ..sort((a, b) => a.text.compareTo(b.text));

        return uniqueCategories;
      } else {
        throw Exception(
            'Failed to load dealer categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load dealer categories: $e');
    }
  }

  Future<WeeklyTourDetailResponse> insertWeeklyTourDetail(
      WeeklyTourDetailRequest request) async {
    try {
      print('🔄 Inserting Weekly Tour Detail...');
      final response = await http.post(
        Uri.parse('${ApiUrl.insertWeeklyTourDetail}'),
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeeklyTourDetailResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to insert weekly tour detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error inserting weekly tour detail: $e');
    }
  }

  Future<Map<String, dynamic>> getWeeklyDetails({
    required String mobileNo,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      print('🔄 Fetching Weekly Details...');
      print('📱 Mobile: $mobileNo');
      print('📅 Range: $fromDate to $toDate');

      final dio = Dio();
      final Map<String, dynamic> dataMap = {
        'MobileNo': mobileNo,
      };
      
      // Omit date parameters if they are empty or null to match working Postman configuration
      if (fromDate != null && fromDate.trim().isNotEmpty) {
        dataMap['FromDt'] = fromDate;
      }
      if (toDate != null && toDate.trim().isNotEmpty) {
        dataMap['toDt'] = toDate;
      }
      final formData = FormData.fromMap(dataMap);

      final response = await dio.post(
        ApiUrl.weeklyTourDetailsView,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          responseType: ResponseType.plain,
        ),
      );
      print('Api URL>>>: ${ApiUrl.weeklyTourDetailsView}');

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.data}');

      // Extract JSON from response
      String jsonString = _extractJsonFromResponse(response.data.toString());

      if (jsonString.isEmpty) {
        print('❌ No JSON data found in response');
        return {
          'status': 'error',
          'message': 'No data found in response',
          'result': []
        };
      }

      print('✅ JSON extracted successfully: $jsonString');

      try {
        final Map<String, dynamic> responseData = json.decode(jsonString);
        print('📊 Decoded JSON - Status: ${responseData['status']}');

        return _processWeeklyDetailsResponse(responseData);
      } catch (e) {
        print('❌ Error parsing JSON: $e');
        return {
          'status': 'error',
          'message': 'JSON parsing failed: $e',
          'result': []
        };
      }
    } catch (e) {
      print('❌ Exception fetching weekly details: $e');
      return {'status': 'error', 'message': 'Network error: $e', 'result': []};
    }
  }

  String _extractJsonFromResponse(String responseBody) {
    print('🔍 Extracting JSON from response via brace counting...');

    int jsonStartIndex = responseBody.indexOf('{');
    if (jsonStartIndex == -1) {
      print('❌ No { found in response');
      return '';
    }

    int braceCount = 0;
    int jsonEndIndex = -1;

    for (int i = jsonStartIndex; i < responseBody.length; i++) {
      if (responseBody[i] == '{') {
        braceCount++;
      } else if (responseBody[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          jsonEndIndex = i;
          break;
        }
      }
    }

    if (jsonEndIndex != -1) {
      String jsonString = responseBody.substring(jsonStartIndex, jsonEndIndex + 1);
      print('Spacer/Brace Match: Extracted ${jsonString.length} chars');
      return jsonString;
    }

    print('❌ Matching } not found');
    return '';
  }

  Map<String, dynamic> _processWeeklyDetailsResponse(
      Map<String, dynamic> responseData) {
    print('🔄 Processing API response...');

    String status = responseData['status']?.toString() ?? '';
    String message = responseData['message']?.toString() ?? '';

    print('📊 Response - Status: $status, Message: $message');

    if (status == '200') {
      // Success case
      List<dynamic> result = responseData['result'] ?? [];
      print('✅ API Success - Found ${result.length} records');

      return {
        'status': 'success',
        'message': message.isNotEmpty ? message : 'Data fetched successfully',
        'result': result
      };
    } else if (status == '209') {
      // Server limit error - return empty data but success status
      print('🚫 Server Limit Error: $message');

      return {
        'status': 'success', // Return success to maintain UI flow
        'message': 'Data available but server cannot display',
        'result': []
      };
    } else {
      // Other errors
      print('❌ API Error: $status - $message');

      return {
        'status': 'error',
        'message':
            message.isNotEmpty ? message : 'API returned error status: $status',
        'result': []
      };
    }
  }
}
