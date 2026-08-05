import 'package:flutter/material.dart';
import 'package:waterman_iattandance/flavor_config.dart';

class ApiUrl {
  // Runtime override — used by the background isolate (which cannot access
  // FlavorConfig). When null, BASE_URL falls back to FlavorConfig.instance.baseUrl.
  static String? _baseUrlOverride;

  static String get BASE_URL =>
      _baseUrlOverride ?? FlavorConfig.instance.baseUrl;

  /// Allows the background service isolate to set the URL at runtime.
  static set BASE_URL(String url) => _baseUrlOverride = url;


  // ================== API ENDPOINTS ==================

  static String get GetBack_DatedRights =>
      "${BASE_URL}API_GetBackDatedRights.aspx";

  static String get TourExpenseView =>
      "${BASE_URL}API_TourExpenseView.aspx";

  static String get API_UploadDocument =>
      "${BASE_URL}API_UploadDocument.aspx";

  static String get API_InsertTourExpense =>
      "${BASE_URL}API_InsertTourExpense.aspx";

  static String get API_GetUploadedDocList =>
      "${BASE_URL}API_GetUploadedDocList.aspx";

  static String get GetNewIdForPJC =>
      "${BASE_URL}API_GetNewIdForPJC.aspx";

  static String get ITV_GetBack_DatedRights =>
      "${BASE_URL}API_GetBackDatedRights.aspx";

  static String get CheckEntryValidation =>
      "${BASE_URL}API_CheckEntryValidation.aspx";

  static String get InsertPJC =>
      "${BASE_URL}API_InsertPJC.aspx";

  static String get GetPJC =>
      "${BASE_URL}API_GetPJC.aspx";

  static String get GetPJCEvent =>
      "${BASE_URL}API_GetPJCEvent.aspx";

  static String get API_UpdateTourExpense =>
      "${BASE_URL}API_UpdateTourExpense.aspx";

  static String get API_TourExpenseUpdateApprovalStatus =>
      "${BASE_URL}API_TourExpenseUpdateApprovalStatus.aspx";

  static String get CheckEntry_Validation =>
      "${BASE_URL}API_CheckEntryValidation.aspx";

  static String get Get_AllowTour_Without_PJC =>
      "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";

  static String get ITV_Get_AllowTour_Without_PJC =>
      "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";

  static String get GetDistrictList =>
      "${BASE_URL}API_GetDistrictList.aspx";

  static String get TextLists_ForViewer =>
      "${BASE_URL}API_TextListsForViewer.aspx";

  static String get Insert_WeeklyTour_Detail =>
      "${BASE_URL}API_InsertWeeklyTourDetail.aspx";

  static String get Weekly_DetailsView =>
      "${BASE_URL}API_WeeklyDetailsView.aspx";

  static String get TourExpense_ApprovalList =>
      "${BASE_URL}API_TourExpenseApprovalList.aspx";

  static String get Travelling_By =>
      "${BASE_URL}API_TextLists.aspx";

  static String get userValidLogin =>
      "${BASE_URL}API_UserValid.aspx";

  static String get loginWithFcmId =>
      "${BASE_URL}API_LoginWithFCMId.aspx";

  static String get logoutWithFcmid =>
      "${BASE_URL}API_LogoutWithFCMId.aspx";

  static String get attandanceTextList =>
      "${BASE_URL}API_TextLists.aspx";

  static String get attandanceInOut =>
      "${BASE_URL}API_AttendanceInOut.aspx";

  static String get getLastAttandanceDetails =>
      "${BASE_URL}API_GetLastAttendances.aspx";

  static String get getCheckinoutStatus =>
      "${BASE_URL}API_CheckInOutStatus.aspx";

  static String get tourVoucherApprovalList =>
      "${BASE_URL}API_TourExpenseApprovalList.aspx";

  static String get weeklyTourDetailsView =>
      "${BASE_URL}API_WeeklyDetailsView.aspx";

  static String get insertWeeklyTourDetail =>
      "${BASE_URL}API_InsertWeeklyTourDetail.aspx";

  static String get dealerCategoryList =>
      "${BASE_URL}API_TextListsForViewer.aspx";

  static String get districtList =>
      "${BASE_URL}API_GetDistrictList.aspx";

  static String get getAllowedTourWithoutPJC =>
      "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";

  static String get checkEntryValidation =>
      "${BASE_URL}API_CheckEntryValidation.aspx";

  static String get checkAttendanceStatus =>
      "${BASE_URL}API_CheckAttendanceStatus.aspx";

  static String get tourExpenseView =>
      "${BASE_URL}API_TourExpenseView.aspx";

  static String get getMonthList =>
      "${BASE_URL}API_GetMonth.aspx";

  static String get insertPortfolio =>
      "${BASE_URL}API_InsertPortfolio.aspx";

  static String get API_ViewPortfolio =>
      "${BASE_URL}API_ViewPortfolio.aspx";

  static String get selectPortfolioDetails =>
      "${BASE_URL}API_SelectPortfolio.aspx";

  static String get updatePortfolioDetails =>
      "${BASE_URL}API_UpdatePortfolio.aspx";

  static String get FollowUps =>
      "${BASE_URL}API_FollowUps.aspx";

  static String get InsertlatLong =>
      "${BASE_URL}API_InsertLatLong.aspx";

  static String get GetAttendanceFromID =>
      "${BASE_URL}API_GetAttendanceFromId.aspx";

  static String get GetAttendanceStatusUpdate =>
      "${BASE_URL}API_AttendanceStatusUpdate.aspx";

  static String get GetEmpCoffDate => "${BASE_URL}API_GetEmpCOFFDates.aspx";

  static String get deleteUploadedDoc => "${BASE_URL}API_DeleteUploadedDocument.aspx";

  static String get mapDetails => "${BASE_URL}API_MapDetails.aspx";

  // static String get checkAttendanceStatus => "${BASE_URL}API_CheckAttendanceStatus.aspx";

  // ================== WEB URLS ==================

  static String iERPHoWebLogin = "/DeltaiERP/login.aspx";
  static String iERPNagpurWebLogin = "/iERPNagpur/Login.aspx";
  static String locationLogs = "/LocationLogList.aspx";

  static const String iERPKolkataLogin =
      "/iERPKolkata/Login.aspx";

  static const String WIPLPJCWebLogin =
      "/DeltaViewerWIPL/login.aspx?ReturnUrl=%2fDeltaViewerWIPL%2fGeneral%2fDefault.aspx";




}






// class ApiUrl {
//   static  String BASE_URL =
//       "http://103.113.32.126/DeltaAttendanceAPIWIPL/";
//       // "http://galaxy.ierp.in:90/AmrutAttendanceAPI/";
//       // "http://192.168.0.101:90/AmrutAttendanceAPI/";
//
//   static  String GetBack_DatedRights =
//       "${BASE_URL}API_GetBackDatedRights.aspx";
//
//   static  String TourExpenseView = "${BASE_URL}API_TourExpenseView.aspx";
//
//   static  String API_UploadDocument = "${BASE_URL}API_UploadDocument.aspx";
//
//   static  String API_InsertTourExpense =
//       "${BASE_URL}API_InsertTourExpense.aspx";
//
//   static  String API_GetUploadedDocList =
//       "${BASE_URL}API_GetUploadedDocList.aspx";
//
//   static  String GetNewIdForPJC = "${BASE_URL}API_GetNewIdForPJC.aspx";
//
//   static  String ITV_GetBack_DatedRights =
//       "${BASE_URL}API_GetBackDatedRights.aspx";
//
//   static  String CheckEntryValidation =
//       "${BASE_URL}API_CheckEntryValidation.aspx";
//
//   static  String InsertPJC = "${BASE_URL}API_InsertPJC.aspx";
//
//   static  String GetPJC = "${BASE_URL}API_GetPJC.aspx";
//
//   static  String GetPJCEvent = "${BASE_URL}API_GetPJCEvent.aspx";
//
//   static  String API_UpdateTourExpense =
//       "${BASE_URL}API_UpdateTourExpense.aspx";
//
//   static  String CheckEntry_Validation =
//       "${BASE_URL}API_CheckEntryValidation.aspx";
//
//   static  String Get_AllowTour_Without_PJC =
//       "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";
//
//   static  String ITV_Get_AllowTour_Without_PJC =
//       "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";
//
//   static  String GetDistrictList = "${BASE_URL}API_GetDistrictList.aspx";
//
//   static  String TextLists_ForViewer =
//       "${BASE_URL}API_TextListsForViewer.aspx";
//
//   static  String Insert_WeeklyTour_Detail =
//       "${BASE_URL}API_InsertWeeklyTourDetail.aspx";
//
//   static  String Weekly_DetailsView =
//       "${BASE_URL}API_WeeklyDetailsView.aspx";
//
//   static  String TourExpense_ApprovalList =
//       "${BASE_URL}API_TourExpenseApprovalList.aspx";
//
//   static  String Travelling_By = "${BASE_URL}API_TextLists.aspx";
//
//   static  String userValidLogin =
//       //"/DeltaAttendanceAPIWIPL/API_UserValid.aspx";
//       "${BASE_URL}API_UserValid.aspx";
//
//   static  String loginWithFcmId =
//       //"/DeltaAttendanceAPIWIPL/API_LoginWithFCMId.aspx";
//       "${BASE_URL}API_LoginWithFCMId.aspx";
//
//   static  String logoutWithFcmid =
//       //"/DeltaAttendanceAPIWIPL/API_LogoutWithFCMId.aspx";
//       "${BASE_URL}API_LogoutWithFCMId.aspx";
//
//   static  String iERPHoWebLogin = "/DeltaiERP/login.aspx";
//
//   static  String iERPNagpurWebLogin = "/iERPNagpur/Login.aspx";
//
//   static const String iERPKolkataLogin = "/iERPKolkata/Login.aspx";
//
//   static  String attandanceTextList =
//       //"/DeltaAttendanceAPIWIPL/API_TextLists.aspx";
//       "${BASE_URL}API_TextLists.aspx";
//
//   static  String attandanceInOut =
//       //"/DeltaAttendanceAPIWIPL/API_AttendanceInOut.aspx";
//       "${BASE_URL}API_AttendanceInOut.aspx";
//
//   static  String getLastAttandanceDetails =
//       //"/DeltaAttendanceAPIWIPL/API_GetLastAttendances.aspx";
//       "${BASE_URL}API_GetLastAttendances.aspx";
//
//   static const String WIPLPJCWebLogin =
//       "/DeltaViewerWIPL/login.aspx?ReturnUrl=%2fDeltaViewerWIPL%2fGeneral%2fDefault.aspx";
//
//   static  String getCheckinoutStatus =
//       "${BASE_URL}API_CheckInOutStatus.aspx";
//
//   static  String tourVoucherApprovalList =
//       "${BASE_URL}API_TourExpenseApprovalList.aspx";
//
//   static  String weeklyTourDetailsView =
//       "${BASE_URL}API_WeeklyDetailsView.aspx";
//
//   static  String insertWeeklyTourDetail =
//       "${BASE_URL}API_InsertWeeklyTourDetail.aspx";
//
//   static  String dealerCategoryList =
//       "${BASE_URL}API_TextListsForViewer.aspx";
//
//   static  String districtList =
//       "${BASE_URL}API_GetDistrictList.aspx";
//
//   static  String getAllowedTourWithoutPJC =
//       "${BASE_URL}API_GetAllowTourWithoutPJC.aspx";
//
//   static  String checkEntryValidation =
//       "${BASE_URL}API_CheckEntryValidation.aspx";
//
//   static  String tourExpenseView =
//       "${BASE_URL}API_TourExpenseView.aspx";
//
//   static  String getMonthList = "${BASE_URL}API_GetMonth.aspx";
//
//   static  String insertPortfolio = "${BASE_URL}API_InsertPortfolio.aspx";
//
//   static  String API_ViewPortfolio =
//       "${BASE_URL}API_ViewPortfolio.aspx";
//
//   static  String selectPortfolioDetails =
//       "${BASE_URL}API_SelectPortfolio.aspx";
//
//   static  String updatePortfolioDetails =
//       "${BASE_URL}API_UpdatePortfolio.aspx";
//
//   static  String FollowUps =
//       "${BASE_URL}API_FollowUps.aspx";
//
//   static  String InsertlatLong =
//       "${BASE_URL}API_InsertLatLong.aspx";
//
//   fetchTourVouchers(
//       {required String mobileNo,
//       required String fromDate,
//       required String toDate}) {}
//
//   updateTourVoucher(Map<String, dynamic> requestData) {}
// }

  //TODO : App - Ip and Mobile No
  //9106497803 or 9586404597 or 8128599638 or 9595989898 9687688010 or 9821728260 or 8000952603
  //103.113.32.126
  //http://103.113.32.126/DeltaAttendanceAPIWIPL/

  //TODO : Web Login Credential : admin 123123123
  //Approval Link:
  //http://103.113.32.126/DeltaiAttendanceWIPL/Admin/MobileUsers.aspx - old
  //http://103.113.32.126/DeltaiAttendanceWIPL/login.aspx - New
  //admin - wipl@delta123


 /// Singla Attendance credential
 //Web Credentials
// Web Link : http://103.168.19.137/DeltaiAttendance/login.aspx
// Admin - 123123123
//
// App Credentials
// Ip : 103.168.19.137
// Mobile No testing :  Delta NA	9106497803
//