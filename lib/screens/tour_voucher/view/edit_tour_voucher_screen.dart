import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';
import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/Insert_tour_voucher_controller.dart';
import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/tour_voucher_screen_controller.dart';
import 'package:waterman_iattandance/widget/document_preview_screen.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../flavor_config.dart';

class EditTourVoucherScreen extends StatefulWidget {
  final TourVoucherModel voucher;

  const EditTourVoucherScreen({super.key, required this.voucher});

  @override
  State<EditTourVoucherScreen> createState() => _EditTourVoucherScreenState();
}

class _EditTourVoucherScreenState extends State<EditTourVoucherScreen> {
  final TourVoucherController _controller = Get.find<TourVoucherController>();
  final TourScreenVoucherController _insertController = Get.put(TourScreenVoucherController());
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late TextEditingController _fromPlaceController;
  late TextEditingController _toPlaceController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _fareAmountController;
  late TextEditingController _lodgingController;
  late TextEditingController _dailyAllowanceController;
  late TextEditingController _otherExpensesController;
  late TextEditingController _extraDetailsController;
  late TextEditingController _autoChargesController;
  late TextEditingController _autoChargesDetailController;

  // State variables
  late bool _nightHault;
  double _totalExpenses = 0;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with voucher data
    _initializeFormWithVoucherData();

    _calculateTotal();

    // Listen for changes to recalculate total
    _fareAmountController.addListener(_calculateTotal);
    _lodgingController.addListener(_calculateTotal);
    _dailyAllowanceController.addListener(_calculateTotal);
    _otherExpensesController.addListener(_calculateTotal);
    _autoChargesController.addListener(_calculateTotal);

    // Fetch existing documents for the voucher being edited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.voucher.expenseId != null && widget.voucher.expenseId!.isNotEmpty) {
        _insertController.getUploadedDocuments(
          recordId: widget.voucher.expenseId!,
          attachmentType: 'TravelVoucher',
        );
      }
    });
  }

  void _initializeFormWithVoucherData() {
    final voucher = widget.voucher;

    // Parse and set dates
    _fromDateController =
        TextEditingController(text: _parseApiDateForForm(voucher.travelDt));
    _toDateController = TextEditingController(
        text: _parseApiDateForForm(voucher.travelToDt ?? voucher.travelDt));

    // Set other fields
    _fromPlaceController = TextEditingController(text: voucher.fromPlace);
    _toPlaceController = TextEditingController(text: voucher.toPlace);

    // Parse and set times
    _startTimeController =
        TextEditingController(text: _parseApiTimeForForm(voucher.startTime));
    _endTimeController =
        TextEditingController(text: _parseApiTimeForForm(voucher.endTime));

    // Set expense fields
    _fareAmountController = TextEditingController(text: voucher.fareAmount);
    _lodgingController = TextEditingController(text: voucher.lodging ?? '0');
    _dailyAllowanceController =
        TextEditingController(text: voucher.dailyAllowance ?? '0');
    _otherExpensesController =
        TextEditingController(text: voucher.otherExpenses ?? '0');
    _extraDetailsController =
        TextEditingController(text: voucher.otherChargesDetail ?? '');
    _autoChargesController =
        TextEditingController(text: voucher.autoCharges ?? '0');
    _autoChargesDetailController =
        TextEditingController(text: voucher.autoChargesDetail ?? '');

    _nightHault = voucher.nighHault == 'True';
  }

  String _parseApiDateForForm(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      // Handle formats like "18-Nov-2025 00:00:00"
      if (dateString.contains(' ')) {
        dateString = dateString.split(' ')[0];
      }
      return dateString; // Already in dd-MMM-yyyy format
    } catch (e) {
      print('Error parsing date "$dateString": $e');
      return '';
    }
  }

  String _parseApiTimeForForm(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';

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
      return timeString;
    } catch (e) {
      print('Error parsing time "$timeString": $e');
      return timeString ?? '';
    }
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _fromPlaceController.dispose();
    _toPlaceController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _fareAmountController.dispose();
    _lodgingController.dispose();
    _dailyAllowanceController.dispose();
    _otherExpensesController.dispose();
    _extraDetailsController.dispose();
    _autoChargesController.dispose();
    _autoChargesDetailController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double fare = double.tryParse(_fareAmountController.text) ?? 0;
    double lodging = double.tryParse(_lodgingController.text) ?? 0;
    double allowance = double.tryParse(_dailyAllowanceController.text) ?? 0;
    double other = double.tryParse(_otherExpensesController.text) ?? 0;
    double autoCharges = double.tryParse(_autoChargesController.text) ?? 0;

    setState(() {
      _totalExpenses = fare + lodging + allowance + other + autoCharges;
    });
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = _formatTime(dt);
      setState(() {});
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

    if (pickedDate != null) {
      controller.text = _formatDate(pickedDate);
      setState(() {});
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${_getMonthAbbreviation(date.month)}-${date.year}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      final List<String> errors = _validateRequiredFields();
      if (errors.isNotEmpty) {
        CustomSnackBar.show(
          message: "Please fill required fields:\n${errors.join(', ')}",
          isError: true,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Update the voucher with new values
      _controller.updateSelectedVoucherField(
          'fromPlace', _fromPlaceController.text);
      _controller.updateSelectedVoucherField(
          'toPlace', _toPlaceController.text);
      _controller.updateSelectedVoucherField(
          'travellingBy', widget.voucher.travellingBy); // Keep original
      _controller.updateSelectedVoucherField(
          'fareAmount', _fareAmountController.text);
      _controller.updateSelectedVoucherField('lodging',
          _lodgingController.text.isEmpty ? '0' : _lodgingController.text);
      _controller.updateSelectedVoucherField(
          'dailyAllowance',
          _dailyAllowanceController.text.isEmpty
              ? '0'
              : _dailyAllowanceController.text);
      _controller.updateSelectedVoucherField(
          'otherExpenses',
          _otherExpensesController.text.isEmpty
              ? '0'
              : _otherExpensesController.text);
      _controller.updateSelectedVoucherField('autoCharges',
          _autoChargesController.text.isEmpty ? '0' : _autoChargesController.text);
      _controller.updateSelectedVoucherField(
          'autoChargesDetail', _autoChargesDetailController.text);
      _controller.updateSelectedVoucherField(
          'otherChargesDetail', _extraDetailsController.text);
      _controller.updateSelectedVoucherField(
          'totalExpenses', _totalExpenses.toStringAsFixed(2));
      _controller.updateSelectedVoucherField(
          'nighHault', _nightHault ? 'True' : 'False');

      // Get the updated voucher
      final updatedVoucher = _controller.selectedVoucher.value!;

      // Call update API
      final success = await _controller.updateTourVoucher(updatedVoucher);

      if (success) {
        Get.back(); // Close edit screen
        CustomSnackBar.show(
          message: 'Tour voucher updated successfully!',
        );
      } else {
        CustomSnackBar.show(
          message: _controller.updateMessage.value,
          isError: true,
        );
      }
    }
  }

  List<String> _validateRequiredFields() {
    final List<String> errors = [];

    if (_fromDateController.text.isEmpty) errors.add('From Date');
    if (_toDateController.text.isEmpty) errors.add('To Date');
    if (_fromPlaceController.text.isEmpty) errors.add('From Place');
    if (_toPlaceController.text.isEmpty) errors.add('To Place');
    if (_startTimeController.text.isEmpty) errors.add('Start Time');
    if (_endTimeController.text.isEmpty) errors.add('End Time');
    if (_fareAmountController.text.isEmpty) errors.add('Fare Amount');

    if (_fareAmountController.text.isNotEmpty) {
      final fare = double.tryParse(_fareAmountController.text);
      if (fare == null || fare <= 0) errors.add('Valid Fare Amount');
    }

    if (_totalExpenses <= 0) errors.add('Total Expense must be greater than 0');

    return errors;
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    bool isDateField = false,
    bool isTimeField = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isDateField
            ? () => _pickDate(controller)
            : isTimeField
                ? () => _pickTime(controller)
                : null,
        child: AbsorbPointer(
          absorbing: isDateField || isTimeField,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon:
                  icon != null ? Icon(icon, color: Colors.black54) : null,
              labelText: label + (isRequired ? ' *' : ''),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FlavorConfig.instance.primaryColor, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.black54) : null,
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: FlavorConfig.instance.primaryColor, width: 1.5),
          ),
          prefixText: '₹ ',
          prefixStyle: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildRowFields(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: Text(
          'Edit Tour Voucher',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        if (_controller.isUpdating.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(FlavorConfig.instance.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text('Updating voucher...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Section
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Dates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                  ),
                ),
                _buildRowFields(
                  _buildTextField(
                    label: 'From Date',
                    controller: _fromDateController,
                    isRequired: true,
                    isDateField: true,
                    icon: Icons.calendar_today,
                  ),
                  _buildTextField(
                    label: 'To Date',
                    controller: _toDateController,
                    isRequired: true,
                    isDateField: true,
                    icon: Icons.calendar_today,
                  ),
                ),

                // Basic Information
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                  ),
                ),
                _buildTextField(
                  label: 'From Place',
                  controller: _fromPlaceController,
                  isRequired: true,
                  icon: Icons.location_on,
                ),
                _buildTextField(
                  label: 'To Place',
                  controller: _toPlaceController,
                  isRequired: true,
                  icon: Icons.location_on,
                ),

                // Time Section
                const SizedBox(height: 10),
                _buildRowFields(
                  _buildTextField(
                    label: 'Start Time',
                    controller: _startTimeController,
                    isRequired: true,
                    isTimeField: true,
                    icon: Icons.access_time,
                  ),
                  _buildTextField(
                    label: 'End Time',
                    controller: _endTimeController,
                    isRequired: true,
                    isTimeField: true,
                    icon: Icons.access_time,
                  ),
                ),

                // Night Hault Switch
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.nightlight_round, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text('Night Hault', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _nightHault,
                        onChanged: (value) {
                          setState(() {
                            _nightHault = value;
                          });
                        },
                        activeColor: FlavorConfig.instance.primaryColor,
                      ),
                    ],
                  ),
                ),

                // Expenses Section
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildExpenseField(
                  label: 'Fare Amount',
                  controller: _fareAmountController,
                  isRequired: true,
                  icon: Icons.attach_money,
                ),
                _buildExpenseField(
                  label: 'Lodging',
                  controller: _lodgingController,
                  icon: Icons.hotel,
                ),
                _buildExpenseField(
                  label: 'Food Allowance',
                  controller: _dailyAllowanceController,
                  icon: Icons.restaurant,
                ),
                _buildExpenseField(
                  label: 'Other Expenses',
                  controller: _otherExpensesController,
                  icon: Icons.currency_rupee,
                ),
                const SizedBox(height: 10),
                _buildExpenseField(
                  label: 'Auto Charges',
                  controller: _autoChargesController,
                  icon: Icons.local_taxi,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Auto Charges Details',
                  controller: _autoChargesDetailController,
                  icon: Icons.note,
                ),

                // Extra Details
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Extra Expense Details',
                  controller: _extraDetailsController,
                  icon: Icons.description,
                ),

                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlavorConfig.instance.primaryColor,
                    ),
                  ),
                ),
                _buildUploadSection(),
                const SizedBox(height: 10),
                Obx(() => _buildUploadedDocumentsList()),

                // Total Expenses
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Expenses:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '₹${_totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlavorConfig.instance.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                // Cancel Button
                const SizedBox(height: 12),
                SafeArea(
                  maintainBottomViewPadding: true,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
  File? selectedFile;
  final bool _isFormUnlocked = true;

  Future<void> pickFile() async {
    if (!_isFormUnlocked) return;

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
      final String userId = 'df2711c8-95ad-42b4-be08-735c7475cde9';
      final String recordId = widget.voucher.expenseId!;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final uploadedId = await _insertController.uploadDocument(
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
                        if (_insertController.isUploadingDocument.value) {
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
                            _insertController.isUploadingDocument.value
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
                  if (_insertController.isLoadingDocuments.value) {
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

                  if (_insertController.uploadedDocuments.isNotEmpty) {
                    return Column(
                      children: [
                        Text(
                          "${_insertController.uploadedDocuments.length} Document(s) Uploaded",
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
      ],
    );
  }

  Widget _buildUploadedDocumentsList() {
    if (_insertController.uploadedDocuments.isEmpty) return Container();

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
                Text("(${_insertController.uploadedDocuments.length})",
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ..._insertController.uploadedDocuments.map((doc) {
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
                          final String recordId = widget.voucher.expenseId!;

                          await _insertController.deleteDocument(
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
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';
// import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/tour_voucher_screen_controller.dart';

// class EditTourVoucherScreen extends StatefulWidget {
//   final TourVoucherModel voucher;

//   const EditTourVoucherScreen({super.key, required this.voucher});

//   @override
//   State<EditTourVoucherScreen> createState() => _EditTourVoucherScreenState();
// }

// class _EditTourVoucherScreenState extends State<EditTourVoucherScreen> {
//   final TourVoucherController _controller = Get.find<TourVoucherController>();
//   final _formKey = GlobalKey<FormState>();

//   // Text controllers
//   late TextEditingController _fromPlaceController;
//   late TextEditingController _toPlaceController;
//   late TextEditingController _travellingByController;
//   late TextEditingController _fareAmountController;
//   late TextEditingController _lodgingController;
//   late TextEditingController _dailyAllowanceController;
//   late TextEditingController _otherExpensesController;
//   late TextEditingController _autoChargesController;
//   late TextEditingController _autoChargesDetailController;
//   late TextEditingController _otherChargesDetailController;

//   // State variables
//   late bool _nightHault;
//   double _totalExpenses = 0;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize controllers with voucher data
//     _fromPlaceController =
//         TextEditingController(text: widget.voucher.fromPlace);
//     _toPlaceController = TextEditingController(text: widget.voucher.toPlace);
//     _travellingByController =
//         TextEditingController(text: widget.voucher.travellingBy);
//     _fareAmountController =
//         TextEditingController(text: widget.voucher.fareAmount);
//     _lodgingController = TextEditingController(text: widget.voucher.lodging);
//     _dailyAllowanceController =
//         TextEditingController(text: widget.voucher.dailyAllowance);
//     _otherExpensesController =
//         TextEditingController(text: widget.voucher.otherExpenses);
//     _autoChargesController =
//         TextEditingController(text: widget.voucher.autoCharges);
//     _autoChargesDetailController =
//         TextEditingController(text: widget.voucher.autoChargesDetail);
//     _otherChargesDetailController =
//         TextEditingController(text: widget.voucher.otherChargesDetail);

//     _nightHault = widget.voucher.nighHault == 'True';
//     _calculateTotal();

//     // Listen for changes to recalculate total
//     _fareAmountController.addListener(_calculateTotal);
//     _lodgingController.addListener(_calculateTotal);
//     _dailyAllowanceController.addListener(_calculateTotal);
//     _otherExpensesController.addListener(_calculateTotal);
//     _autoChargesController.addListener(_calculateTotal);
//   }

//   @override
//   void dispose() {
//     _fromPlaceController.dispose();
//     _toPlaceController.dispose();
//     _travellingByController.dispose();
//     _fareAmountController.dispose();
//     _lodgingController.dispose();
//     _dailyAllowanceController.dispose();
//     _otherExpensesController.dispose();
//     _autoChargesController.dispose();
//     _autoChargesDetailController.dispose();
//     _otherChargesDetailController.dispose();
//     super.dispose();
//   }

//   void _calculateTotal() {
//     double fare = double.tryParse(_fareAmountController.text) ?? 0;
//     double lodging = double.tryParse(_lodgingController.text) ?? 0;
//     double allowance = double.tryParse(_dailyAllowanceController.text) ?? 0;
//     double other = double.tryParse(_otherExpensesController.text) ?? 0;
//     double autoCharges = double.tryParse(_autoChargesController.text) ?? 0;

//     setState(() {
//       _totalExpenses = fare + lodging + allowance + other + autoCharges;
//     });
//   }

//   Future<void> _saveChanges() async {
//     if (_formKey.currentState!.validate()) {
//       // Update the voucher with new values
//       _controller.updateSelectedVoucherField(
//           'fromPlace', _fromPlaceController.text);
//       _controller.updateSelectedVoucherField(
//           'toPlace', _toPlaceController.text);
//       _controller.updateSelectedVoucherField(
//           'travellingBy', _travellingByController.text);
//       _controller.updateSelectedVoucherField(
//           'fareAmount', _fareAmountController.text);
//       _controller.updateSelectedVoucherField(
//           'lodging', _lodgingController.text);
//       _controller.updateSelectedVoucherField(
//           'dailyAllowance', _dailyAllowanceController.text);
//       _controller.updateSelectedVoucherField(
//           'otherExpenses', _otherExpensesController.text);
//       _controller.updateSelectedVoucherField(
//           'autoCharges', _autoChargesController.text);
//       _controller.updateSelectedVoucherField(
//           'autoChargesDetail', _autoChargesDetailController.text);
//       _controller.updateSelectedVoucherField(
//           'otherChargesDetail', _otherChargesDetailController.text);
//       _controller.updateSelectedVoucherField('nighHault', _nightHault);

//       // Get the updated voucher
//       final updatedVoucher = _controller.selectedVoucher.value!;

//       // Call update API
//       final success = await _controller.updateTourVoucher(updatedVoucher);

//       if (success) {
//         Get.back(); // Close edit screen
//         Get.snackbar(
//           'Success',
//           'Tour voucher updated successfully!',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//         );
//       } else {
//         Get.snackbar(
//           'Error',
//           _controller.updateMessage.value,
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//         );
//       }
//     }
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     bool isRequired = false,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           labelText: label + (isRequired ? ' *' : ''),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         ),
//         validator: isRequired
//             ? (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter $label';
//                 }
//                 return null;
//               }
//             : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Get.back(),
//         ),
//         title: const Text(
//           'Edit Tour Voucher',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//       ),
//       body: Obx(() {
//         if (_controller.isUpdating.value) {
//           return const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
//                 ),
//                 SizedBox(height: 16),
//                 Text('Updating voucher...'),
//               ],
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Basic Information
//                 _buildTextField(
//                   label: 'From Place',
//                   controller: _fromPlaceController,
//                   isRequired: true,
//                 ),
//                 _buildTextField(
//                   label: 'To Place',
//                   controller: _toPlaceController,
//                   isRequired: true,
//                 ),
//                 _buildTextField(
//                   label: 'Travelling By',
//                   controller: _travellingByController,
//                   isRequired: true,
//                 ),

//                 // Night Hault Switch
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.nightlight_round, color: Colors.grey),
//                       const SizedBox(width: 12),
//                       const Text('Night Hault', style: TextStyle(fontSize: 16)),
//                       const Spacer(),
//                       Switch(
//                         value: _nightHault,
//                         onChanged: (value) {
//                           setState(() {
//                             _nightHault = value;
//                           });
//                         },
//                         activeColor: Colors.red,
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Expenses Section
//                 const Padding(
//                   padding: EdgeInsets.only(bottom: 8),
//                   child: Text(
//                     'Expenses',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 _buildTextField(
//                   label: 'Fare Amount (₹)',
//                   controller: _fareAmountController,
//                   isRequired: true,
//                   keyboardType: TextInputType.number,
//                 ),

//                 _buildTextField(
//                   label: 'Food Allowance (₹)',
//                   controller: _dailyAllowanceController,
//                   keyboardType: TextInputType.number,
//                 ),

//                 _buildTextField(
//                   label: 'Auto Charges (₹)',
//                   controller: _autoChargesController,
//                   keyboardType: TextInputType.number,
//                 ),

//                 // Details Section
//                 const SizedBox(height: 15),
//                 const Padding(
//                   padding: EdgeInsets.only(bottom: 8),
//                   child: Text(
//                     'Details',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 // Total Expenses
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: Card(
//                     color: Colors.green.shade50,
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Total Expenses:',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           Text(
//                             '₹${_totalExpenses.toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Save Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: _saveChanges,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Save Changes',
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),
//                 ),

//                 // Cancel Button
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: OutlinedButton(
//                     onPressed: () => Get.back(),
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Colors.grey),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Cancel',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
