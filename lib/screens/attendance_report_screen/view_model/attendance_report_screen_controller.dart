import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/screens/attendance_report_screen/model/get_month_list_response_model.dart';

import '../../../constant/local_db/local_db.dart';
import '../../home/model/get_last_attandances_response_model.dart';


class AttendanceReportScreenController extends GetxController{
  var isLoading = true.obs;

  void onInit(){
    // fetchLastAttandances();
    super.onInit();
  }


  Future<GetMonthListResponseModel> getMonthList()async{
    var dio = Dio();
    var response = await dio.request(
      '${ApiUrl.getMonthList}',
      options: Options(
        method: 'GET',
      ),
    );

    if (response.statusCode == 200) {
      print('Month List >>>>>>>${response.data}');
      return GetMonthListResponseModel.fromJson(response.data);
    }
    else {
      print(response.statusMessage);
    }
    throw Exception();
  }


  var lastAttendances = <GetLastAttandancesResultData>[].obs;

  Future<void> fetchLastAttandances(String month) async {
    String user = LocalDbController.to.mobileNo;
    try {
      isLoading(true);

      lastAttendances.clear();

      var data = FormData.fromMap({
        'MobileNo': user,
        'Month': month
      });

      var dio = Dio();
      var response = await dio.request(
        '${ApiUrl.getLastAttandanceDetails}',
        options: Options(method: 'POST'),
        data: data,
      );

      if (response.statusCode == 200) {
        print('Attendance Report>>>>>>>>${response.data}');
        final model = GetLastAttandancesResponseModel.fromJson(response.data);
        lastAttendances.value = model.result ?? [];
      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      isLoading(false);
    }
  }
}