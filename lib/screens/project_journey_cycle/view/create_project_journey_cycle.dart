// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:waterman_iattandance/constant/local_db/local_db.dart';
// import '../viewmodel/project_journey_controller.dart';

// class CreateJourneyScreen extends StatefulWidget {
//   const CreateJourneyScreen({super.key});

//   @override
//   State<CreateJourneyScreen> createState() => _CreateJourneyScreenState();
// }

// class _CreateJourneyScreenState extends State<CreateJourneyScreen> {
//   final JourneyCycleController journeyController =
//       Get.find<JourneyCycleController>();
//   TextEditingController stationController = TextEditingController();
//   TextEditingController agendaController = TextEditingController();

//   DateTime get selectedDate => journeyController.selectedDate.value;

//   @override
//   void initState() {
//     super.initState();
//     print('CreateJourneyScreen initialized');

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (journeyController.backDatedRights.value == null) {
//         print('Loading back-dated rights in Create screen...');
//         await journeyController.fetchBackDatedRights();
//       }
//       journeyController.resetPJCCreationState();
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: journeyController.minSelectableDate,
//       lastDate: journeyController.maxSelectableDate ?? DateTime(2030),
//       selectableDayPredicate: (DateTime date) {
//         return journeyController.isDateSelectable(date);
//       },
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.red.shade700,
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red.shade700,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null && picked != selectedDate) {
//       print('User selected date: $picked');
//       journeyController.updateSelectedDate(picked);
//     }
//   }

//   Widget _buildInputField({
//     required IconData icon,
//     required String label,
//     required String hintText,
//     required VoidCallback onTap,
//     TextEditingController? controller,
//     bool readOnly = false,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(4.0),
//       ),
//       child: InkWell(
//         onTap: readOnly ? onTap : null,
//         child: Row(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Icon(icon, color: Colors.grey.shade600),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 12.0),
//                 child: readOnly
//                     ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(label,
//                               style: TextStyle(
//                                   color: Colors.grey.shade600, fontSize: 12)),
//                           const SizedBox(height: 2),
//                           Text(hintText,
//                               style: const TextStyle(
//                                   fontSize: 16, color: Colors.black)),
//                         ],
//                       )
//                     : TextField(
//                         controller: controller,
//                         readOnly: readOnly,
//                         decoration: InputDecoration(
//                             labelText: null,
//                             hintText: hintText,
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.only(bottom: 5)),
//                         style: const TextStyle(fontSize: 16),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleCreate() async {
//     print('Create button pressed');

//     if (stationController.text.isEmpty) {
//       Get.snackbar(
//         'Error',
//         'Please enter station',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//       return;
//     }

//     if (agendaController.text.isEmpty) {
//       Get.snackbar(
//         'Error',
//         'Please enter visit agenda',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//       return;
//     }

//     if (!journeyController.isDateSelectable(selectedDate)) {
//       Get.snackbar(
//         'Date Not Available',
//         'You can only select dates from today to next ${journeyController.allowedDays} days',
//         backgroundColor: Colors.orange.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//       return;
//     }

//     print('Form validation successful');
//     final mobileNo = _getUserMobileNumber();

//     if (mobileNo.isEmpty) {
//       Get.snackbar(
//         'Error',
//         'User mobile number not available. Please login again.',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 4),
//       );
//       return;
//     }

//     print('Using mobile number: $mobileNo');

//     // Show loading
//     Get.dialog(
//       const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(
//               'Creating Journey Plan...',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//       barrierDismissible: false,
//     );

//     try {
//       // Create PJC
//       final success = await journeyController.createPJC(
//         date: selectedDate,
//         station: stationController.text,
//         agenda: agendaController.text,
//         mobileNo: mobileNo,
//       );

//       Get.back(); // Hide loading

//       if (success) {
//         Get.snackbar(
//           'Success',
//           'Journey Plan Created Successfully!',
//           backgroundColor: Colors.green.withOpacity(0.9),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 2),
//         );

//         // ✅ FIXED: Navigate back with success result
//         Future.delayed(const Duration(seconds: 1), () {
//           Get.back(result: true); // Pass true to indicate success
//         });
//       } else {
//         Get.snackbar(
//           'Error',
//           journeyController.createPJCMessage.value,
//           backgroundColor: Colors.red.withOpacity(0.9),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 4),
//         );
//       }
//     } catch (e) {
//       Get.back();
//       Get.snackbar(
//         'Error',
//         e.toString(),
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 4),
//       );
//     }
//   }

//   String _getUserMobileNumber() {
//     try {
//       final localDb = LocalDbController.to;
//       if (!localDb.loggedIn) {
//         return '';
//       }
//       final mobileNo = localDb.getMobileNo();
//       return mobileNo.isNotEmpty ? mobileNo : '9106497803';
//     } catch (e) {
//       return '9106497803';
//     }
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
//           'Projected Journey Cycle',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//       ),
//       body: Column(
//         children: [
//           _buildInputField(
//             icon: Icons.calendar_today,
//             label: 'date',
//             hintText: DateFormat('dd-MMM-yyyy').format(selectedDate),
//             onTap: () => _selectDate(context),
//             readOnly: true,
//           ),

//           _buildInputField(
//             icon: Icons.location_on,
//             label: '',
//             hintText: 'enter station',
//             controller: stationController,
//             onTap: () {},
//           ),

//           _buildInputField(
//             icon: Icons.menu_book,
//             label: '',
//             hintText: 'enter visit agenda',
//             controller: agendaController,
//             onTap: () {},
//           ),

//           // Date restrictions info
//           if (journeyController.backDatedRights.value != null)
//             Container(
//               margin:
//                   const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//               padding: const EdgeInsets.all(12.0),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(4.0),
//                 border: Border.all(color: Colors.blue.shade100),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline,
//                       color: Colors.blue.shade700, size: 16),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'You can select dates from today to next ${journeyController.allowedDays} days',
//                       style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           const Spacer(),

//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _handleCreate,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(4.0),
//                   ),
//                 ),
//                 child: const Text(
//                   'Create',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     stationController.dispose();
//     agendaController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import 'package:waterman_iattandance/screens/home/view/home_screen.dart';
import '../../../flavor_config.dart';
import '../viewmodel/Project_journey_controller.dart';

class CreateJourneyScreen extends StatefulWidget {
  const CreateJourneyScreen({super.key});

  @override
  State<CreateJourneyScreen> createState() => _CreateJourneyScreenState();
}

class _CreateJourneyScreenState extends State<CreateJourneyScreen> {
  final JourneyCycleController journeyController =
      Get.find<JourneyCycleController>();
  TextEditingController stationController = TextEditingController();
  TextEditingController agendaController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    print('🎯 CreateJourneyScreen initialized');

    journeyController.selectedDate.value = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🔄 Initializing back-dated rights...');
      if (journeyController.backDatedRights.value == null) {
        await journeyController.fetchBackDatedRights();
      }
      journeyController.resetPJCCreationState();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    print('📅 Date picker opened');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: journeyController.selectedDate.value,
      firstDate: journeyController.minSelectableDate,
      lastDate: journeyController.maxSelectableDate ?? DateTime(2030),
      selectableDayPredicate: (DateTime date) {
        return journeyController.isDateSelectable(date);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlavorConfig.instance.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: FlavorConfig.instance.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != journeyController.selectedDate.value) {
      print('✅ User selected date: $picked');
      journeyController.updateSelectedDate(picked);
      setState(() {});
    }
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String hintText,
    required VoidCallback onTap,
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: InkWell(
        onTap: readOnly ? onTap : null,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(icon, color: Colors.grey.shade600),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: readOnly
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd-MMM-yyyy')
                                .format(journeyController.selectedDate.value),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                          ),
                        ],
                      )
                    : TextField(
                        controller: controller,
                        readOnly: readOnly,
                        decoration: InputDecoration(
                            labelText: null,
                            hintText: hintText,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 5)),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreate() async {
    if (_isCreating) return;

    print('🎯 Create button pressed');

    if (stationController.text.isEmpty) {
      _showErrorSnackbar('Please Enter Station');
      return;
    }

    if (agendaController.text.isEmpty) {
      _showErrorSnackbar('Please Enter Visit Agenda');
      return;
    }

    final selectedDate = journeyController.selectedDate.value;
    if (!journeyController.isDateSelectable(selectedDate)) {
      _showWarningSnackbar(
          'You can only select dates from today to next ${journeyController.allowedDays} days');
      return;
    }

    print('✅ Form validation successful');
    final mobileNo = _getUserMobileNumber();
    if (mobileNo.isEmpty) {
      _showErrorSnackbar(
          'User mobile number not available. Please login again.');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    {
      print('🚀 Calling createPJC API...');
      final success = await journeyController.createPJC(
        date: selectedDate,
        station: stationController.text,
        agenda: agendaController.text,
        mobileNo: mobileNo,
      );

      print('📡 API Response - Success: $success');

      setState(() {
        _isCreating = false;
      });

      if (success) {
        print('✅ Journey creation successful');

        // ✅ FIXED: First show snackbar, then navigate
        _showSuccessSnackbar('Journey Plan Created Successfully!');

        // Wait for snackbar to show, then navigate
        await Future.delayed(const Duration(milliseconds: 500));

        // Clear form and navigate directly to home screen (Dashboard)
        Get.offAll(() => const HomeScreen());

        stationController.clear();
        agendaController.clear();

        print('🔙 Navigating back to calendar screen...');
      } else {
        _showErrorSnackbar(journeyController.createPJCMessage.value);
      }
    }
    // } catch (e) {
    //   setState(() {
    //     _isCreating = false;
    //   });
    //   _showErrorSnackbar(e.toString());
    // }
  }

  void _showSuccessSnackbar(String message) {
    CustomSnackBar.show(
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    CustomSnackBar.show(
      message: message,
      isError: true,
      duration: const Duration(seconds: 3),
    );
  }

  void _showWarningSnackbar(String message) {
    CustomSnackBar.show(
      message: message,
      isError: true,
      duration: const Duration(seconds: 3),
    );
  }

  String _getUserMobileNumber() {
    try {
      final localDb = LocalDbController.to;
      if (!localDb.loggedIn) return '';
      return localDb.mobileNo;
    } catch (e) {
      return '';
    }
  }
  // String _getUserMobileNumber() {
  //   try {
  //     final localDb = LocalDbController.to;
  //     if (!localDb.loggedIn) return '';
  //     final mobileNo = localDb.getMobileNo();
  //     return mobileNo.isNotEmpty ? mobileNo : '';
  //   } catch (e) {
  //     return '';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(
          context,
          onPressed: () {
            stationController.clear();
            agendaController.clear();
            Get.back();
          },
        ),
        title: Text(
          'Project Journey Cycle',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Obx(() => _buildInputField(
                icon: Icons.calendar_today,
                label: 'date',
                hintText: DateFormat('dd-MMM-yyyy')
                    .format(journeyController.selectedDate.value),
                onTap: () => _selectDate(context),
                readOnly: true,
              )),
          _buildInputField(
            icon: Icons.location_on,
            label: '',
            hintText: 'enter station',
            controller: stationController,
            onTap: () {},
          ),
          _buildInputField(
            icon: Icons.menu_book,
            label: '',
            hintText: 'enter visit agenda',
            controller: agendaController,
            onTap: () {},
          ),
          Obx(() {
            if (FlavorConfig.instance.flavor == AppFlavor.singla) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.hotel, size: 24, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text(
                      'Night Hold *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Yes'),
                      selected: journeyController.nightHold.value == true,
                      onSelected: (selected) {
                        if (selected) {
                          journeyController.nightHold.value = true;
                        }
                      },
                      selectedColor: FlavorConfig.instance.primaryColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: journeyController.nightHold.value == true
                            ? FlavorConfig.instance.primaryColor
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('No'),
                      selected: journeyController.nightHold.value == false,
                      onSelected: (selected) {
                        if (selected) {
                          journeyController.nightHold.value = false;
                        }
                      },
                      selectedColor: FlavorConfig.instance.primaryColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: journeyController.nightHold.value == false
                            ? FlavorConfig.instance.primaryColor
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final allowedDays = journeyController.allowedDays;
            return Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can select dates from today to next $allowedDays days',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          SafeArea(
            maintainBottomViewPadding: true,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlavorConfig.instance.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stationController.dispose();
    agendaController.dispose();
    super.dispose();
  }
}
