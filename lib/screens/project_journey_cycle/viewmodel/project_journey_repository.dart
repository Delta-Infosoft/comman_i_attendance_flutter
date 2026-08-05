import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/model/project_journey_model.dart';
import 'package:waterman_iattandance/flavor_config.dart';
import 'dart:convert';

class ProjectJourneyRepository {

  Future<BackDatedRightsResponse> getBackDatedRights(String empId) async {
    try {
      print('Starting getBackDatedRights API call');

      final url = ApiUrl.GetBack_DatedRights;
      print('URL: $url');

      http.Response response;
      if (FlavorConfig.instance.flavor == AppFlavor.singla) {
        // Send as form-data POST request for Singla
        final Map<String, String> bodyParams = {
          'EmpId': empId,
        };
        print('Sending POST request with bodyParams: $bodyParams');
        response = await http.post(
          Uri.parse(url),
          body: bodyParams,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ).timeout(const Duration(seconds: 30));
      } else {
        // Keep GET for Waterman
        final getUrl = '$url?EmpId=$empId';
        print('Sending GET request to $getUrl');
        response = await http.get(Uri.parse(getUrl)).timeout(const Duration(seconds: 30));
      }

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          String responseBody = response.body;
          if (responseBody.contains('{')) {
            int jsonStartIndex = responseBody.indexOf('{');
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
              responseBody = responseBody.substring(jsonStartIndex, jsonEndIndex + 1);
            }
          }

          final Map<String, dynamic> responseData = json.decode(responseBody);
          print('Parsed Response: $responseData');

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

  // ✅ FIXED: Method to get PJC Event data
  Future<GetPJCEventResponse> getPJCEvent(String mobileNo, String date) async {
    try {
      print('Starting getPJCEvent API call');
      print('URL: ${ApiUrl.GetPJCEvent}');
      print('Parameters - MobileNo: $mobileNo, Date: $date');

      final Map<String, String> bodyParams = {
        'MobileNo': mobileNo,
        'Date': date,
      };

      print('Sending POST request to PJC Event API...');

      final response = await http.post(
        Uri.parse(ApiUrl.GetPJCEvent),
        body: bodyParams,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 30));

      print('PJC Event Response Status: ${response.statusCode}');
      print('PJC Event Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Check if response is HTML
          if (response.body.contains('<!DOCTYPE html>') ||
              response.body.contains('<html>') ||
              response.body.contains('__VIEWSTATE')) {
            print('HTML response received from PJC Event API');

            // Try to extract JSON from HTML if exists
            if (response.body.contains('{') && response.body.contains('}')) {
              final jsonStart = response.body.indexOf('{');
              final jsonEnd = response.body.lastIndexOf('}') + 1;
              final jsonString = response.body.substring(jsonStart, jsonEnd);

              print('Extracted JSON from HTML: $jsonString');

              final Map<String, dynamic> responseData = json.decode(jsonString);
              final getPJCEventResponse =
                  GetPJCEventResponse.fromJson(responseData);
              return getPJCEventResponse;
            } else {
              // Return empty response for HTML
              print('No JSON found in HTML response, returning empty data');
              return GetPJCEventResponse(
                status: "200",
                message: "HTML response handled",
                result: [],
              );
            }
          } else {
            // Normal JSON response
            final Map<String, dynamic> responseData =
                json.decode(response.body);
            print('PJC Event Parsed Response: $responseData');

            final getPJCEventResponse =
                GetPJCEventResponse.fromJson(responseData);
            return getPJCEventResponse;
          }
        } catch (e) {
          print('PJC Event JSON Parse Error: $e');
          // Return empty response if parsing fails
          return GetPJCEventResponse(
            status: "200",
            message: "Fallback due to parse error",
            result: [],
          );
        }
      } else {
        print('PJC Event API ERROR: HTTP ${response.statusCode}');
        throw Exception(
            'Failed to fetch PJC Event data: ${response.statusCode}');
      }
    } catch (e) {
      print('PJC Event API EXCEPTION: $e');
      rethrow;
    }
  }

  // Method to insert PJC data
  Future<InsertPJCResponse> insertPJC(PJCCreateRequest request) async {
    try {
      print('API CALL: Inserting PJC data');
      print('URL: ${ApiUrl.InsertPJC}');

      final nightHaultString = request.nightHault ? 'true' : 'false';

      final Map<String, String> bodyParams = {
        'MobileNo': request.mobileNo,
        'NightHault': nightHaultString,
        'MonthYear': request.monthYear,
        'Date': request.date,
        'Place': request.place,
        'Notes': request.notes,
      };

      print('REQUEST PARAMETERS:');
      print('MobileNo: ${bodyParams['MobileNo']}');
      print('NightHault: ${bodyParams['NightHault']}');
      print('MonthYear: ${bodyParams['MonthYear']}');
      print('Date: ${bodyParams['Date']}');
      print('Place: ${bodyParams['Place']}');
      print('Notes: ${bodyParams['Notes']}');

      final response = await http.post(
        Uri.parse(ApiUrl.InsertPJC),
        body: bodyParams,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 30));

      print('API RESPONSE STATUS: ${response.statusCode}');
      print('API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final insertPJCResponse = InsertPJCResponse.fromJson(responseData);

        print('API SUCCESS: ${insertPJCResponse.message}');
        print('PJC Created with ID: ${insertPJCResponse.result.id}');

        return insertPJCResponse;
      } else {
        print('API ERROR: HTTP ${response.statusCode}');
        throw Exception('Failed to insert PJC: ${response.statusCode}');
      }
    } catch (e) {
      print('API EXCEPTION: $e');
      rethrow;
    }
  }

  // Method to get PJC data
  Future<GetPJCResponse> getPJC(String mobileNo, String monthYear) async {
    try {
      print('API CALL: Fetching PJC data');
      print('URL: ${ApiUrl.GetPJC}');
      print('Parameters - MobileNo: $mobileNo, MonthYear: $monthYear');

      final Map<String, String> bodyParams = {
        'MobileNo': mobileNo,
        'MonthYear': monthYear,
      };

      final response = await http.post(
        Uri.parse(ApiUrl.GetPJC),
        body: bodyParams,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 30));

      print('API RESPONSE STATUS: ${response.statusCode}');
      print('API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final getPJCResponse = GetPJCResponse.fromJson(responseData);

        print('API SUCCESS: ${getPJCResponse.message}');
        print('Total PJC Records: ${getPJCResponse.result.length}');

        return getPJCResponse;
      } else {
        print('API ERROR: HTTP ${response.statusCode}');
        throw Exception('Failed to fetch PJC data: ${response.statusCode}');
      }
    } catch (e) {
      print('API EXCEPTION: $e');
      rethrow;
    }
  }

  // Fallback methods
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
            noOfDays: "40",
            fromPJCDate: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
            toPJCDate: DateFormat('dd-MMM-yyyy')
                .format(DateTime.now().add(const Duration(days: 40))),
          )
        ],
      );
    }
  }

  Future<GetPJCEventResponse> getPJCEventWithFallback(
      String mobileNo, String date) async {
    try {
      return await getPJCEvent(mobileNo, date);
    } catch (e) {
      print('PJC Event API failed, using fallback data: $e');
      return GetPJCEventResponse(
        status: "200",
        message: "Fallback Data",
        result: [],
      );
    }
  }
}
