import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import '../model/Insert_tour_voucher_model.dart';

class TourVoucherRepository {
  final Dio _dio = Dio();

  // 1. Get Back Dated Rights API
  Future<int> getBackDatedRights(String empId) async {
    try {
      final String url = ApiUrl.GetBack_DatedRights;
      print('📞 GetBackDatedRights API URL: $url');
      print('📞 GetBackDatedRights API for EmpId: $empId');

      final formData = FormData.fromMap({'EmpId': empId});

      final response = await _dio.post(
        ApiUrl.GetBack_DatedRights,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData['status'] == '200' &&
            responseData.containsKey('result')) {
          final result = responseData['result'] as List;
          if (result.isNotEmpty) {
            final noOfDays =
                int.tryParse(result[0]['NoOfDays']?.toString() ?? '0') ?? 0;
            print('✅ BackDatedRights NoOfDays: $noOfDays');
            return noOfDays;
          }
        }
      }
      return 0;
    } catch (e) {
      print('❌ GetBackDatedRights Error: $e');
      return 0;
    }
  }

  // 2. Check Entry Validation API
  Future<String> checkEntryValidation({
    required String mobileNo,
    required String type,
    required String fromDate,
    required String toDate,
    required String currentDate,
  }) async {
    try {
      final String url = ApiUrl.CheckEntryValidation;
      print('📞 CheckEntryValidation API URL: $url');
      print('📞 CheckEntryValidation API for MobileNo: $mobileNo, Type: $type');

      final formData = FormData.fromMap({
        'MobileNo': mobileNo,
        'Type': type,
        'FromDate': fromDate,
        'ToDate': toDate,
        'Date': currentDate,
      });

      final response = await _dio.post(
        ApiUrl.CheckEntryValidation,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData['status'] == '200' &&
            responseData.containsKey('result')) {
          final result = responseData['result'] as List;

          String foundEmpId = '';
          for (var item in result) {
            final empId = item['EmpId']?.toString() ?? '';
            if (empId.isNotEmpty && empId.trim() != '' && foundEmpId.isEmpty) {
              foundEmpId = empId;
              break; // Found first valid EmpId
            }
          }

          print('✅ Extracted EmpId: $foundEmpId');
          return foundEmpId;
        }
      }
      return '';
    } catch (e) {
      print('❌ CheckEntryValidation Error: $e');
      return '';
    }
  }

  // 3. Get Allow Tour Without PJC API
  Future<bool> getAllowTourWithoutPJC(String empId) async {
    try {
      final String url = ApiUrl.Get_AllowTour_Without_PJC;
      print('📞 GetAllowTourWithoutPJC API URL: $url');
      print('📞 GetAllowTourWithoutPJC API for EmpId: $empId');

      final formData = FormData.fromMap({'EmpId': empId});

      final response = await _dio.post(
        ApiUrl.Get_AllowTour_Without_PJC,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData['status'] == '200' &&
            responseData.containsKey('result')) {
          final result = responseData['result'] as List;
          if (result.isNotEmpty) {
            final allowPJC =
                result[0]['AllowPJC']?.toString().toLowerCase() == 'true';
            return allowPJC;
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ GetAllowTourWithoutPJC Error: $e');
      return false;
    }
  }

  // 3b. Check Attendance Status API
  Future<bool> checkAttendanceStatus({
    required String mobileNo,
    required String date,
  }) async {
    try {
      print('📞 CheckAttendanceStatus API → MobileNo: $mobileNo, Date: $date');
      final response = await http.post(
        Uri.parse(ApiUrl.checkAttendanceStatus),
        body: {
          'MobileNo': mobileNo,
          'Date': date,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📋 AttendanceStatus Response: $data');
        if (data['status'] == '200' && data.containsKey('result')) {
          final result = data['result'] as List;
          if (result.isNotEmpty) {
            final attnStatus =
                result.first['AttnStatus']?.toString().toUpperCase() ?? '';
            print('✅ AttnStatus: $attnStatus');
            return attnStatus == 'P';
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ CheckAttendanceStatus Error: $e');
      return false;
    }
  }

  // 4. Get Travel Options API
  Future<List<TravelByItem>> getTravelOptions() async {
    try {
      final String url = ApiUrl.Travelling_By;
      print('📞 Calling TravelBy API URL: $url');

      final formData = FormData.fromMap({'Type': 'TravelBy'});

      final response = await _dio.post(
        ApiUrl.Travelling_By,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData['status'] == '200' &&
            responseData.containsKey('result')) {
          final travelByResponse = TravelByResponse.fromJson(responseData);
          travelByResponse.result.sort((a, b) => a.text.compareTo(b.text));

          print('✅ Found ${travelByResponse.result.length} travel options');
          return travelByResponse.result;
        }
      }
      return [];
    } catch (e) {
      print('❌ TravelBy Error: $e');
      return [];
    }
  }

  // 5. Get New ID for PJC API
  Future<String?> getNewIdForPJC() async {
    try {
      final String url = ApiUrl.GetNewIdForPJC;
      print('📞 Calling GetNewIdForPJC API URL: $url');

      final response = await _dio.get(
        ApiUrl.GetNewIdForPJC,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData['status'] == '200' &&
            responseData.containsKey('result')) {
          final result = responseData['result'] as List;
          if (result.isNotEmpty) {
            final newId = result[0]['Column1']?.toString();
            print('✅ New ID for PJC: $newId');
            return newId;
          }
        }
      }

      print('⚠️ No valid ID received from GetNewIdForPJC');
      return null;
    } catch (e) {
      print('❌ GetNewIdForPJC Error: $e');
      return null;
    }
  }

  // 6. Upload Document API
  Future<UploadDocumentResponse> uploadDocument({
    required File file,
    required String attachmentType,
    required String userId,
    required String recordId,
  }) async {
    try {
      final String url = ApiUrl.API_UploadDocument;
      print('📤 UploadDocument API URL: $url');
      print('📤 Uploading document for RecordId: $recordId');

      String fileName = file.path.split('/').last;
      final multipartFile =
          await MultipartFile.fromFile(file.path, filename: fileName);

      final formData = FormData.fromMap({
        'files': [multipartFile],
        'AttachmentType': attachmentType,
        'UserId': userId,
        'RecordId': recordId,
        'File1': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      print('📤 FormData prepared for upload>>>>>>>: ${formData.fields}');

      final response = await _dio.post(
        ApiUrl.API_UploadDocument,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Document uploaded successfully');
        return UploadDocumentResponse.fromJson(response.data);
      }

      throw Exception('Upload failed with status: ${response.statusCode}');
    } catch (e) {
      print('❌ UploadDocument Error: $e');
      rethrow;
    }
  }

  // 7. Get Uploaded Document List API
  Future<UploadedDocListResponse> getUploadedDocList({
    required String attachmentType,
    required String recordId,
  }) async {
    try {
      final String url = ApiUrl.API_GetUploadedDocList;
      print('📋 GetUploadedDocList API URL: $url');
      print('📋 GetUploadedDocList for RecordId: $recordId');

      final formData = FormData.fromMap({
        'AttachmentType': attachmentType,
        'RecordId': recordId,
      });

      final response = await _dio.post(
        ApiUrl.API_GetUploadedDocList,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (responseData.containsKey('result')) {
          final result = UploadedDocListResponse.fromJson(responseData);
          print('✅ Found ${result.result.length} uploaded documents');
          return result;
        }

        return UploadedDocListResponse(
          status: responseData['status'] ?? '',
          message: responseData['message'] ?? '',
          result: [],
        );
      } else if (response.statusCode == 404) {
        print('❌ API endpoint not found: ${ApiUrl.API_GetUploadedDocList}');
        return UploadedDocListResponse(
          status: '404',
          message: 'API endpoint not found',
          result: [],
        );
      }

      throw Exception('Failed to get document list: ${response.statusCode}');
    } catch (e) {
      print('❌ GetUploadedDocList Error: $e');
      return UploadedDocListResponse(
        status: '209',
        message: e.toString(),
        result: [],
      );
    }
  }

  // 8. Delete Uploaded Document API
  Future<bool> deleteUploadedDocument({
    required String recordId,
    required String fuId,
  }) async {
    try {
      print('🗑️ DeleteUploadedDocument API URL: ${ApiUrl.deleteUploadedDoc}');
      print('🗑️ Deleting document → RecordId: $recordId, FUId: $fuId');

      final formData = FormData.fromMap({
        'RecordId': recordId,
        'FUId': fuId,
      });

      final response = await _dio.post(
        ApiUrl.deleteUploadedDoc,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        print('✅ DeleteUploadedDocument Response: $responseData');
        return responseData['status']?.toString() == '200';
      }

      print('⚠️ DeleteUploadedDocument failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ DeleteUploadedDocument Error: $e');
      return false;
    }
  }

  // 9. Insert Tour Expense API
  Future<InsertTourExpenseResponse> insertTourExpense({
    required InsertTourExpenseRequest request,
  }) async {
    try {
      final String url = ApiUrl.API_InsertTourExpense;
      print('📤 InsertTourExpense API URL: $url');
      print('📤 InsertTourExpense for EmpMobileNo: ${request.empMobileNo}');

      final formData = FormData.fromMap({
        'Designation': request.designation,
        'ToPlace': request.toPlace,
        'OtherExpenses': request.otherExpenses,
        'EndTime': request.endTime,
        'NightHault': request.nightHault.toString(),
        'ExpenseId': request.expenseId,
        'StartTime': request.startTime,
        'TotalExpenses': request.totalExpenses,
        'Lodging': request.lodging,
        'AutoChargesDetail': request.autoChargesDetail,
        'FareAmt': request.fareAmt,
        'EmpMobileNo': request.empMobileNo,
        'OtherChargesDetails': request.otherChargesDetails,
        'FromPlace': request.fromPlace,
        'TravellingBy': request.travellingBy,
        'FromDate': request.fromDate,
        'ToDate': request.toDate,
        'DepartmentId': request.departmentId,
        'AutoCharges': request.autoCharges,
        'DailyAllowance': request.dailyAllowance,
      });

      final response = await _dio.post(
        ApiUrl.API_InsertTourExpense,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.plain,
        ),
      );

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
      print('✅ Tour expense inserted successfully');
      return InsertTourExpenseResponse.fromJson(jsonResponse);
    } catch (e) {
      print('❌ InsertTourExpense Error: $e');
      return InsertTourExpenseResponse(
        status: '500',
        message: 'Error: ${e.toString()}',
        result: InsertTourExpenseResult(id: ''),
      );
    }
  }
}
