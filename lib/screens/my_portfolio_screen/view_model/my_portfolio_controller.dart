import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/my_portfolio_screen/model/my_portfolio_response_model.dart';
import 'package:waterman_iattandance/screens/my_portfolio_screen/model/select_portfolio_response_model.dart';

class MyPortfolioController extends GetxController {
  var isLoading = false.obs;

  /// Full list from API
  var portfolioList = <MyPortfolioViewResultData>[].obs;

  /// Filtered list (shown in UI)
  var filteredList = <MyPortfolioViewResultData>[].obs;

  /// Search text
  var searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPortfolio();
  }

  Future<void> fetchPortfolio() async {
    try {
      isLoading.value = true;

      var data = FormData.fromMap({
        'MobileNo': LocalDbController.to.mobileNo
      });

      var dio = Dio();
      var response = await dio.post(
        ApiUrl.API_ViewPortfolio,
        data: data,
      );

      if (response.statusCode == 200) {
        print("Response Data: ${response.data}");
        final model =
        MyPortfolioViewResponseModel.fromJson(response.data);

        portfolioList.assignAll(model.result ?? []);
        filteredList.assignAll(portfolioList);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }


  Future<SelectPortfolioResponseModel> fetchSelectedPortfolioDetails(String portfolioId) async {
    try {
      isLoading.value = true;

      var data = FormData.fromMap({
        'Id': portfolioId
      });

      var dio = Dio();
      var response = await dio.post(
        ApiUrl.selectPortfolioDetails,
        data: data,
      );

      if (response.statusCode == 200) {
        print("Selected portfolio Response Data>>>>>: ${response.data}");
        final model = SelectPortfolioResponseModel.fromJson(response.data);

        return model;
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    } finally {
      isLoading.value = false;
    } throw Exception("Failed to fetch selected portfolio details");
  }

  void filterSearch(String query) {
    searchText.value = query;

    if (query.isEmpty) {
      filteredList.assignAll(portfolioList);
      return;
    }

    final lowerQuery = query.toLowerCase();

    filteredList.assignAll(
      portfolioList.where((item) {
        return (item.companyName ?? '').toLowerCase().contains(lowerQuery) ||
            (item.city ?? '').toLowerCase().contains(lowerQuery) ||
            (item.contactPersonName ?? '').toLowerCase().contains(lowerQuery) ||
            (item.contactPersonMobileNo ?? '')
                .toLowerCase()
                .contains(lowerQuery);
      }).toList(),
    );
  }
}
