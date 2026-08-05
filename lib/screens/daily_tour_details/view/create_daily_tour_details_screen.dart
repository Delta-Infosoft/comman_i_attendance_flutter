import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/model/DTD_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../viewmodel/DTD_Controller.dart';
import '../../../flavor_config.dart';

class CreateEditTourScreen extends StatefulWidget {
  final Map<String, dynamic>? tourData;
  const CreateEditTourScreen({super.key, this.tourData});

  @override
  State<CreateEditTourScreen> createState() => _CreateEditTourScreenState();
}

class _CreateEditTourScreenState extends State<CreateEditTourScreen> {
  final DTDController _dtdController = Get.find<DTDController>();
  final LocalDbController _localDb = Get.find<LocalDbController>();

  // DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fromPlaceController = TextEditingController();
  final TextEditingController _toPlaceController = TextEditingController();
  TextListItem? _selectedDealerCategory;
  final TextEditingController _dealerNameController = TextEditingController();
  District? _selectedDistrict;
  final TextEditingController _talukaController = TextEditingController();
  final TextEditingController _marketCentreNameController =
      TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _commonDiscussionController =
      TextEditingController();
  final TextEditingController _districtSearchController = TextEditingController();
  final TextEditingController _dealerCategorySearchController =
      TextEditingController();

  // Pending category name from tourData (applied after dealerCategories list loads)
  String? _pendingCategoryName;

  final Map<String, bool> _followUpOptions = {
    'Discount Discussion': false,
    'Scheme Discussion': false,
    'Sales Promotional Activity': false,
    'Stock Planning': false,
    'Service Or Repairing': false,
    'New Dealer Appointment': false,
    'Sub Dealer Visit': false,
    'New Dealer Survey': false,
    'Order Discussion': false,
    'Payment Discussion': false,
  };

  @override
  void initState() {
    super.initState();
    print("EmpId>>>>>>>>>>>>>>: ${Get.find<LocalDbController>().empId}");
    _dtdController.fetchBackDatedRights();
    _initializeForm();

    // After dealerCategories loads, apply the pending category selection.
    // This avoids the DropdownButton2 assertion crash when categories are
    // empty at initState time.
    ever(_dtdController.dealerCategories, (_) {
      if (_pendingCategoryName != null && _pendingCategoryName!.isNotEmpty) {
        final match = _dtdController.dealerCategories.firstWhereOrNull(
          (c) => c.text == _pendingCategoryName,
        );
        if (match != null && mounted) {
          setState(() {
            _selectedDealerCategory = match;
            _pendingCategoryName = null; // clear so it only applies once
          });
        }
      }
    });

    _setMobileNumberFromLocalDb();
  }

  void _initializeForm() {
    if (widget.tourData != null) {

      // Pre-fill mode (e.g. from Dealer Check-Out)
      final date = widget.tourData!['date'] as DateTime? ?? DateTime.now();
      _dtdController.selectedDate.value = date;

      // Set default start/end times if not provided
      _dtdController.startTime.value =
          widget.tourData!['startTime'] as TimeOfDay? ?? TimeOfDay.now();
      _dtdController.endTime.value =
          widget.tourData!['endTime'] as TimeOfDay? ??
              TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

      _dateController.text = DateFormat('dd-MMM-yyyy').format(date);
      _fromPlaceController.text = widget.tourData!['fromPlace'] ?? '';
      _toPlaceController.text = widget.tourData!['toPlace'] ?? '';
      _dealerNameController.text = widget.tourData!['dealerName'] ?? '';
      _mobileNoController.text = widget.tourData!['mobileNo'] ?? '';

      // Enable the form — date is already set, no need to lock it
      _dtdController.isFormEnabled.value = true;

      // Set dealer category safely.
      // dealerCategories may be empty when initState runs (async load).
      // We store the name in _pendingCategoryName and apply it via ever()
      // listener above once categories are available.
      if (widget.tourData!['dealerCategory'] is String) {
        final categoryName = widget.tourData!['dealerCategory'] as String;
        if (categoryName.isNotEmpty) {
          // Try immediate match first (if categories already loaded)
          final match = _dtdController.dealerCategories.firstWhereOrNull(
            (c) => c.text == categoryName,
          );
          if (match != null) {
            _selectedDealerCategory = match;
          } else {
            // Categories not loaded yet — defer via ever() listener
            _pendingCategoryName = categoryName;
          }
        }
      }

      if (widget.tourData!['district'] is String) {
        final districtName = widget.tourData!['district'];
        _selectedDistrict = _dtdController.districts.firstWhere(
          (district) => district.district == districtName,
          orElse: () => District(district: districtName),
        );
      }
    } else {
      // For new tours, do NOT set a default date.
      // The user must select it manually.
      _dtdController.selectedDate.value = null;

      if (_dtdController.startTime.value == null) {
        _dtdController.startTime.value = TimeOfDay.now();
      }

      if (_dtdController.endTime.value == null) {
        _dtdController.endTime.value =
            TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
      }

      // 🔥 Disable form until date is selected and validated
      _dtdController.isFormEnabled.value = false;
    }
  }

  void _setMobileNumberFromLocalDb() {
    try {
      final mobile = _localDb.mobileNo;
      if (mobile.isNotEmpty) _mobileNoController.text = mobile;
    } catch (e) {
      debugPrint('Error setting mobile number: $e');
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _fromPlaceController.dispose();
    _toPlaceController.dispose();
    _dealerNameController.dispose();
    _talukaController.dispose();
    _marketCentreNameController.dispose();
    _mobileNoController.dispose();
    _commonDiscussionController.dispose();
    _districtSearchController.dispose();
    _dealerCategorySearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final rights = _dtdController.backDatedRights.value;

    if (rights == null) {
      AppSnackBar.info("Please wait", "Loading back-dated rights...");
      return;
    }

    int allowedDays =
        int.tryParse(rights.noOfDays ?? "0") ?? 0;

    final DateTime today = DateTime.now();
    // Use max(0, allowedDays) to ensure we don't have negative duration,
    // although the API should return non-negative.
    final DateTime minDate =
    today.subtract(Duration(days: allowedDays < 0 ? 0 : allowedDays));

    print("Allowed Days: $allowedDays");
    print("Min Date: $minDate");

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dtdController.selectedDate.value ?? today,
      firstDate: minDate,
      lastDate: today, // no future allowed
    );

    if (picked != null) {
      _dtdController.selectedDate.value = picked;
      await _validateDate(picked);
    }
  }

  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime today = DateTime.now();
  //   final DateTime minDate = today.subtract(const Duration(days: 4));
  //
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: _dtdController.selectedDate.value ?? today,
  //     firstDate: minDate,
  //     lastDate: DateTime(2030),
  //   );
  //
  //   if (picked != null && picked != _dtdController.selectedDate.value) {
  //     setState(() {
  //       _dtdController.selectedDate.value = picked;
  //     });
  //     _validateDate(picked);
  //   }
  //
  //   // if (picked != null) {
  //   //   _dtdController.selectedDate.value = picked;
  //   //   _validateDate(picked);
  //   // }
  // }

  Future<void> _validateDate(DateTime selectedDate) async {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(selectedDate);
    String mobileNo = _mobileNoController.text.isNotEmpty
        ? _mobileNoController.text
        : LocalDbController.to.mobileNo;

    // 1️⃣ Existing PJC entry validation
    _dtdController.checkEntryValidation(
        mobileNo: mobileNo, date: formattedDate, showLoader: false);

    // 2️⃣ New attendance status check
    final isPresent = await _dtdController.checkAttendanceStatus(
        mobileNo: mobileNo, date: formattedDate);

    if (!isPresent) {
      // Disable form – user is Absent for selected date
      _dtdController.isFormEnabled.value = false;
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Attendance Alert'),
            content: const Text(
              'You are marked Absent for the selected date.\n'
              'Daily Tour cannot be submitted on an Absent day.',
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
    }
  }

  Future<void> _selectTime(BuildContext context,
      {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_dtdController.startTime.value ?? TimeOfDay.now())
          : (_dtdController.endTime.value ?? TimeOfDay.now()),
    );
    if (picked != null) {
      if (isStartTime) {
        _dtdController.startTime.value = picked;
      } else {
        _dtdController.endTime.value = picked;
      }
    }
  }

  // void _initializeForm() {
  //   if (widget.tourData != null) {
  //     _dtdController.selectedDate = widget.tourData!['date'];
  //     _startTime = widget.tourData!['startTime'];
  //     _endTime = widget.tourData!['endTime'];
  //     _fromPlaceController.text = widget.tourData!['fromPlace'] ?? '';
  //     _toPlaceController.text = widget.tourData!['toPlace'] ?? '';
  //
  //     // Update dealer category initialization
  //     if (widget.tourData!['dealerCategory'] is String) {
  //       final categoryName = widget.tourData!['dealerCategory'];
  //       _selectedDealerCategory = _dtdController.dealerCategories.firstWhere(
  //         (category) => category.text == categoryName,
  //         orElse: () => TextListItem(textListId: '', text: categoryName),
  //       );
  //     }
  //
  //     _dealerNameController.text = widget.tourData!['dealerName'] ?? '';
  //
  //     // Update district initialization
  //     if (widget.tourData!['district'] is String) {
  //       final districtName = widget.tourData!['district'];
  //       _selectedDistrict = _dtdController.districts.firstWhere(
  //         (district) => district.district == districtName,
  //         orElse: () => District(district: districtName),
  //       );
  //     }
  //
  //     _talukaController.text = widget.tourData!['taluka'] ?? '';
  //     _marketCentreNameController.text =
  //         widget.tourData!['marketCentreName'] ?? '';
  //     _mobileNoController.text = widget.tourData!['mobileNo'] ?? '';
  //     _commonDiscussionController.text =
  //         widget.tourData!['commonDiscussion'] ?? '';
  //
  //     if (widget.tourData!['followUpFor'] is Map<String, bool>) {
  //       (widget.tourData!['followUpFor'] as Map<String, bool>)
  //           .forEach((key, value) {
  //         if (_followUpOptions.containsKey(key)) {
  //           _followUpOptions[key] = value;
  //         }
  //       });
  //     }
  //   } else {
  //     _dtdController.selectedDate.value = DateTime.now();
  //     _startTime = TimeOfDay.now();
  //     _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  //   }
  // }
  //
  // void _setMobileNumberFromLocalDb() {
  //   try {
  //     final mobile = _localDb.mobileNo;
  //
  //     if (mobile.isNotEmpty) {
  //       _mobileNoController.text = mobile;
  //     }
  //   } catch (e) {
  //     print('Error setting mobile number: $e');
  //   }
  // }
  //
  // @override
  // void dispose() {
  //   _fromPlaceController.dispose();
  //   _toPlaceController.dispose();
  //   _dealerNameController.dispose();
  //   _talukaController.dispose();
  //   _marketCentreNameController.dispose();
  //   _mobileNoController.dispose();
  //   _commonDiscussionController.dispose();
  //   super.dispose();
  // }
  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime today = DateTime.now();
  //   final DateTime minDate = today.subtract(const Duration(days: 4));
  //   // 👆 last 5 days allowed (23 Feb agar aaj 28 Feb hai)
  //
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate:  _dtdController.selectedDate.value ?? today,
  //     firstDate: minDate,
  //     lastDate: DateTime(2030),
  //     builder: (context, child) {
  //       return Theme(
  //         data: ThemeData.light().copyWith(
  //           colorScheme: ColorScheme.light(
  //             primary: Colors.red.shade700,
  //             onPrimary: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //           textButtonTheme: TextButtonThemeData(
  //             style: TextButton.styleFrom(
  //               foregroundColor: Colors.red.shade700,
  //             ),
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );
  //
  //   if (picked != null && picked != _dtdController.selectedDate.value) {
  //     setState(() {
  //      _dtdController.selectedDate.value = picked;
  //     });
  //     _validateDate(picked);
  //   }
  // }
  // // Future<void> _selectDate(BuildContext context) async {
  // //   final DateTime? picked = await showDatePicker(
  // //     context: context,
  // //     initialDate: _selectedDate ?? DateTime.now(),
  // //     firstDate: DateTime.now(),
  // //     lastDate: DateTime(2030),
  // //     builder: (context, child) {
  // //       return Theme(
  // //         data: ThemeData.light().copyWith(
  // //           colorScheme: ColorScheme.light(
  // //             primary: Colors.red.shade700,
  // //             onPrimary: Colors.white,
  // //             onSurface: Colors.black,
  // //           ),
  // //           textButtonTheme: TextButtonThemeData(
  // //             style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
  // //           ),
  // //         ),
  // //         child: child!,
  // //       );
  // //     },
  // //   );
  // //
  // //   if (picked != null && picked != _selectedDate) {
  // //     setState(() {
  // //       _selectedDate = picked;
  // //     });
  // //     _validateDate(picked);
  // //   }
  // // }
  //
  // void _validateDate(DateTime selectedDate) {
  //   final formattedDate = DateFormat('dd-MMM-yyyy').format(selectedDate);
  //
  //   // Use mobile number from controller (auto-filled from LocalDb)
  //   String mobileNo = _mobileNoController.text.isNotEmpty
  //       ? _mobileNoController.text
  //       : '9106497803'; // Fallback
  //
  //   _dtdController.checkEntryValidation(
  //       mobileNo: mobileNo, date: formattedDate, showLoader: false);
  // }
  //
  // Future<void> _selectTime(BuildContext context,
  //     {required bool isStartTime}) async {
  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: isStartTime
  //         ? (_startTime ?? TimeOfDay.now())
  //         : (_endTime ?? TimeOfDay.now()),
  //     builder: (context, child) {
  //       return Theme(
  //         data: ThemeData.light().copyWith(
  //           colorScheme: ColorScheme.light(
  //             primary: Colors.red.shade700,
  //             onPrimary: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //           textButtonTheme: TextButtonThemeData(
  //             style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       if (isStartTime) {
  //         _startTime = picked;
  //       } else {
  //         _endTime = picked;
  //       }
  //     });
  //   }
  // }

  Future<void> _selectFollowUpDate(
      BuildContext context, String followUpType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dtdController.followUpDates[followUpType] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: FlavorConfig.instance.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: FlavorConfig.instance.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dtdController.followUpDates[followUpType] = picked;
      });
    }
  }

  Widget _buildInputRow({
    required IconData icon,
    required String label,
    String? hintText,
    TextStyle? hintStyle,
    TextEditingController? controller,
    VoidCallback? onTap,
    bool readOnly = false,
    bool required = false,
    Widget? trailing,
    // For string dropdowns (if any remain)
    List<String>? dropdownItems,
    String? selectedDropdownValue,
    ValueChanged<String?>? onDropdownChanged,
    // For district dropdown
    List<District>? districtDropdownItems,
    District? selectedDistrictValue,
    ValueChanged<District?>? onDistrictDropdownChanged,
    // For dealer category dropdown
    List<TextListItem>? dealerCategoryDropdownItems,
    TextListItem? selectedDealerCategoryValue,
    ValueChanged<TextListItem?>? onDealerCategoryDropdownChanged,
    // Keyboard & input control
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(icon, color: Colors.grey.shade600),
              ),
              Expanded(
                child: districtDropdownItems != null
                    ? _buildDistrictDropdown(
                        hintText: hintText,
                        hintStyle: hintStyle,
                        required: required,
                        selectedDistrictValue: selectedDistrictValue,
                        onDistrictDropdownChanged: onDistrictDropdownChanged,
                        readOnly: readOnly,
                      )
                    : dealerCategoryDropdownItems != null
                        ? _buildDealerCategoryDropdown(
                            hintText: hintText,
                            hintStyle: hintStyle,
                            required: required,
                            selectedDealerCategoryValue:
                                selectedDealerCategoryValue,
                            onDealerCategoryDropdownChanged:
                                onDealerCategoryDropdownChanged,
                            readOnly: readOnly,
                          )
                        : dropdownItems != null
                            ? DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedDropdownValue,
                                  hint: Text(
                                    '$hintText${required ? ' *' : ''}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.grey),
                                  onChanged: onDropdownChanged,
                                  items: dropdownItems
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              )
                            : TextField(
                                controller: controller,
                                readOnly: readOnly,
                                onTap: onTap,
                                maxLength: maxLength,
                                inputFormatters: inputFormatters,
                                decoration: InputDecoration(
                                  labelText: (label.isNotEmpty && readOnly)
                                      ? label
                                      : null,
                                  hintText: '$hintText${required ? ' *' : ''}',
                                  hintStyle: hintStyle ??
                                      TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16),
                                  border: InputBorder.none,
                                  counterText: '', // hide the default counter
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  suffixIcon: trailing,
                                  suffixIconConstraints: const BoxConstraints(
                                      minWidth: 0, minHeight: 0),
                                ),
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black),
                                keyboardType: keyboardType ??
                                    ((label == 'Mobile No')
                                        ? TextInputType.phone
                                        : TextInputType.text),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown({
    required String? hintText,
    TextStyle? hintStyle,
    required bool required,
    required District? selectedDistrictValue,
    required ValueChanged<District?>? onDistrictDropdownChanged,
    required bool readOnly,
  }) {
    return Obx(() {
      if (_dtdController.isLoadingDistricts.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Loading districts...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      if (_dtdController.districtErrorMessage.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dtdController.districtErrorMessage.value,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }

      return DropdownButtonHideUnderline(
        child: DropdownButton2<District>(
          isExpanded: true,
          value: selectedDistrictValue,
          hint: Text(
            '$hintText${required ? ' *' : ''}',
            style: hintStyle ??
                TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          onChanged: readOnly ? null : onDistrictDropdownChanged,
          items: _dtdController.districts
              .map<DropdownMenuItem<District>>((District district) {
            return DropdownMenuItem<District>(
              value: district,
              child: Text(
                district.district,
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _districtSearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _districtSearchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Search district...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value!.district
                  .toLowerCase()
                  .contains(searchValue.toLowerCase());
            },
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
          ),
          //This to clear the search value when you close the menu
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              _districtSearchController.clear();
            }
          },
        ),
      );
    });
  }

  Widget _buildDealerCategoryDropdown({
    required String? hintText,
    TextStyle? hintStyle,
    required bool required,
    required TextListItem? selectedDealerCategoryValue,
    required ValueChanged<TextListItem?>? onDealerCategoryDropdownChanged,
    required bool readOnly,
  }) {
    return Obx(() {
      print('🔄 Building dealer category dropdown UI...');
      print(
          '📊 Categories available: ${_dtdController.dealerCategories.length}');

      // Show loading state
      if (_dtdController.isLoadingDealerCategories.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Loading dealer categories...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      // Show error state
      if (_dtdController.dealerCategoryErrorMessage.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dtdController.dealerCategoryErrorMessage.value,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }

      // Show empty state
      if (_dtdController.dealerCategories.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No dealer categories available',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        );
      }

      // Show the actual dropdown
      return DropdownButtonHideUnderline(
        child: DropdownButton2<TextListItem>(
          isExpanded: true,
          value: selectedDealerCategoryValue,
          hint: Text(
            '$hintText${required ? ' *' : ''}',
            style: hintStyle ??
                TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          onChanged: readOnly ? null : onDealerCategoryDropdownChanged,
          selectedItemBuilder: (BuildContext context) {
            return _dtdController.dealerCategories.map<Widget>((TextListItem category) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  category.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _dtdController.dealerCategories
              .map<DropdownMenuItem<TextListItem>>((TextListItem category) {
            return DropdownMenuItem<TextListItem>(
              value: category,
              child: Text(
                category.text,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _dealerCategorySearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _dealerCategorySearchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Search category...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value!.text
                  .toLowerCase()
                  .contains(searchValue.toLowerCase());
            },
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
          ),
          //This to clear the search value when you close the menu
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              _dealerCategorySearchController.clear();
            }
          },
        ),
      );
    });
  }

  Widget _buildFollowUpDateField(String followUpType) {
    // Initialize dates if they don't exist
    if (!_dtdController.followUpDates.containsKey(followUpType)) {
      _dtdController.followUpDates[followUpType] = DateTime.now();
    }

    String fieldLabel = '';
    String hintText = '';

    // Set appropriate labels based on follow-up type
    switch (followUpType) {
      case 'New Dealer Appointment':
        fieldLabel = 'New Dealer Appointment Date *';
        hintText = 'Select Appointment Date';
        break;
      case 'Sub Dealer Visit':
        fieldLabel = 'Sub Dealer Visit Date *';
        hintText = 'Select Visit Date';
        break;
      case 'New Dealer Survey':
        fieldLabel = 'New Dealer Survey Date *';
        hintText = 'Select Survey Date';
        break;
      case 'Order Discussion':
        fieldLabel = 'Order Follow-Up On *';
        hintText = 'Select Follow-up Date';
        break;
      case 'Payment Discussion':
        fieldLabel = 'Payment Follow-Up On *';
        hintText = 'Select Follow-up Date';
        break;
      default:
        fieldLabel = '$followUpType Date *';
        hintText = 'Select Date';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Field
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
          child: InkWell(
            onTap: _dtdController.isFormEnabled.value
                ? () => _selectFollowUpDate(context, followUpType)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child:
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fieldLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _dtdController.followUpDates[followUpType] != null
                              ? DateFormat('dd-MMM-yyyy').format(
                                  _dtdController.followUpDates[followUpType]!)
                              : hintText,
                          style: TextStyle(
                            fontSize: 16,
                            color: _dtdController.followUpDates[followUpType] !=
                                    null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ),

        // Additional Payment Amount field for Payment Discussion
        if (followUpType == 'Payment Discussion') ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.phone_android_outlined,
                        color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextField(
                          controller: _dtdController.paymentAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter payment amount',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _submitForm() {
    // Individual required field validation
    if (_dtdController.selectedDate.value == null || _dateController.text.isEmpty) {
      CustomSnackBar.show(
        message: 'Please select Date',
        isError: true,
      );
      return;
    }
    if (_dtdController.startTime == null) {
      CustomSnackBar.show(
        message: 'Please select Start Time',
        isError: true,
      );
      return;
    }
    if (_dtdController.endTime == null) {
      CustomSnackBar.show(
        message: 'Please select End Time',
        isError: true,
      );
      return;
    }
    if (_fromPlaceController.text.trim().isEmpty) {
      CustomSnackBar.show(
        message: 'Please enter From Place',
        isError: true,
      );
      return;
    }
    if (_toPlaceController.text.trim().isEmpty) {
      CustomSnackBar.show(
        message: 'Please enter To Place',
        isError: true,
      );
      return;
    }
    if (_selectedDealerCategory == null) {
      CustomSnackBar.show(
        message: 'Please select Dealer Category',
        isError: true,
      );
      return;
    }
    if (_dealerNameController.text.trim().isEmpty) {
      CustomSnackBar.show(
        message: 'Please enter Dealer Name',
        isError: true,
      );
      return;
    }
    if (_selectedDistrict == null) {
      CustomSnackBar.show(
        message: 'Please select District',
        isError: true,
      );
      return;
    }

    // Mobile number — exactly 10 digits required
    final mobileText = _mobileNoController.text.trim();
    if (mobileText.isEmpty) {
      CustomSnackBar.show(
        message: 'Please enter Mobile No',
        isError: true,
      );
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobileText)) {
      CustomSnackBar.show(
        message: 'Mobile No must be exactly 10 digits',
        isError: true,
      );
      return;
    }

    // Validate follow-up dates when checkboxes are checked
    for (String key in _followUpOptions.keys.skip(5)) {
      if (_followUpOptions[key] == true) {
        // Check if date is selected for this follow-up
        if (_dtdController.followUpDates[key] == null) {
          CustomSnackBar.show(
            message: 'Please select date for $key',
            isError: true,
          );
          return;
        }

        // Additional validation for Payment Discussion amount
        if (key == 'Payment Discussion' &&
            (_dtdController.paymentAmountController.text.isEmpty ||
                _dtdController.paymentAmountController.text == '0')) {
          CustomSnackBar.show(
            message: 'Please enter payment amount for Payment Discussion',
            isError: true,
          );
          return;
        }
      }
    }

    // Format follow-up dates for submission
    final Map<String, String> formattedFollowUpDates = {};
    _dtdController.followUpDates.forEach((key, value) {
      if (value != null && _followUpOptions[key] == true) {
        formattedFollowUpDates[key] = DateFormat('dd-MMM-yyyy').format(value);
      }
    });

    // Prepare form data with proper mapping for API
    Map<String, dynamic> formData = {
      'date': _dtdController.selectedDate.value,
      'startTime': _dtdController.startTime.value,
      'endTime': _dtdController.endTime.value,
      'fromPlace': _fromPlaceController.text.trim(),
      'toPlace': _toPlaceController.text.trim(),
      'dealerCategory': _selectedDealerCategory!.text,
      'dealerName': _dealerNameController.text.trim(),
      'district': _selectedDistrict!.district,
      'taluka': _talukaController.text.trim(),
      'marketCentreName': _marketCentreNameController.text.trim(),
      'mobileNo': _mobileNoController.text.trim(),
      'followUpFor': Map<String, bool>.from(
          _followUpOptions), // Create a new map to avoid reference issues
      'followUpDates': formattedFollowUpDates,
      'paymentAmount': _dtdController.paymentAmountController.text.isNotEmpty
          ? _dtdController.paymentAmountController.text
          : '0',
      'commonDiscussion': _commonDiscussionController.text.trim(),
    };

    print('📋 Form Data Prepared:');
    print('📍 From Place: ${formData['fromPlace']}');
    print('📍 To Place: ${formData['toPlace']}');
    print('🏪 Dealer Category: ${formData['dealerCategory']}');
    print('👤 Dealer Name: ${formData['dealerName']}');
    print('🏙️ District: ${formData['district']}');
    print('📱 Mobile No: ${formData['mobileNo']}');
    print('💰 Payment Amount: ${formData['paymentAmount']}');
    print('💬 Common Discussion: ${formData['commonDiscussion']}');
    print('📅 Follow-up Dates: $formattedFollowUpDates');
    print('✅ Follow-up Options: $_followUpOptions');

    // Call the controller to submit the form
    _dtdController.submitDTDForm(formData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: Text(
          'Create Daily Tour',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading Indicator
                    Obx(() {
                      if (_dtdController.isLoading.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox();
                    }),

                    // Date Input
                    // _buildInputRow(
                    //   icon: Icons.calendar_today,
                    //   label: 'Date',
                    //   hintText: _selectedDate == null
                    //       ? 'Select Date'
                    //       : DateFormat('dd-MMM-yyyy').format(_selectedDate!),
                    //   onTap: () => _selectDate(context),
                    //   readOnly: true,
                    //   required: true,
                    // ),
                    // Obx(() => _buildInputRow(
                    //   icon: Icons.calendar_today,
                    //   label: 'Date',
                    //   hintText: _dtdController.selectedDate.value == null
                    //       ? 'Select Date'
                    //       : DateFormat('dd-MMM-yyyy').format(_dtdController.selectedDate.value!),
                    //   onTap: () => _selectDate(context),
                    //   readOnly: true,
                    //   required: true,
                    // )),

                    Obx(() {
                      _dateController.text =
                          _dtdController.selectedDate.value == null
                              ? ''
                              : DateFormat('dd-MMM-yyyy')
                                  .format(_dtdController.selectedDate.value!);

                      return _buildInputRow(
                        icon: Icons.calendar_today,
                        label: '',
                        hintText: 'Select Date',
                        controller: _dateController,
                        onTap: widget.tourData == null ? () => _selectDate(context) : null,
                        readOnly: true,
                        required: true,
                      );
                    }),

                    // Start/End Time Input
                    Obx(() => Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300))),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.grey.shade600),
                              const SizedBox(width: 12),
                              _buildTimeColumn('Start Time *',
                                  _dtdController.startTime.value, true),
                              const SizedBox(width: 20),
                              _buildTimeColumn('End Time *',
                                  _dtdController.endTime.value, false),
                            ],
                          ),
                        )),
                    // Container(
                    //   margin: const EdgeInsets.symmetric(
                    //       horizontal: 16.0, vertical: 4.0),
                    //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                    //   decoration: BoxDecoration(
                    //     border: Border(
                    //         bottom: BorderSide(
                    //             color: Colors.grey.shade300, width: 1)),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Padding(
                    //         padding: const EdgeInsets.only(right: 12.0),
                    //         child: Icon(Icons.schedule,
                    //             color: Colors.grey.shade600),
                    //       ),
                    //       Expanded(
                    //         child: InkWell(
                    //           onTap: () =>
                    //               _selectTime(context, isStartTime: true),
                    //           child: Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Text(
                    //                 'Start Time *',
                    //                 style: TextStyle(
                    //                     color: Colors.grey.shade600,
                    //                     fontSize: 12),
                    //               ),
                    //               Text(
                    //                 _startTime?.format(context) ??
                    //                     'Select Time',
                    //                 style: const TextStyle(
                    //                     fontSize: 16, color: Colors.black),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 20),
                    //       Expanded(
                    //         child: InkWell(
                    //           onTap: () =>
                    //               _selectTime(context, isStartTime: false),
                    //           child: Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Text(
                    //                 'End Time *',
                    //                 style: TextStyle(
                    //                     color: Colors.grey.shade600,
                    //                     fontSize: 12),
                    //               ),
                    //               Text(
                    //                 _endTime?.format(context) ?? 'Select Time',
                    //                 style: const TextStyle(
                    //                     fontSize: 16, color: Colors.black),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // From Place
                    Obx(() => _buildInputRow(
                          icon: Icons.location_on,
                          label: '',
                          hintText: 'From Place',
                          controller: _fromPlaceController,
                          required: true,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    // To Place
                    Obx(() => _buildInputRow(
                          icon: Icons.location_on_outlined,
                          label: '',
                          hintText: 'To Place',
                          controller: _toPlaceController,
                          required: true,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    // Updated Dealer Category Dropdown - Now from API
                    Obx(() => _buildInputRow(
                          icon: Icons.category,
                          label: '',
                          hintText: 'Dealer Category',
                          hintStyle: TextStyle(color: Colors.black, fontSize: 16),
                          dealerCategoryDropdownItems:
                              _dtdController.dealerCategories,
                          selectedDealerCategoryValue: _selectedDealerCategory,
                          onDealerCategoryDropdownChanged:
                              _dtdController.isFormEnabled.value && widget.tourData == null
                                  ? (TextListItem? newValue) {
                                      setState(() {
                                        _selectedDealerCategory = newValue;
                                      });
                                    }
                                  : null,
                          required: true,
                          readOnly: !_dtdController.isFormEnabled.value || widget.tourData != null,
                        )),

                    Obx(() => _buildInputRow(
                          icon: Icons.person_outline,
                          label: '',
                          hintText: 'Dealer Name',
                          controller: _dealerNameController,
                          required: true,
                          readOnly: !_dtdController.isFormEnabled.value || widget.tourData != null,
                        )),

                    // District Dropdown
                    Obx(() => _buildInputRow(
                          icon: Icons.location_city,
                          label: '',
                          hintText: 'District',
                          hintStyle:
                              TextStyle(color: Colors.black, fontSize: 16),
                          districtDropdownItems: _dtdController.districts,
                          selectedDistrictValue: _selectedDistrict,
                          onDistrictDropdownChanged:
                              _dtdController.isFormEnabled.value
                                  ? (District? newValue) {
                                      setState(() {
                                        _selectedDistrict = newValue;
                                      });
                                    }
                                  : null,
                          required: true,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    Obx(() => _buildInputRow(
                          icon: Icons.apartment,
                          label: '',
                          hintText: 'Taluka',
                          controller: _talukaController,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    Obx(() => _buildInputRow(
                          icon: Icons.store,
                          label: '',
                          hintText: 'Market Centre Name',
                          controller: _marketCentreNameController,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    Obx(() => _buildInputRow(
                          icon: Icons.phone_android,
                          label: '',
                          hintText: 'Mobile No',
                          controller: _mobileNoController,
                          readOnly: !_dtdController.isFormEnabled.value,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        )),

                    const SizedBox(height: 20),

                    // Follow-up section - Only checkboxes
                    Obx(() => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: FlavorConfig.instance.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Follow-up for',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // All checkboxes - no additional fields here
                              ..._followUpOptions.keys.map((String key) {
                                return CheckboxListTile(
                                  title: Text(key),
                                  value: _followUpOptions[key],
                                  onChanged: _dtdController.isFormEnabled.value
                                      ? (bool? value) {
                                          setState(() {
                                            _followUpOptions[key] = value!;
                                          });
                                        }
                                      : null,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: FlavorConfig.instance.primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ],
                          ),
                        )),

                    const SizedBox(height: 20),
                    ..._followUpOptions.keys
                        .skip(5)
                        .where((key) => _followUpOptions[key] == true)
                        .map((key) {
                      return _buildFollowUpDateField(key);
                    }).toList(),

                    const SizedBox(height: 5),
                    // Common Discussion
                    Obx(() => _buildInputRow(
                          icon: Icons.chat_bubble_outline,
                          label: '',
                          hintText: 'Common Discussion',
                          controller: _commonDiscussionController,
                          readOnly: !_dtdController.isFormEnabled.value,
                        )),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Submit Button
            Obx(() => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _dtdController.isFormEnabled.value ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dtdController.isFormEnabled.value
                          ? FlavorConfig.instance.primaryColor
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, TimeOfDay? time, bool isStart) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectTime(context, isStartTime: isStart),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(time?.format(context) ?? 'Select Time',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:waterman_iattandance/constant/local_db/local_db.dart';
// import 'package:waterman_iattandance/screens/daily_tour_details/model/DTD_model.dart';
// import '../viewmodel/DTD_Controller.dart';

// class CreateEditTourScreen extends StatefulWidget {
//   final Map<String, dynamic>? tourData;
//   const CreateEditTourScreen({super.key, this.tourData});

//   @override
//   State<CreateEditTourScreen> createState() => _CreateEditTourScreenState();
// }

// class _CreateEditTourScreenState extends State<CreateEditTourScreen> {
//   final DTDController _dtdController = Get.find<DTDController>();
//   final LocalDbController _localDb = Get.find<LocalDbController>();

//   DateTime? _selectedDate;
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;
//   final TextEditingController _fromPlaceController = TextEditingController();
//   final TextEditingController _toPlaceController = TextEditingController();
//   TextListItem? _selectedDealerCategory; // Change from String? to TextListItem?
//   final TextEditingController _dealerNameController = TextEditingController();
//   District? _selectedDistrict;
//   final TextEditingController _talukaController = TextEditingController();
//   final TextEditingController _marketCentreNameController =
//       TextEditingController();
//   final TextEditingController _mobileNoController = TextEditingController();
//   final TextEditingController _commonDiscussionController =
//       TextEditingController();

//   final Map<String, bool> _followUpOptions = {
//     'Discount Discussion': false,
//     'Scheme Discussion': false,
//     'Sales Promotional Activity': false,
//     'Stock Planning': false,
//     'Service Or Repairing': false,
//     'New Dealer Appointment': false,
//     'Sub Dealer Visit': false,
//     'New Dealer Survey': false,
//     'Order Discussion': false,
//     'Payment Discussion': false,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _initializeForm();
//     _dtdController.resetForm();
//     _setMobileNumberFromLocalDb();
//   }

//   void _initializeForm() {
//     if (widget.tourData != null) {
//       _selectedDate = widget.tourData!['date'];
//       _startTime = widget.tourData!['startTime'];
//       _endTime = widget.tourData!['endTime'];
//       _fromPlaceController.text = widget.tourData!['fromPlace'] ?? '';
//       _toPlaceController.text = widget.tourData!['toPlace'] ?? '';

//       // Update dealer category initialization
//       if (widget.tourData!['dealerCategory'] is String) {
//         final categoryName = widget.tourData!['dealerCategory'];
//         _selectedDealerCategory = _dtdController.dealerCategories.firstWhere(
//           (category) => category.text == categoryName,
//           orElse: () => TextListItem(textListId: '', text: categoryName),
//         );
//       }

//       _dealerNameController.text = widget.tourData!['dealerName'] ?? '';

//       // Update district initialization
//       if (widget.tourData!['district'] is String) {
//         final districtName = widget.tourData!['district'];
//         _selectedDistrict = _dtdController.districts.firstWhere(
//           (district) => district.district == districtName,
//           orElse: () => District(district: districtName),
//         );
//       }

//       _talukaController.text = widget.tourData!['taluka'] ?? '';
//       _marketCentreNameController.text =
//           widget.tourData!['marketCentreName'] ?? '';
//       _mobileNoController.text = widget.tourData!['mobileNo'] ?? '';
//       _commonDiscussionController.text =
//           widget.tourData!['commonDiscussion'] ?? '';

//       if (widget.tourData!['followUpFor'] is Map<String, bool>) {
//         (widget.tourData!['followUpFor'] as Map<String, bool>)
//             .forEach((key, value) {
//           if (_followUpOptions.containsKey(key)) {
//             _followUpOptions[key] = value;
//           }
//         });
//       }
//     } else {
//       _selectedDate = DateTime.now();
//       _startTime = TimeOfDay.now();
//       _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
//     }
//   }

//   void _setMobileNumberFromLocalDb() {
//     try {
//       // Try to get mobile number from LocalDb
//       if (_localDb.userMobile != null && _localDb.userMobile!.isNotEmpty) {
//         _mobileNoController.text = _localDb.userMobile!;
//       } else if (_localDb.mobileNo != null && _localDb.mobileNo!.isNotEmpty) {
//         _mobileNoController.text = _localDb.mobileNo!;
//       } else if (_localDb.phone != null && _localDb.phone!.isNotEmpty) {
//         _mobileNoController.text = _localDb.phone!;
//       }
//     } catch (e) {
//       print('Error setting mobile number: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _fromPlaceController.dispose();
//     _toPlaceController.dispose();
//     _dealerNameController.dispose();
//     _talukaController.dispose();
//     _marketCentreNameController.dispose();
//     _mobileNoController.dispose();
//     _commonDiscussionController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.red.shade700,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//       _validateDate(picked);
//     }
//   }

//   void _validateDate(DateTime selectedDate) {
//     final formattedDate = DateFormat('dd-MMM-yyyy').format(selectedDate);

//     // Use mobile number from controller (auto-filled from LocalDb)
//     String mobileNo = _mobileNoController.text.isNotEmpty
//         ? _mobileNoController.text
//         : '9106497803'; // Fallback

//     _dtdController.checkEntryValidation(
//       mobileNo: mobileNo,
//       date: formattedDate,
//     );
//   }

//   Future<void> _selectTime(BuildContext context,
//       {required bool isStartTime}) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: isStartTime
//           ? (_startTime ?? TimeOfDay.now())
//           : (_endTime ?? TimeOfDay.now()),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.red.shade700,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStartTime) {
//           _startTime = picked;
//         } else {
//           _endTime = picked;
//         }
//       });
//     }
//   }

//   Widget _buildInputRow({
//     required IconData icon,
//     required String label,
//     String? hintText,
//     TextEditingController? controller,
//     VoidCallback? onTap,
//     bool readOnly = false,
//     bool required = false,
//     Widget? trailing,
//     // For string dropdowns (if any remain)
//     List<String>? dropdownItems,
//     String? selectedDropdownValue,
//     ValueChanged<String?>? onDropdownChanged,
//     // For district dropdown
//     List<District>? districtDropdownItems,
//     District? selectedDistrictValue,
//     ValueChanged<District?>? onDistrictDropdownChanged,
//     // For dealer category dropdown
//     List<TextListItem>? dealerCategoryDropdownItems,
//     TextListItem? selectedDealerCategoryValue,
//     ValueChanged<TextListItem?>? onDealerCategoryDropdownChanged,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//       decoration: BoxDecoration(
//         border:
//             Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(right: 12.0),
//                 child: Icon(icon, color: Colors.grey.shade600),
//               ),
//               Expanded(
//                 child: districtDropdownItems != null
//                     ? _buildDistrictDropdown(
//                         hintText: hintText,
//                         required: required,
//                         selectedDistrictValue: selectedDistrictValue,
//                         onDistrictDropdownChanged: onDistrictDropdownChanged,
//                         readOnly: readOnly,
//                       )
//                     : dealerCategoryDropdownItems != null
//                         ? _buildDealerCategoryDropdown(
//                             hintText: hintText,
//                             required: required,
//                             selectedDealerCategoryValue:
//                                 selectedDealerCategoryValue,
//                             onDealerCategoryDropdownChanged:
//                                 onDealerCategoryDropdownChanged,
//                             readOnly: readOnly,
//                           )
//                         : dropdownItems != null
//                             ? DropdownButtonHideUnderline(
//                                 child: DropdownButton<String>(
//                                   isExpanded: true,
//                                   value: selectedDropdownValue,
//                                   hint: Text(
//                                     '$hintText${required ? ' *' : ''}',
//                                     style: TextStyle(
//                                         color: Colors.grey.shade600,
//                                         fontSize: 16),
//                                   ),
//                                   icon: const Icon(Icons.arrow_drop_down,
//                                       color: Colors.grey),
//                                   onChanged: onDropdownChanged,
//                                   items: dropdownItems
//                                       .map<DropdownMenuItem<String>>(
//                                           (String value) {
//                                     return DropdownMenuItem<String>(
//                                       value: value,
//                                       child: Text(value),
//                                     );
//                                   }).toList(),
//                                 ),
//                               )
//                             : TextField(
//                                 controller: controller,
//                                 readOnly: readOnly,
//                                 onTap: onTap,
//                                 decoration: InputDecoration(
//                                   labelText: (label.isNotEmpty && readOnly)
//                                       ? label
//                                       : null,
//                                   hintText: '$hintText${required ? ' *' : ''}',
//                                   border: InputBorder.none,
//                                   contentPadding:
//                                       const EdgeInsets.symmetric(vertical: 0),
//                                   suffixIcon: trailing,
//                                   suffixIconConstraints: const BoxConstraints(
//                                       minWidth: 0, minHeight: 0),
//                                 ),
//                                 style: const TextStyle(
//                                     fontSize: 16, color: Colors.black),
//                                 keyboardType: (label == 'Mobile No')
//                                     ? TextInputType.phone
//                                     : TextInputType.text,
//                               ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDistrictDropdown({
//     required String? hintText,
//     required bool required,
//     required District? selectedDistrictValue,
//     required ValueChanged<District?>? onDistrictDropdownChanged,
//     required bool readOnly,
//   }) {
//     return Obx(() {
//       if (_dtdController.isLoadingDistricts.value) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//               SizedBox(width: 12),
//               Text(
//                 'Loading districts...',
//                 style: TextStyle(color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//         );
//       }

//       if (_dtdController.districtErrorMessage.isNotEmpty) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             children: [
//               Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   _dtdController.districtErrorMessage.value,
//                   style: TextStyle(color: Colors.red.shade700, fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }

//       return DropdownButtonHideUnderline(
//         child: DropdownButton<District>(
//           isExpanded: true,
//           value: selectedDistrictValue,
//           hint: Text(
//             '$hintText${required ? ' *' : ''}',
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//           ),
//           icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           onChanged: readOnly ? null : onDistrictDropdownChanged,
//           items: _dtdController.districts
//               .map<DropdownMenuItem<District>>((District district) {
//             return DropdownMenuItem<District>(
//               value: district,
//               child: Text(
//                 district.district,
//                 style: TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             );
//           }).toList(),
//         ),
//       );
//     });
//   }

//   Widget _buildDealerCategoryDropdown({
//     required String? hintText,
//     required bool required,
//     required TextListItem? selectedDealerCategoryValue,
//     required ValueChanged<TextListItem?>? onDealerCategoryDropdownChanged,
//     required bool readOnly,
//   }) {
//     return Obx(() {
//       print('🔄 Building dealer category dropdown UI...');
//       print(
//           '📊 Categories available: ${_dtdController.dealerCategories.length}');

//       // Show loading state
//       if (_dtdController.isLoadingDealerCategories.value) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//               SizedBox(width: 12),
//               Text(
//                 'Loading dealer categories...',
//                 style: TextStyle(color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//         );
//       }

//       // Show error state
//       if (_dtdController.dealerCategoryErrorMessage.isNotEmpty) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             children: [
//               Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   _dtdController.dealerCategoryErrorMessage.value,
//                   style: TextStyle(color: Colors.red.shade700, fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }

//       // Show empty state
//       if (_dtdController.dealerCategories.isEmpty) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Text(
//             'No dealer categories available',
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//         );
//       }

//       // Show the actual dropdown
//       return DropdownButtonHideUnderline(
//         child: DropdownButton<TextListItem>(
//           isExpanded: true,
//           value: selectedDealerCategoryValue,
//           hint: Text(
//             '$hintText${required ? ' *' : ''}',
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//           ),
//           icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           onChanged: readOnly ? null : onDealerCategoryDropdownChanged,
//           items: _dtdController.dealerCategories
//               .map<DropdownMenuItem<TextListItem>>((TextListItem category) {
//             return DropdownMenuItem<TextListItem>(
//               value: category,
//               child: Text(
//                 category.text,
//                 style: TextStyle(fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             );
//           }).toList(),
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Get.back(),
//         ),
//         title: const Text(
//           'Daily Tour Details',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.only(bottom: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Loading Indicator
//                     Obx(() {
//                       if (_dtdController.isLoading.value) {
//                         return const Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(16.0),
//                             child: CircularProgressIndicator(),
//                           ),
//                         );
//                       }
//                       return const SizedBox();
//                     }),

//                     // Date Input
//                     _buildInputRow(
//                       icon: Icons.calendar_today,
//                       label: 'Date',
//                       hintText: _selectedDate == null
//                           ? 'Select Date'
//                           : DateFormat('dd-MMM-yyyy').format(_selectedDate!),
//                       onTap: () => _selectDate(context),
//                       readOnly: true,
//                       required: true,
//                     ),

//                     // Start/End Time Input
//                     Container(
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 16.0, vertical: 4.0),
//                       padding: const EdgeInsets.symmetric(vertical: 8.0),
//                       decoration: BoxDecoration(
//                         border: Border(
//                             bottom: BorderSide(
//                                 color: Colors.grey.shade300, width: 1)),
//                       ),
//                       child: Row(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(right: 12.0),
//                             child: Icon(Icons.schedule,
//                                 color: Colors.grey.shade600),
//                           ),
//                           Expanded(
//                             child: InkWell(
//                               onTap: () =>
//                                   _selectTime(context, isStartTime: true),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Start Time *',
//                                     style: TextStyle(
//                                         color: Colors.grey.shade600,
//                                         fontSize: 12),
//                                   ),
//                                   Text(
//                                     _startTime?.format(context) ??
//                                         'Select Time',
//                                     style: const TextStyle(
//                                         fontSize: 16, color: Colors.black),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 20),
//                           Expanded(
//                             child: InkWell(
//                               onTap: () =>
//                                   _selectTime(context, isStartTime: false),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'End Time *',
//                                     style: TextStyle(
//                                         color: Colors.grey.shade600,
//                                         fontSize: 12),
//                                   ),
//                                   Text(
//                                     _endTime?.format(context) ?? 'Select Time',
//                                     style: const TextStyle(
//                                         fontSize: 16, color: Colors.black),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // From Place
//                     Obx(() => _buildInputRow(
//                           icon: Icons.location_on,
//                           label: '',
//                           hintText: 'From Place',
//                           controller: _fromPlaceController,
//                           required: true,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     // To Place
//                     Obx(() => _buildInputRow(
//                           icon: Icons.location_on_outlined,
//                           label: '',
//                           hintText: 'To Place',
//                           controller: _toPlaceController,
//                           required: true,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     // Updated Dealer Category Dropdown - Now from API
//                     Obx(() => _buildInputRow(
//                           icon: Icons.category,
//                           label: '',
//                           hintText: 'Dealer Category',
//                           dealerCategoryDropdownItems:
//                               _dtdController.dealerCategories,
//                           selectedDealerCategoryValue: _selectedDealerCategory,
//                           onDealerCategoryDropdownChanged:
//                               _dtdController.isFormEnabled.value
//                                   ? (TextListItem? newValue) {
//                                       setState(() {
//                                         _selectedDealerCategory = newValue;
//                                       });
//                                     }
//                                   : null,
//                           required: true,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     Obx(() => _buildInputRow(
//                           icon: Icons.person_outline,
//                           label: '',
//                           hintText: 'Dealer Name',
//                           controller: _dealerNameController,
//                           required: true,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     // District Dropdown
//                     Obx(() => _buildInputRow(
//                           icon: Icons.location_city,
//                           label: '',
//                           hintText: 'District',
//                           districtDropdownItems: _dtdController.districts,
//                           selectedDistrictValue: _selectedDistrict,
//                           onDistrictDropdownChanged:
//                               _dtdController.isFormEnabled.value
//                                   ? (District? newValue) {
//                                       setState(() {
//                                         _selectedDistrict = newValue;
//                                       });
//                                     }
//                                   : null,
//                           required: true,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     Obx(() => _buildInputRow(
//                           icon: Icons.apartment,
//                           label: '',
//                           hintText: 'Taluka',
//                           controller: _talukaController,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     Obx(() => _buildInputRow(
//                           icon: Icons.store,
//                           label: '',
//                           hintText: 'Market Centre Name',
//                           controller: _marketCentreNameController,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     Obx(() => _buildInputRow(
//                           icon: Icons.phone_android,
//                           label: '',
//                           hintText: 'Mobile No',
//                           controller: _mobileNoController,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     const SizedBox(height: 20),

//                     Obx(() => Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 10,
//                                     height: 10,
//                                     decoration: BoxDecoration(
//                                       color: Colors.red,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   const Text(
//                                     'Follow-up for',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               ..._followUpOptions.keys.map((String key) {
//                                 return CheckboxListTile(
//                                   title: Text(key),
//                                   value: _followUpOptions[key],
//                                   onChanged: _dtdController.isFormEnabled.value
//                                       ? (bool? value) {
//                                           setState(() {
//                                             _followUpOptions[key] = value!;
//                                           });
//                                         }
//                                       : null,
//                                   controlAffinity:
//                                       ListTileControlAffinity.leading,
//                                   activeColor: Colors.red,
//                                   contentPadding: EdgeInsets.zero,
//                                 );
//                               }).toList(),
//                             ],
//                           ),
//                         )),

//                     const SizedBox(height: 20),

//                     // Common Discussion
//                     Obx(() => _buildInputRow(
//                           icon: Icons.chat_bubble_outline,
//                           label: '',
//                           hintText: 'Common Discussion',
//                           controller: _commonDiscussionController,
//                           readOnly: !_dtdController.isFormEnabled.value,
//                         )),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//             // Submit Button
//             Obx(() => Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.2),
//                         spreadRadius: 2,
//                         blurRadius: 5,
//                         offset: const Offset(0, -3),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton(
//                     onPressed:
//                         _dtdController.isFormEnabled.value ? _submitForm : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _dtdController.isFormEnabled.value
//                           ? Colors.red.shade700
//                           : Colors.grey.shade400,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                     ),
//                     child: const Text(
//                       'SUBMIT',
//                       style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   void _submitForm() {
//     if (_selectedDate == null ||
//         _startTime == null ||
//         _endTime == null ||
//         _fromPlaceController.text.isEmpty ||
//         _toPlaceController.text.isEmpty ||
//         _selectedDealerCategory == null ||
//         _dealerNameController.text.isEmpty ||
//         _selectedDistrict == null) {
//       Get.snackbar(
//         'Error',
//         'Please fill all required fields (*)',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     Map<String, dynamic> formData = {
//       'date': _selectedDate,
//       'startTime': _startTime,
//       'endTime': _endTime,
//       'fromPlace': _fromPlaceController.text,
//       'toPlace': _toPlaceController.text,
//       'dealerCategory': _selectedDealerCategory!.text, // Get category text
//       'dealerName': _dealerNameController.text,
//       'district': _selectedDistrict!.district, // Get district name
//       'taluka': _talukaController.text,
//       'marketCentreName': _marketCentreNameController.text,
//       'mobileNo': _mobileNoController.text,
//       'followUpFor': _followUpOptions,
//       'commonDiscussion': _commonDiscussionController.text,
//     };

//     _dtdController.submitDTDForm(formData);
//   }
// }
