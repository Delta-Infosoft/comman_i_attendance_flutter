import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/view/create_daily_tour_details_screen.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';
import 'package:waterman_iattandance/screens/webviews/common_web_view.dart';
import '../../../flavor_config.dart';
import 'package:waterman_iattandance/screens/tour_voucher/view/tour_voucher_screen.dart';
import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/tour_voucher_screen_controller.dart';
import 'package:waterman_iattandance/widget/document_preview_screen.dart';
import '../viewmodel/Insert_tour_voucher_controller.dart';
import '../model/Insert_tour_voucher_model.dart';

class CreateTourVoucherScreen extends StatefulWidget {
  final TourVoucherModel? voucherToEdit;
  final bool isEditMode;

  const CreateTourVoucherScreen({
    Key? key,
    this.voucherToEdit,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<CreateTourVoucherScreen> createState() =>
      _CreateTourVoucherScreenState();
}

class _CreateTourVoucherScreenState extends State<CreateTourVoucherScreen> {
  final TourScreenVoucherController _controller =
      Get.put(TourScreenVoucherController());
  final TourVoucherController _tourVoucherController =
      Get.find<TourVoucherController>();

  // Form controllers
  final TextEditingController fromDateCtrl = TextEditingController();
  final TextEditingController toDateCtrl = TextEditingController();
  final TextEditingController fromPlaceCtrl = TextEditingController();
  final TextEditingController toPlaceCtrl = TextEditingController();
  final TextEditingController startTimeCtrl = TextEditingController();
  final TextEditingController endTimeCtrl = TextEditingController();
  final TextEditingController fareCtrl = TextEditingController();
  final TextEditingController lodgingCtrl = TextEditingController();
  final TextEditingController foodCtrl = TextEditingController();
  final TextEditingController otherExpenseCtrl = TextEditingController();
  final TextEditingController extraDetailsCtrl = TextEditingController();
  final TextEditingController autoChargesCtrl = TextEditingController();
  final TextEditingController autoChargesDetailCtrl = TextEditingController();
  final TextEditingController travelByCtrl = TextEditingController();

  // State variables
  bool isNightHold = true;
  File? selectedFile;
  double totalExpense = 0;
  bool _isFormUnlocked = false;
  bool _isValidatingDates = false;
  bool _hasDatesSelected = false;
  bool? _pjcStatus;
  String _travelByValue = '';

  @override
  void initState() {
    super.initState();

    // Initialize form with voucher data if in edit mode
    if (widget.isEditMode && widget.voucherToEdit != null) {
      // Set edit mode and unlock form immediately
      _unlockFormFields();
      _initializeFormWithVoucherData();
    }

    _calculateTotal();
    _initializeListeners();

    // Only call GetNewIdAPI for new vouchers
    if (!widget.isEditMode) {
      _callGetNewIdAPI();
    } else {
      // In edit mode, fetch existing documents
      _fetchExistingDocumentsForEdit();
    }

    // Fetch back-dated rights
    _controller.getBackDatedRights();
  }

  void _initializeListeners() {
    fareCtrl.addListener(_calculateTotal);
    lodgingCtrl.addListener(_calculateTotal);
    foodCtrl.addListener(_calculateTotal);
    otherExpenseCtrl.addListener(_calculateTotal);
    autoChargesCtrl.addListener(_calculateTotal);
    fromDateCtrl.addListener(_checkDatesSelection);
    toDateCtrl.addListener(_checkDatesSelection);

    ever(_controller.allowPJC, (bool allowPJCStatus) {
      setState(() {
        _pjcStatus = allowPJCStatus;
      });

      if (allowPJCStatus == true) {
        _unlockFormFields();
      } else if (allowPJCStatus == false) {
        _lockFormFields();
      }
    });

    ever(_controller.uploadedDocuments, (List<UploadedDocument> documents) {
      if (documents.isNotEmpty) {
        print('Received ${documents.length} uploaded documents');
      }
    });
  }

  void _checkDatesSelection() {
    final bool bothDatesSelected =
        fromDateCtrl.text.isNotEmpty && toDateCtrl.text.isNotEmpty;
    if (bothDatesSelected != _hasDatesSelected) {
      setState(() {
        _hasDatesSelected = bothDatesSelected;
      });
    }
  }

  void _unlockFormFields() {
    setState(() {
      _isFormUnlocked = true;
    });
  }

  void _lockFormFields() {
    setState(() {
      _isFormUnlocked = false;
    });
  }

  @override
  void dispose() {
    fareCtrl.removeListener(_calculateTotal);
    lodgingCtrl.removeListener(_calculateTotal);
    foodCtrl.removeListener(_calculateTotal);
    otherExpenseCtrl.removeListener(_calculateTotal);
    autoChargesCtrl.removeListener(_calculateTotal);
    fromDateCtrl.removeListener(_checkDatesSelection);
    toDateCtrl.removeListener(_checkDatesSelection);
    travelByCtrl.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final double fare = double.tryParse(fareCtrl.text) ?? 0;
    final double lodging = double.tryParse(lodgingCtrl.text) ?? 0;
    final double food = double.tryParse(foodCtrl.text) ?? 0;
    final double other = double.tryParse(otherExpenseCtrl.text) ?? 0;
    final double autoCharges = double.tryParse(autoChargesCtrl.text) ?? 0;

    setState(() {
      totalExpense = fare + lodging + food + other + autoCharges;
    });
  }

  Future<void> _pickTime(TextEditingController controller) async {
    if (!_isFormUnlocked) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = DateFormat("hh:mm a").format(dt);
      setState(() {});
    }
  }

  Future<void> pickFile() async {
    if (!_isFormUnlocked) return;
    if (_controller.newPJCId.value.isEmpty && !widget.isEditMode) return;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          selectedFile = file;
        });
        await _uploadFile(file);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      final String userId = _getUserId();
      final String recordId = widget.isEditMode
          ? widget.voucherToEdit!.expenseId!
          : _controller.newPJCId.value;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final uploadedId = await _controller.uploadDocument(
        file: file,
        userId: userId,
        recordId: recordId,
      );

      Get.back();

      if (uploadedId != null) {
        print('Document uploaded successfully');
      } else {
        setState(() {
          selectedFile = null;
        });
      }
    } catch (e) {
      Get.back();
      print('Upload error: $e');
      setState(() {
        selectedFile = null;
      });
    }
  }

  String _getUserId() {
    return 'df2711c8-95ad-42b4-be08-735c7475cde9';
  }

  String _getLoggedInMobileNo() {
    return LocalDbController.to.mobileNo;
  }

  void _callGetNewIdAPI() async {
    print('Calling GetNewIdForPJC API...');
    await _controller.getNewIdForPJC();

    if (_controller.newPJCId.value.isNotEmpty) {
      print('Received New PJC ID: ${_controller.newPJCId.value}');
      if (_isFormUnlocked) {
        await _fetchExistingDocuments();
      }
    }
  }

  Future<void> _fetchExistingDocuments() async {
    final String recordId = widget.isEditMode
        ? (widget.voucherToEdit?.expenseId ?? '')
        : _controller.newPJCId.value;

    if (recordId.isEmpty) return;

    try {
      final String attachmentType = 'TravelVoucher';
      await _controller.getUploadedDocuments(
        attachmentType: attachmentType,
        recordId: recordId,
      );
    } catch (e) {
      print('Error fetching documents: $e');
    }
  }

  Future<void> _fetchExistingDocumentsForEdit() async {
    if (widget.voucherToEdit?.expenseId == null ||
        widget.voucherToEdit!.expenseId!.isEmpty) {
      return;
    }

    try {
      final String attachmentType = 'TravelVoucher';
      final String recordId = widget.voucherToEdit!.expenseId!;

      // Set the PJC ID first
      _controller.newPJCId.value = recordId;

      // Then fetch documents
      await _controller.getUploadedDocuments(
        attachmentType: attachmentType,
        recordId: recordId,
      );

      print('Fetched existing documents for edit mode');
    } catch (e) {
      print('Error fetching documents for edit mode: $e');
    }
  }

  Future<void> _pickDate(TextEditingController controller,
      {bool isFromDate = false}) async {
    setState(() {
      _isValidatingDates = true;
    });

    try {
      await _controller.getBackDatedRights();
      final DateTime? pickedDate = await _showDatePicker(controller);
      if (pickedDate == null) return;

      controller.text = DateFormat("dd-MMM-yyyy").format(pickedDate);
      setState(() {});

      // ── Attendance Status Check ──────────────────────────────────────────
      // Always check attendance for the picked date (From Date or To Date).
      final String dateToCheck = controller.text;
      final String mobileNo = _getLoggedInMobileNo();

      final bool isPresent = await _controller.checkAttendanceStatus(
        mobileNo: mobileNo,
        date: dateToCheck,
      );

      if (!isPresent) {
        // Lock the form – user is Absent for this date
        _lockFormFields();
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Attendance Alert'),
              content: const Text(
                'You are marked Absent for the selected date.\n'
                'Tour Voucher cannot be submitted on an Absent day.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return; // Skip PJC check when attendance is Absent
      }
      // ────────────────────────────────────────────────────────────────────

      if (fromDateCtrl.text.isNotEmpty && toDateCtrl.text.isNotEmpty) {
        await _validateDatesAndCheckPJC();
      }
    } finally {
      setState(() {
        _isValidatingDates = false;
      });
    }
  }

  Future<DateTime?> _showDatePicker(TextEditingController controller) async {
    DateTime initialDate = _getInitialDate(controller);
    final DateTimeRange allowedRange = _getAllowedDateRange();

    if (initialDate.isBefore(allowedRange.start)) {
      initialDate = allowedRange.start;
    } else if (initialDate.isAfter(allowedRange.end)) {
      initialDate = allowedRange.end;
    }

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: allowedRange.start,
      lastDate: allowedRange.end,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: FlavorConfig.instance.primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
  }

  DateTime _getInitialDate(TextEditingController controller) {
    if (controller.text.isEmpty) return DateTime.now();
    try {
      return DateFormat("dd-MMM-yyyy").parse(controller.text);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTimeRange _getAllowedDateRange() {
    final DateTime today = DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);

    int allowedDays = _controller.noOfDays.value;
    if (allowedDays < 0) allowedDays = 0;

    // minDate is today minus allowedDays
    final DateTime minDate = startOfToday.subtract(Duration(days: allowedDays));

    // maxDate is today (no future dates allowed)
    final DateTime maxDate = today;

    return DateTimeRange(start: minDate, end: maxDate);
  }

  Future<void> _validateDatesAndCheckPJC() async {
    if (!_areDatesValid()) return;
    await _performPJCCheck();
  }

  bool _areDatesValid() {
    try {
      final DateTime fromDate =
          DateFormat("dd-MMM-yyyy").parse(fromDateCtrl.text);
      final DateTime toDate = DateFormat("dd-MMM-yyyy").parse(toDateCtrl.text);

      if (toDate.isBefore(fromDate)) {
        AppSnackBar.error('Error', 'To Date cannot be before From Date');
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _performPJCCheck() async {
    final bool isValid = await _controller.checkTourValidation(
      mobileNo: _getLoggedInMobileNo(),
      fromDate: fromDateCtrl.text,
      toDate: toDateCtrl.text,
    );

    if (isValid) {
      print('PJC validation passed');
      await _fetchExistingDocuments();
    }
  }

  void _initializeFormWithVoucherData() {
    if (widget.voucherToEdit == null) return;

    final voucher = widget.voucherToEdit!;

    try {
      // Parse and set dates
      if (voucher.travelDt != null && voucher.travelDt!.isNotEmpty) {
        final fromDate = _parseApiDate(voucher.travelDt!);
        if (fromDate != null) {
          fromDateCtrl.text = DateFormat("dd-MMM-yyyy").format(fromDate);
        }
      }

      if (voucher.travelToDt != null && voucher.travelToDt!.isNotEmpty) {
        final toDate = _parseApiDate(voucher.travelToDt!);
        if (toDate != null) {
          toDateCtrl.text = DateFormat("dd-MMM-yyyy").format(toDate);
        }
      } else if (voucher.travelDt != null && voucher.travelDt!.isNotEmpty) {
        // Use travelDt as fallback for toDate
        final toDate = _parseApiDate(voucher.travelDt!);
        if (toDate != null) {
          toDateCtrl.text = DateFormat("dd-MMM-yyyy").format(toDate);
        }
      }

      // Set other fields
      fromPlaceCtrl.text = voucher.fromPlace ?? '';
      toPlaceCtrl.text = voucher.toPlace ?? '';

      // Parse and set times
      if (voucher.startTime != null && voucher.startTime!.isNotEmpty) {
        final parsedTime = _parseApiTimeForForm(voucher.startTime!);
        if (parsedTime != null) {
          startTimeCtrl.text = parsedTime;
        }
      }

      if (voucher.endTime != null && voucher.endTime!.isNotEmpty) {
        final parsedTime = _parseApiTimeForForm(voucher.endTime!);
        if (parsedTime != null) {
          endTimeCtrl.text = parsedTime;
        }
      }

      // Set expense fields
      fareCtrl.text = voucher.fareAmount ?? '0';
      lodgingCtrl.text = voucher.lodging ?? '0';
      foodCtrl.text = voucher.dailyAllowance ?? '0';
      otherExpenseCtrl.text = voucher.otherExpenses ?? '0';
      extraDetailsCtrl.text = voucher.otherChargesDetail ?? '';
      autoChargesCtrl.text = voucher.autoCharges ?? '0';
      autoChargesDetailCtrl.text = voucher.autoChargesDetail ?? '';
      isNightHold = voucher.nighHault == 'True';

      // Set travel by option
      if (voucher.travellingBy != null && voucher.travellingBy!.isNotEmpty) {
        _travelByValue = voucher.travellingBy!;
        travelByCtrl.text = voucher.travellingBy!;
      }

      // Set PJC ID if available
      if (voucher.expenseId != null && voucher.expenseId!.isNotEmpty) {
        _controller.newPJCId.value = voucher.expenseId!;
      }

      // Force PJC status to true for edit mode
      _controller.allowPJC.value = true;
      _pjcStatus = true;

      print('Form initialized with voucher data for editing');
      print('Expense ID: ${voucher.expenseId}');
      print('Total Expenses: ${voucher.totalExpenses}');
    } catch (e) {
      print('Error initializing form with voucher data: $e');
    }
  }

  DateTime? _parseApiDate(String dateString) {
    try {
      // Handle formats like "18-Nov-2025 00:00:00"
      if (dateString.contains(' ')) {
        dateString = dateString.split(' ')[0];
      }
      return DateFormat("dd-MMM-yyyy").parse(dateString);
    } catch (e) {
      print('Error parsing date "$dateString": $e');
      return null;
    }
  }

  String? _parseApiTimeForForm(String timeString) {
    try {
      // Handle formats like "18-Nov-2025 11:33:00"
      if (timeString.contains(' ')) {
        final parts = timeString.split(' ');
        if (parts.length >= 2) {
          final timePart = parts[1];
          final timeComponents = timePart.split(':');
          if (timeComponents.length >= 2) {
            final hour = int.parse(timeComponents[0]);
            final minute = timeComponents[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
          }
        }
      }
      return null;
    } catch (e) {
      print('Error parsing time "$timeString": $e');
      return null;
    }
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isFormUnlocked ? pickFile : null,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _isFormUnlocked ? FlavorConfig.instance.primaryColor : Colors.grey.shade300,
                  width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isFormUnlocked
                        ? FlavorConfig.instance.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        if (_controller.isUploadingDocument.value) {
                          return SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: FlavorConfig.instance.primaryColor),
                          );
                        }
                        return Icon(Icons.attach_file,
                            color: _isFormUnlocked
                                ? FlavorConfig.instance.primaryColor
                                : Colors.grey.shade400);
                      }),
                      const SizedBox(width: 8),
                      Obx(() => Text(
                            _controller.isUploadingDocument.value
                                ? "Uploading..."
                                : "Attach Document",
                            style: TextStyle(
                                color: _isFormUnlocked
                                    ? FlavorConfig.instance.primaryColor
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w500),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (_controller.isLoadingDocuments.value) {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text("Loading documents...",
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ],
                    );
                  }

                  if (_controller.uploadedDocuments.isNotEmpty) {
                    return Column(
                      children: [
                        Text(
                          "${_controller.uploadedDocuments.length} Document(s) Uploaded",
                          style: TextStyle(
                              color: _isFormUnlocked
                                  ? Colors.green
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }

                  return Text(
                    "Upload Attached Photo/Document/File",
                    style: TextStyle(
                        color:
                            _isFormUnlocked ? FlavorConfig.instance.primaryColor : Colors.grey.shade400,
                        fontWeight: FontWeight.w600),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => _buildUploadedDocumentsList()),
      ],
    );
  }

  Widget _buildUploadedDocumentsList() {
    if (_controller.uploadedDocuments.isEmpty) return Container();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text("Uploaded Documents",
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const Spacer(),
                Text("(${_controller.uploadedDocuments.length})",
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ..._controller.uploadedDocuments.map((doc) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade100),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(doc.fileName),
                      color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.fileName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text("Uploaded: ${doc.insertedOn}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue.shade700),
                    onPressed: () =>
                        Get.to(() => DocumentPreviewScreen(document: doc)),
                  ),
                  IconButton(
                      onPressed: () async {
                        // Show confirmation dialog before deleting
                        final bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Document'),
                            content: Text(
                              'Are you sure you want to delete "${doc.fileName}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final String recordId = widget.isEditMode
                              ? (widget.voucherToEdit?.expenseId ?? '')
                              : _controller.newPJCId.value;

                          await _controller.deleteDocument(
                            recordId: recordId,
                            fuId: doc.fuId,
                            attachmentType: '',
                          );
                        }
                      },
                      icon: Icon(Icons.delete, color: Colors.red.shade700))
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension))
      return Icons.image;
    if (['pdf'].contains(extension)) return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  bool _isImageFile(String path) {
    return path.endsWith(".jpg") ||
        path.endsWith(".png") ||
        path.endsWith(".jpeg");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        title: Text(
          widget.isEditMode ? "Edit Tour Voucher" : "Create Tour Voucher",
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
        leading: FlavorConfig.instance.getAppBarLeading(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // In edit mode, show edit banner
            if (widget.isEditMode) _buildEditModeBanner(),

            if (!widget.isEditMode) _buildPJCStatusIndicator(),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _buildFormContent(),
              ),
            ),
            const SizedBox(height: 20),
            SafeArea(
              maintainBottomViewPadding: true,
                child: _buildSubmitButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editing existing tour voucher',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPJCStatusIndicator() {
    if (_pjcStatus == null) {
      if (_hasDatesSelected) return _buildValidationInProgressBanner();
      return _buildInstructionsBanner();
    }
    if (_pjcStatus == true) return _buildSuccessBanner();
    if (_pjcStatus == false) return _buildWarningBanner();
    return Container();
  }

  Widget _buildInstructionsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Please select both From Date and To Date to check PJC status',
                  style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildValidationInProgressBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Checking PJC and DTD status...',
                  style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Validation Complete! PJC & DTD are filled.',
                  style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Please complete PJC and Daily Tour Details first',
                  style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500))),
          TextButton(
            onPressed: () => Get.off(() => CreateEditTourScreen()),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            child: Text('Complete Now',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        _buildDateSection(),
        const SizedBox(height: 16),
        AbsorbPointer(
          absorbing: !_isFormUnlocked,
          child: Opacity(
            opacity: _isFormUnlocked ? 1.0 : 0.6,
            child: _buildOtherFields(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return _rowFields(
      _buildDateField(Icons.calendar_today, "from date *", fromDateCtrl),
      _buildDateField(Icons.calendar_today, "to date *", toDateCtrl),
    );
  }

  Widget _buildDateField(
      IconData icon, String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _pickDate(controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black87),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.black54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherFields() {
    return Column(
      children: [
        _buildInputField(Icons.location_on, "from place *", fromPlaceCtrl),
        const SizedBox(height: 10),
        _buildInputField(Icons.location_on, "to place *", toPlaceCtrl),
        const SizedBox(height: 10),
        _rowFields(
          _buildTimeField(Icons.access_time, "start time *", startTimeCtrl),
          _buildTimeField(Icons.access_time, "end time *", endTimeCtrl),
        ),
        const SizedBox(height: 10),
        _buildNightHoldSwitch(),
        const SizedBox(height: 10),
        FlavorConfig.instance.isSingla
            ? _buildInputField(Icons.directions_bus, "travelling by *", travelByCtrl)
            : _buildTravelByDropdown(),
        const SizedBox(height: 10),
        _buildExpenseField(Icons.attach_money, "fare amount *", fareCtrl),
        const SizedBox(height: 10),
        _buildExpenseField(Icons.hotel, "lodging", lodgingCtrl),
        const SizedBox(height: 10),
        _buildExpenseField(Icons.restaurant, "food allowance", foodCtrl),
        const SizedBox(height: 10),
        _buildExpenseField(
            Icons.currency_rupee, "other expense", otherExpenseCtrl),
        const SizedBox(height: 10),
        _buildInputField(
            Icons.description, "extra expense details", extraDetailsCtrl),
        const SizedBox(height: 10),
        _buildExpenseField(Icons.local_taxi, "auto charges", autoChargesCtrl),
        const SizedBox(height: 10),
        _buildInputField(Icons.note, "auto charges details", autoChargesDetailCtrl),
        const SizedBox(height: 10),
        _buildTotalExpense(),
        const SizedBox(height: 16),
        _buildUploadSection(),
      ],
    );
  }

  Widget _buildTimeField(
      IconData icon, String label, TextEditingController controller) {
    return GestureDetector(
      onTap: _isFormUnlocked ? () => _pickTime(controller) : null,
      child: AbsorbPointer(child: _buildInputField(icon, label, controller)),
    );
  }

  Widget _buildNightHoldSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.nightlight_round,
              color: _isFormUnlocked ? Colors.black54 : Colors.grey.shade400),
          const SizedBox(width: 10),
          Text("night hold",
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      _isFormUnlocked ? Colors.black87 : Colors.grey.shade600)),
          const Spacer(),
          GestureDetector(
            onTap: _isFormUnlocked
                ? () => setState(() => isNightHold = !isNightHold)
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: !_isFormUnlocked
                    ? Colors.grey.shade300
                    : (isNightHold ? FlavorConfig.instance.primaryColor : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(isNightHold ? "Yes" : "No",
                  style: TextStyle(
                      color: _isFormUnlocked
                          ? Colors.white
                          : Colors.grey.shade600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelByDropdown() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8)),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Loading travel options...'),
              ],
            ),
          ),
        );
      }

      // Find the matching travel option
      TravelByItem? selectedItem;
      if (_travelByValue.isNotEmpty && _controller.travelOptions.isNotEmpty) {
        selectedItem = _controller.travelOptions.firstWhere(
          (item) => item.text == _travelByValue,
          orElse: () => TravelByItem(
              text: _travelByValue,
              value: _travelByValue,
              textListId: '',
              group: '',
              insertedOn: '',
              lastUpdatedOn: '',
              insertedByUserId: '',
              lastUpdatedByUserId: '',
              isGetInOutTime: true,
              id: ''),
        );
      }

      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color:
                  _isFormUnlocked ? Colors.grey.shade400 : Colors.grey.shade300,
              width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.directions_bus,
                    color: _isFormUnlocked
                        ? Colors.black54
                        : Colors.grey.shade400)),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TravelByItem>(
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  hint: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('travelling by *',
                          style: TextStyle(
                              color: _isFormUnlocked
                                  ? Colors.grey
                                  : Colors.grey.shade400))),
                  value: selectedItem ?? _controller.selectedTravelOption.value,
                  onChanged: _isFormUnlocked
                      ? (TravelByItem? value) {
                          _controller.setSelectedTravelOption(value);
                          if (value != null) {
                            _travelByValue = value.text;
                          }
                        }
                      : null,
                  items: _controller.travelOptions.map((TravelByItem item) {
                    return DropdownMenuItem<TravelByItem>(
                      value: item,
                      child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(item.text,
                              style: TextStyle(
                                  color: _isFormUnlocked
                                      ? Colors.black87
                                      : Colors.grey.shade600))),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildExpenseField(
      IconData icon, String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: _isFormUnlocked,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
          color: _isFormUnlocked ? Colors.black87 : Colors.grey.shade600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon,
            color: _isFormUnlocked ? Colors.black54 : Colors.grey.shade400),
        hintText: label,
        hintStyle: TextStyle(
            fontSize: 14,
            color: _isFormUnlocked ? Colors.grey : Colors.grey.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _isFormUnlocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
                width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _isFormUnlocked ? FlavorConfig.instance.primaryColor : Colors.grey.shade300,
                width: 1.5)),
        prefixText: '₹ ',
        prefixStyle: TextStyle(
            fontSize: 16,
            color: _isFormUnlocked ? Colors.black87 : Colors.grey.shade600,
            fontWeight: FontWeight.w500),
        filled: true,
        fillColor: _isFormUnlocked ? Colors.white : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      onChanged: (value) => _calculateTotal(),
    );
  }

  Widget _buildInputField(
      IconData icon, String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: _isFormUnlocked,
      style: TextStyle(
          color: _isFormUnlocked ? Colors.black87 : Colors.grey.shade600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon,
            color: _isFormUnlocked ? Colors.black54 : Colors.grey.shade400),
        hintText: label,
        hintStyle: TextStyle(
            fontSize: 14,
            color: _isFormUnlocked ? Colors.grey : Colors.grey.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _isFormUnlocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
                width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _isFormUnlocked ? FlavorConfig.instance.primaryColor : Colors.grey.shade300,
                width: 1.5)),
        filled: true,
        fillColor: _isFormUnlocked ? Colors.white : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildTotalExpense() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Total expense :",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color:
                      _isFormUnlocked ? Colors.black87 : Colors.grey.shade600)),
          Text("₹ ${totalExpense.toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isFormUnlocked
                      ? Colors.green.shade700
                      : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isFormUnlocked ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormUnlocked ? FlavorConfig.instance.primaryColor : Colors.grey.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Obx(() {
          if (_controller.isSubmittingForm.value) {
            return const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white));
          }
          return Text(
            widget.isEditMode ? "Update Tour Expense" : "Submit Tour Expense",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          );
        }),
      ),
    );
  }

  void _submitForm() async {
    if (!_isFormUnlocked) return;

    final List<String> errors = _validateRequiredFields();
    if (errors.isNotEmpty) {
      CustomSnackBar.show(
        message: "Please fill required fields:\n${errors.join(', ')}",
        isError: true,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // For edit mode, we need the existing expense ID
    if (widget.isEditMode) {
      if (widget.voucherToEdit?.expenseId == null ||
          widget.voucherToEdit!.expenseId!.isEmpty) {
        CustomSnackBar.show(
          message: "Cannot update: Missing expense ID",
          isError: true,
        );
        return;
      }
      _controller.newPJCId.value = widget.voucherToEdit!.expenseId!;
    } else {
      // For new vouchers, get new PJC ID
      if (_controller.newPJCId.value.isEmpty) {
        await _controller.getNewIdForPJC();
      }
      if (_controller.newPJCId.value.isEmpty) return;
    }

    print(
        'Starting form ${widget.isEditMode ? 'update' : 'submission'} process...');
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    try {
      if (widget.isEditMode) {
        await _callUpdateTourExpenseAPI();
      } else {
        await _callInsertTourExpenseAPI();
      }
    } catch (e) {
      Get.back();
      print('Form ${widget.isEditMode ? 'update' : 'submission'} error: $e');
    }
  }

  Future<void> _callUpdateTourExpenseAPI() async {
    try {
      print('Preparing API request data for update...');
      final String empMobileNo = _getLoggedInMobileNo();
      final String travellingBy = FlavorConfig.instance.isSingla
          ? travelByCtrl.text.trim()
          : (_controller.selectedTravelOption.value?.text ?? _travelByValue);

      // Create updated voucher model for the update API
      final updatedVoucher = TourVoucherModel(
        expenseId: widget.voucherToEdit!.expenseId,
        fromPlace: fromPlaceCtrl.text,
        toPlace: toPlaceCtrl.text,
        travellingBy: travellingBy,
        fareAmount: fareCtrl.text,
        lodging: lodgingCtrl.text.isEmpty ? '0' : lodgingCtrl.text,
        dailyAllowance: foodCtrl.text.isEmpty ? '0' : foodCtrl.text,
        otherExpenses:
            otherExpenseCtrl.text.isEmpty ? '0' : otherExpenseCtrl.text,
        autoCharges: autoChargesCtrl.text.isEmpty ? '0' : autoChargesCtrl.text,
        autoChargesDetail: autoChargesDetailCtrl.text,
        otherChargesDetail: extraDetailsCtrl.text,
        totalExpenses: totalExpense.toStringAsFixed(2),
        nighHault: isNightHold ? 'True' : 'False',
        // Keep original dates and times from the voucher being edited
        travelDt: widget.voucherToEdit!.travelDt,
        travelToDt: widget.voucherToEdit!.travelToDt,
        startTime: widget.voucherToEdit!.startTime,
        endTime: widget.voucherToEdit!.endTime,
        // Keep other original data
        name: widget.voucherToEdit!.name,
        designation: widget.voucherToEdit!.designation,
        status: widget.voucherToEdit!.status,
        tourReport: widget.voucherToEdit!.tourReport,
      );

      // Call update API through TourVoucherController
      final tourVoucherController = Get.find<TourVoucherController>();
      final success =
          await tourVoucherController.updateTourVoucher(updatedVoucher);

      Get.back(); // loader close

      if (success) {
        CustomSnackBar.show(
          message: "Tour voucher updated successfully",
        );

        // Navigate back to TourVoucherScreen
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAll(() => const TourVoucherScreen());
        });
      } else {
        CustomSnackBar.show(
          message: "Failed to update voucher. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      Get.back(); // loader close

      CustomSnackBar.show(
        message: "Something went wrong. Please try again later.",
        isError: true,
      );
    }
  }

  Future<void> _callInsertTourExpenseAPI() async {
    try {
      print('Preparing API request data...');
      final String empMobileNo = _getLoggedInMobileNo();
      final String travellingBy = FlavorConfig.instance.isSingla
          ? travelByCtrl.text.trim()
          : (_controller.selectedTravelOption.value?.text ?? '');

      final request = InsertTourExpenseRequest(
        designation: '',
        toPlace: toPlaceCtrl.text,
        otherExpenses:
            otherExpenseCtrl.text.isEmpty ? '0' : otherExpenseCtrl.text,
        endTime: endTimeCtrl.text,
        nightHault: isNightHold,
        expenseId: _controller.newPJCId.value,
        startTime: startTimeCtrl.text,
        totalExpenses: totalExpense.toString(),
        lodging: lodgingCtrl.text.isEmpty ? '0' : lodgingCtrl.text,
        autoChargesDetail: autoChargesDetailCtrl.text,
        fareAmt: fareCtrl.text,
        empMobileNo: empMobileNo,
        otherChargesDetails: extraDetailsCtrl.text,
        fromPlace: fromPlaceCtrl.text,
        travellingBy: travellingBy,
        fromDate: fromDateCtrl.text,
        toDate: toDateCtrl.text,
        departmentId: '',
        autoCharges: autoChargesCtrl.text.isEmpty ? '0' : autoChargesCtrl.text,
        dailyAllowance: foodCtrl.text.isEmpty ? '0' : foodCtrl.text,
      );

      final response = await _controller.insertTourExpense(request: request);
      Get.back(); // loader close

      // ✅ SUCCESS
      if (response != null && response.status == '200') {
        CustomSnackBar.show(
          message: "Tour voucher added successfully",
        );

        // 👉 Navigate to TourVoucherScreen
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAll(() => const TourVoucherScreen());
        });

        _printReceipt(response);
      }

      // ❌ API FAILED
      else {
        CustomSnackBar.show(
          message: "Something went wrong. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      Get.back(); // loader close

      // ❌ EXCEPTION
      CustomSnackBar.show(
        message: "Something went wrong. Please try again later.",
        isError: true,
      );
    }
  }

  void _printReceipt(InsertTourExpenseResponse response) {
    print('TOUR EXPENSE RECEIPT');
    print('========================================');
    print('Tour ID: ${response.result.id}');
    print('Date: ${DateTime.now()}');
    print('----------------------------------------');
    print('From Date: ${fromDateCtrl.text}');
    print('To Date: ${toDateCtrl.text}');
    print('From Place: ${fromPlaceCtrl.text}');
    print('To Place: ${toPlaceCtrl.text}');
    print('Travel By: ${FlavorConfig.instance.isSingla ? travelByCtrl.text : _controller.selectedTravelOption.value?.text}');
    print('----------------------------------------');
    print('EXPENSE BREAKDOWN:');
    print('  Fare Amount: ₹${fareCtrl.text}');
    print('  Lodging: ₹${lodgingCtrl.text.isEmpty ? "0" : lodgingCtrl.text}');
    print('  Food Allowance: ₹${foodCtrl.text.isEmpty ? "0" : foodCtrl.text}');
    print(
        '  Other Expenses: ₹${otherExpenseCtrl.text.isEmpty ? "0" : otherExpenseCtrl.text}');
    print('----------------------------------------');
    print('TOTAL EXPENSE: ₹$totalExpense');
    print('========================================');
    print('Submitted by: ${_getLoggedInMobileNo()}');
    print('Documents: ${_controller.uploadedDocuments.length} files');
  }

  List<String> _validateRequiredFields() {
    final List<String> errors = [];

    if (fromDateCtrl.text.isEmpty) errors.add('From Date');
    if (toDateCtrl.text.isEmpty) errors.add('To Date');
    if (fromPlaceCtrl.text.isEmpty) errors.add('From Place');
    if (toPlaceCtrl.text.isEmpty) errors.add('To Place');
    if (startTimeCtrl.text.isEmpty) errors.add('Start Time');
    if (endTimeCtrl.text.isEmpty) errors.add('End Time');
    if (FlavorConfig.instance.isSingla) {
      if (travelByCtrl.text.trim().isEmpty) errors.add('Travelling By');
    } else {
      if (_controller.selectedTravelOption.value == null &&
          _travelByValue.isEmpty) errors.add('Travelling By');
    }
    if (fareCtrl.text.isEmpty) errors.add('Fare Amount');

    if (fareCtrl.text.isNotEmpty) {
      final fare = double.tryParse(fareCtrl.text);
      if (fare == null || fare <= 0) errors.add('Valid Fare Amount');
    }

    if (totalExpense <= 0) errors.add('Total Expense must be greater than 0');

    print('Validation errors: ${errors.length} errors');
    if (errors.isNotEmpty) print('Errors: $errors');

    return errors;
  }

  Widget _rowFields(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}
