import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData,MultipartFile;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waterman_iattandance/constant/api_url/api_url.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/new_customer_dealer_screen/model/insert_portfolio_responses_model.dart';


class NewCustomerDealerController extends GetxController {
  TextEditingController companyNameController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController contactPersonNameController = TextEditingController();
  TextEditingController contactPersonMobileNoController = TextEditingController();
  TextEditingController contactPersonEmailController = TextEditingController();
  TextEditingController remarkController = TextEditingController();


  GoogleMapController? mapController;

  // LatLng? currentPosition;
  Set<Marker>markers = {};

  Position? currentPosition;
  LatLng? currentLatLng;


  @override
  void onInit() {
    loadCurrentLocation();
    super.onInit();
  }

  Future<void> loadCurrentLocation() async {
    final pos = await _getCurrentLocation();

    currentPosition = pos;
    currentLatLng = LatLng(pos.latitude, pos.longitude);

    update(); // GetX refresh
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<InsertPortfolioResponseModel> insertNewCustomerDealer({
    String? photoPath,
    String? photoPath1,
    String? photoPath2,
    String? photoPath3,
    String? photoPath4,
  }) async {
    if (currentPosition == null) {
      throw Exception("Location not available");
    }

    double latitude = currentPosition!.latitude;
    double longitude = currentPosition!.longitude;

    Map<String, dynamic> dataMap = {
      'CompanyName': companyNameController.text,
      'ContactPersonEmailId': contactPersonEmailController.text,
      'InsertedByUserId': LocalDbController.to.autoId,
      'Remarks': remarkController.text,
      'ContactPersonName': contactPersonNameController.text,
      'Long': longitude.toString(),
      'Lat': latitude.toString(),
      'ContactPersonMobileNo': contactPersonMobileNoController.text,
      'City': cityController.text,
    };

    /// 📸 Attach images properly
    if (photoPath != null && photoPath.isNotEmpty) {
      dataMap['PhotoPath'] = await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      );
    }

    if (photoPath1 != null && photoPath1.isNotEmpty) {
      dataMap['PhotoPath1'] = await MultipartFile.fromFile(
        photoPath1,
        filename: photoPath1.split('/').last,
      );
    }

    if (photoPath2 != null && photoPath2.isNotEmpty) {
      dataMap['PhotoPath2'] = await MultipartFile.fromFile(
        photoPath2,
        filename: photoPath2.split('/').last,
      );
    }

    if (photoPath3 != null && photoPath3.isNotEmpty) {
      dataMap['PhotoPath3'] = await MultipartFile.fromFile(
        photoPath3,
        filename: photoPath3.split('/').last,
      );
    }

    if (photoPath4 != null && photoPath4.isNotEmpty) {
      dataMap['PhotoPath4'] = await MultipartFile.fromFile(
        photoPath4,
        filename: photoPath4.split('/').last,
      );
    }

    final formData = FormData.fromMap(dataMap);

    /// ✅ Proper debug log
    print("Insert request fields >>> ${formData.fields}");
    print("Insert request files >>> ${formData.files.map((e) => e.key)}");

    final dio = Dio();
    final response = await dio.post(
      ApiUrl.insertPortfolio,
      data: formData,
    );

    if (response.statusCode == 200) {
      print('Insert Successful>>>>>>>>: ${response.data}');
      return InsertPortfolioResponseModel.fromJson(response.data);
    }

    throw Exception("Insert failed");
  }


  Future<InsertPortfolioResponseModel> updateCustomerDealer({
    required String portfolioId,
    String? photoPath,
    String? photoPath1,
    String? photoPath2,
    String? photoPath3,
    String? photoPath4,
  }) async {
    if (currentPosition == null) {
      throw Exception("Location not available");
    }

    double latitude = currentPosition!.latitude;
    double longitude = currentPosition!.longitude;

    Map<String, dynamic> dataMap = {
      'PortfolioId': portfolioId,
      'CompanyName': companyNameController.text,
      'ContactPersonEmailId': contactPersonEmailController.text,
      'InsertedByUserId': LocalDbController.to.insertedByUserId.toString(),
      'Remarks': remarkController.text,
      'ContactPersonName': contactPersonNameController.text,
      'Long': longitude.toString(),
      'Lat': latitude.toString(),
      'ContactPersonMobileNo': contactPersonMobileNoController.text,
      'City': cityController.text,
    };

    /// 📸 Attach images properly
    if (photoPath != null && photoPath.isNotEmpty) {
      dataMap['PhotoPath'] = await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      );
    }

    if (photoPath1 != null && photoPath1.isNotEmpty) {
      dataMap['PhotoPath1'] = await MultipartFile.fromFile(
        photoPath1,
        filename: photoPath1.split('/').last,
      );
    }

    if (photoPath2 != null && photoPath2.isNotEmpty) {
      dataMap['PhotoPath2'] = await MultipartFile.fromFile(
        photoPath2,
        filename: photoPath2.split('/').last,
      );
    }

    if (photoPath3 != null && photoPath3.isNotEmpty) {
      dataMap['PhotoPath3'] = await MultipartFile.fromFile(
        photoPath3,
        filename: photoPath3.split('/').last,
      );
    }

    if (photoPath4 != null && photoPath4.isNotEmpty) {
      dataMap['PhotoPath4'] = await MultipartFile.fromFile(
        photoPath4,
        filename: photoPath4.split('/').last,
      );
    }

    final formData = FormData.fromMap(dataMap);

    /// ✅ Proper debug log
    print("Update request fields >>> ${formData.fields}");
    print("Update request files >>> ${formData.files.map((e) => e.key)}");

    final dio = Dio();
    final response = await dio.post(
      ApiUrl.updatePortfolioDetails,
      data: formData,
    );
    print('API URL UPDate portfollio >>>>${ApiUrl.updatePortfolioDetails}');

    if (response.statusCode == 200) {
      return InsertPortfolioResponseModel.fromJson(response.data);
    } else if(response.statusCode == 209) {
      print('ERoorrr>>>>>>${response.data['message']}');
    }


    throw Exception("Update failed");
  }



  // Future<InsertPortfolioResponseModel> insertNewCustomerDealer() async {
  //
  //   if (currentPosition == null) {
  //     throw Exception("Location not available");
  //   }
  //
  //   double latitude = currentPosition!.latitude;
  //   double longitude = currentPosition!.longitude;
  //
  //   var data = FormData.fromMap({
  //     'CompanyName': companyNameController.text,
  //     'ContactPersonEmailId': contactPersonEmailController.text,
  //     'InsertedByUserId': LocalDbController.to.autoId.toString(),
  //     'Remarks': remarkController.text,
  //     'ContactPersonName': contactPersonNameController.text,
  //     'Long': longitude.toString(),
  //     'Lat': latitude.toString(),
  //     'ContactPersonMobileNo': contactPersonMobileNoController.text,
  //     'City': cityController.text,
  //   });
  //   print('Insert request Data>>>>>>>>: ${data.fields}');
  //
  //   var dio = Dio();
  //   var response = await dio.post(ApiUrl.insertPortfolio, data: data);
  //
  //   if (response.statusCode == 200) {
  //     print('Insert Successful>>>>>>>>: ${response.data}');
  //     return InsertPortfolioResponseModel.fromJson(response.data);
  //   }
  //
  //   throw Exception("Insert failed");
  // }
}
