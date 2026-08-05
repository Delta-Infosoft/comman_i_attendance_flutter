// Model for TravelBy API response
class TravelByResponse {
  final String status;
  final String message;
  final List<TravelByItem> result;

  TravelByResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory TravelByResponse.fromJson(Map<String, dynamic> json) {
    return TravelByResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => TravelByItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Model for individual travel option
class TravelByItem {
  final String textListId;
  final String group;
  final String text;
  final String insertedOn;
  final String lastUpdatedOn;
  final String insertedByUserId;
  final String lastUpdatedByUserId;
  final bool isGetInOutTime;

  TravelByItem({
    required this.textListId,
    required this.group,
    required this.text,
    required this.insertedOn,
    required this.lastUpdatedOn,
    required this.insertedByUserId,
    required this.lastUpdatedByUserId,
    required this.isGetInOutTime,
    required String id,
    required String value,
  });

  factory TravelByItem.fromJson(Map<String, dynamic> json) {
    return TravelByItem(
      textListId: json['TextListId'] ?? '',
      group: json['Group'] ?? '',
      text: json['Text'] ?? '',
      insertedOn: json['InsertedOn'] ?? '',
      lastUpdatedOn: json['LastUpdatedOn'] ?? '',
      insertedByUserId: json['InsertedByUserId'] ?? '',
      lastUpdatedByUserId: json['LastUpdatedByUserId'] ?? '',
      isGetInOutTime:
          (json['IsGetInOutTime'] as String).toLowerCase() == 'true',
      id: '',
      value: '',
    );
  }

  @override
  String toString() => text;
}

// Model for Back Dated Rights API response
class BackDatedRightsResponse {
  final String status;
  final String message;
  final List<BackDatedRights> result;

  BackDatedRightsResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory BackDatedRightsResponse.fromJson(Map<String, dynamic> json) {
    return BackDatedRightsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => BackDatedRights.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Model for individual back dated rights
class BackDatedRights {
  final int noOfDays;
  final int fromPJCDate;
  final int toPJCDate;

  BackDatedRights({
    required this.noOfDays,
    required this.fromPJCDate,
    required this.toPJCDate,
  });

  factory BackDatedRights.fromJson(Map<String, dynamic> json) {
    return BackDatedRights(
      noOfDays: int.tryParse(json['NoOfDays']?.toString() ?? '0') ?? 0,
      fromPJCDate: int.tryParse(json['FromPJCDate']?.toString() ?? '0') ?? 0,
      toPJCDate: int.tryParse(json['ToPJCDate']?.toString() ?? '0') ?? 0,
    );
  }
}

// Model for CheckEntryValidation API response
class CheckEntryValidationResponse {
  final String status;
  final String message;
  final List<DateValidation> result;

  CheckEntryValidationResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory CheckEntryValidationResponse.fromJson(Map<String, dynamic> json) {
    return CheckEntryValidationResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => DateValidation.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class DateValidation {
  final String calendarDate;
  final String empId;

  DateValidation({
    required this.calendarDate,
    required this.empId,
  });

  factory DateValidation.fromJson(Map<String, dynamic> json) {
    return DateValidation(
      calendarDate: json['CalendarDate']?.toString() ?? '',
      empId: json['EmpId']?.toString() ?? '',
    );
  }
}

// Model for GetAllowTourWithoutPJC API response
class AllowTourWithoutPJCResponse {
  final String status;
  final String message;
  final List<AllowTourDetails> result;

  AllowTourWithoutPJCResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory AllowTourWithoutPJCResponse.fromJson(Map<String, dynamic> json) {
    return AllowTourWithoutPJCResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => AllowTourDetails.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class AllowTourDetails {
  final String column1;
  final bool allowTourWithoutPJC;
  final bool allowPJC;

  AllowTourDetails({
    required this.column1,
    required this.allowTourWithoutPJC,
    required this.allowPJC,
  });

  factory AllowTourDetails.fromJson(Map<String, dynamic> json) {
    return AllowTourDetails(
      column1: json['Column1']?.toString() ?? '',
      allowTourWithoutPJC:
          (json['AllowTourWithoutPJC']?.toString().toLowerCase() == 'true'),
      allowPJC: (json['AllowPJC']?.toString().toLowerCase() == 'true'),
    );
  }
}

// API_UploadDocument response model
class UploadDocumentResponse {
  final String status;
  final String message;
  final UploadDocumentResult result;

  UploadDocumentResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory UploadDocumentResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocumentResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: UploadDocumentResult.fromJson(json['result'] ?? {}),
    );
  }
}

class UploadDocumentResult {
  final String id;

  UploadDocumentResult({
    required this.id,
  });

  factory UploadDocumentResult.fromJson(Map<String, dynamic> json) {
    return UploadDocumentResult(
      id: json['id'] ?? '',
    );
  }
}

// API_GetUploadedDocList response model
class UploadedDocListResponse {
  final String status;
  final String message;
  final List<UploadedDocument> result;

  UploadedDocListResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory UploadedDocListResponse.fromJson(Map<String, dynamic> json) {
    return UploadedDocListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => UploadedDocument.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class UploadedDocument {
  final String fuId;
  final String lnNo;
  final String recordId;
  final String formName;
  final String filePath;
  final String insertedOn;
  final String lastUpdatedOn;
  final String fileName;
  final String file1; // URL

  UploadedDocument({
    required this.fuId,
    required this.lnNo,
    required this.recordId,
    required this.formName,
    required this.filePath,
    required this.insertedOn,
    required this.lastUpdatedOn,
    required this.fileName,
    required this.file1,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      fuId: json['FUId'] ?? '',
      lnNo: json['LnNo'] ?? '',
      recordId: json['RecordId'] ?? '',
      formName: json['FormName'] ?? '',
      filePath: json['FilePath'] ?? '',
      insertedOn: json['InsertedOn'] ?? '',
      lastUpdatedOn: json['LastUpdatedOn'] ?? '',
      fileName: json['FileName'] ?? '',
      file1: json['File1'] ?? '',
    );
  }

  get id => null;
}

// API_InsertTourExpense request model
class InsertTourExpenseRequest {
  final String designation;
  final String toPlace;
  final String otherExpenses;
  final String endTime;
  final bool nightHault;
  final String expenseId;
  final String startTime;
  final String totalExpenses;
  final String lodging;
  final String autoChargesDetail;
  final String fareAmt;
  final String empMobileNo;
  final String otherChargesDetails;
  final String fromPlace;
  final String travellingBy;
  final String fromDate;
  final String toDate;
  final String departmentId;
  final String autoCharges;
  final String dailyAllowance;

  InsertTourExpenseRequest({
    required this.designation,
    required this.toPlace,
    required this.otherExpenses,
    required this.endTime,
    required this.nightHault,
    required this.expenseId,
    required this.startTime,
    required this.totalExpenses,
    required this.lodging,
    required this.autoChargesDetail,
    required this.fareAmt,
    required this.empMobileNo,
    required this.otherChargesDetails,
    required this.fromPlace,
    required this.travellingBy,
    required this.fromDate,
    required this.toDate,
    required this.departmentId,
    required this.autoCharges,
    required this.dailyAllowance,
  });

  Map<String, dynamic> toJson() {
    return {
      'Designation': designation,
      'ToPlace': toPlace,
      'OtherExpenses': otherExpenses,
      'EndTime': endTime,
      'NightHault': nightHault.toString().toLowerCase(),
      'ExpenseId': expenseId,
      'StartTime': startTime,
      'TotalExpenses': totalExpenses,
      'Lodging': lodging,
      'AutoChargesDetail': autoChargesDetail,
      'FareAmt': fareAmt,
      'EmpMobileNo': empMobileNo,
      'OtherChargesDetails': otherChargesDetails,
      'FromPlace': fromPlace,
      'TravellingBy': travellingBy,
      'FromDate': fromDate,
      'ToDate': toDate,
      'DepartmentId': departmentId,
      'AutoCharges': autoCharges,
      'DailyAllowance': dailyAllowance,
    };
  }
}

// API_InsertTourExpense response model
class InsertTourExpenseResponse {
  final String status;
  final String message;
  final InsertTourExpenseResult result;

  InsertTourExpenseResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory InsertTourExpenseResponse.fromJson(Map<String, dynamic> json) {
    return InsertTourExpenseResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: InsertTourExpenseResult.fromJson(json['result'] ?? {}),
    );
  }
}

class InsertTourExpenseResult {
  final String id;

  InsertTourExpenseResult({
    required this.id,
  });

  factory InsertTourExpenseResult.fromJson(Map<String, dynamic> json) {
    return InsertTourExpenseResult(
      id: json['id'] ?? '',
    );
  }
}
