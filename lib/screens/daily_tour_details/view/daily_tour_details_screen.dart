import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/view/create_daily_tour_details_screen.dart';
import 'package:waterman_iattandance/screens/daily_tour_details/viewmodel/DTD_Controller.dart';
import '../../../flavor_config.dart';

class DailyTourDetailsScreen extends StatefulWidget {
  const DailyTourDetailsScreen({super.key});

  @override
  State<DailyTourDetailsScreen> createState() => _DailyTourDetailsScreenState();
}

class _DailyTourDetailsScreenState extends State<DailyTourDetailsScreen> {
  final DTDController controller = Get.find<DTDController>();
  bool showPendingOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchWeeklyDetailsForDisplay();
    });
  }

  // Helper function to format date to "17 November 2025"
  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return 'No Date';

      String cleanDate = dateStr;
      if (cleanDate.contains(' ')) {
        cleanDate = cleanDate.split(' ').first;
      }

      // Try different possible input formats
      List<String> possibleFormats = [
        'dd-MMM-yyyy', // 17-Nov-2025
        'M/d/yyyy',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'MM-dd-yyyy',
      ];

      DateTime? parsedDate;
      for (String format in possibleFormats) {
        try {
          DateFormat inputFormat = DateFormat(format);
          parsedDate = inputFormat.parse(cleanDate);
          break;
        } catch (e) {
          continue;
        }
      }

      if (parsedDate != null) {
        DateFormat outputFormat = DateFormat('dd MMMM yyyy');
        return outputFormat.format(parsedDate);
      }

      return dateStr; // Return original if parsing fails
    } catch (e) {
      return dateStr; // Return original if any error
    }
  }

  // Format date-time to "17-Nov-2025 12:00:00 PM"
  String _formatDateTime(String dateTimeStr) {
    try {
      if (dateTimeStr.isEmpty || dateTimeStr == '00:00 AM' || dateTimeStr == '00:00 PM') {
        return dateTimeStr;
      }

      // Try different possible input formats
      List<String> possibleFormats = [
        'M/d/yyyy h:mm:ss a',
        'M/d/yyyy hh:mm:ss a',
        'MM/dd/yyyy h:mm:ss a',
        'MM/dd/yyyy hh:mm:ss a',
        'dd-MMM-yyyy hh:mm:ss a',
        'dd-MMM-yyyy h:mm:ss a',
      ];

      DateTime? parsedDate;
      for (String format in possibleFormats) {
        try {
          DateFormat inputFormat = DateFormat(format);
          parsedDate = inputFormat.parse(dateTimeStr);
          break;
        } catch (e) {
          continue;
        }
      }

      if (parsedDate != null) {
        DateFormat outputFormat = DateFormat('dd-MMM-yyyy hh:mm:ss a');
        return outputFormat.format(parsedDate);
      }

      return dateTimeStr; // Return original if parsing fails
    } catch (e) {
      return dateTimeStr; // Return original if any error
    }
  }

  // Check if tour is pending (today or future)
  bool _isTourPending(dynamic tour) {
    try {
      String rawDate = tour['date'] ?? tour['tourDate'] ?? tour['Date'] ?? tour['Dt'] ?? '';
      if (rawDate.isEmpty) return false;

      String cleanDate = rawDate;
      if (cleanDate.contains(' ')) {
        cleanDate = cleanDate.split(' ').first;
      }

      // Try to parse the date
      List<String> possibleFormats = [
        'dd-MMM-yyyy',
        'M/d/yyyy',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'MM-dd-yyyy',
      ];

      DateTime? tourDate;
      for (String format in possibleFormats) {
        try {
          DateFormat inputFormat = DateFormat(format);
          tourDate = inputFormat.parse(cleanDate);
          break;
        } catch (e) {
          continue;
        }
      }

      if (tourDate == null) return false;

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime tourDay = DateTime(tourDate.year, tourDate.month, tourDate.day);

      // Tour is pending if it's today or in future
      return tourDay.isAfter(today) || tourDay.isAtSameMomentAs(today);
    } catch (e) {
      print('Error checking pending status: $e');
      return false;
    }
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInOutItem(String location, String time,
      {required bool isCheckedIn}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 2),
              color: isCheckedIn ? FlavorConfig.instance.primaryColor : Colors.transparent,
            ),
            child: isCheckedIn
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFilterDate(BuildContext context, bool isFromDate, Function setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (controller.filterFromDate.value ?? DateTime.now())
          : (controller.filterToDate.value ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlavorConfig.instance.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setModalState(() {
        if (isFromDate) {
          controller.filterFromDate.value = picked;
        } else {
          controller.filterToDate.value = picked;
        }
      });
    }
  }

  void _filterPendingEntries() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter Tours",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date Range Section
                    const Text(
                      "Date Range",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectFilterDate(context, true, setModalState),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: FlavorConfig.instance.primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.filterFromDate.value != null
                                          ? DateFormat('dd-MMM-yyyy').format(controller.filterFromDate.value!)
                                          : "From Date",
                                      style: TextStyle(
                                        color: controller.filterFromDate.value != null ? Colors.black : Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectFilterDate(context, false, setModalState),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: FlavorConfig.instance.primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.filterToDate.value != null
                                          ? DateFormat('dd-MMM-yyyy').format(controller.filterToDate.value!)
                                          : "To Date",
                                      style: TextStyle(
                                        color: controller.filterToDate.value != null ? Colors.black : Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Approval Status Section
                    const Text(
                      "Approval Status",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text("All"),
                            selected: !showPendingOnly,
                            onSelected: (val) {
                              setModalState(() => showPendingOnly = false);
                              setState(() => showPendingOnly = false);
                            },
                            selectedColor: FlavorConfig.instance.primaryColor.withOpacity(0.15),
                            labelStyle: TextStyle(color: !showPendingOnly ? FlavorConfig.instance.primaryColor : Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Text("Pending"),
                            selected: showPendingOnly,
                            onSelected: (val) {
                              setModalState(() => showPendingOnly = true);
                              setState(() => showPendingOnly = true);
                            },
                            selectedColor: FlavorConfig.instance.primaryColor.withOpacity(0.15),
                            labelStyle: TextStyle(color: showPendingOnly ? FlavorConfig.instance.primaryColor : Colors.black),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                controller.filterFromDate.value = null;
                                controller.filterToDate.value = null;
                              });
                              setState(() {
                                showPendingOnly = false;
                              });
                              controller.refreshWeeklyDetails();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: BorderSide(color: FlavorConfig.instance.primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Reset", style: TextStyle(color: FlavorConfig.instance.primaryColor)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              controller.refreshWeeklyDetails();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlavorConfig.instance.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Apply Filter", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // void _filterPendingEntries() {
  //   setState(() {
  //     showPendingOnly = !showPendingOnly;
  //   });
  // }

  Widget _buildTourCard(dynamic tour, int index) {
    // Extract data from API response
    String dealerName = tour['DealerName'] ??
        tour['customerName'] ??
        tour['DealerName'] ??
        'Unknown Dealer';
    String location = tour['Area'] ??
        tour['district'] ??
        tour['location'] ??
        tour['Area'] ??
        'Unknown Location';
    String rawDate = tour['date'] ?? tour['tourDate'] ?? tour['Date'] ?? tour['Dt'] ?? '';
    String formattedDate = _formatDate(rawDate);
    
    // Safely check for empty string values as ?? only coalesces null
    String personName = (tour['Name'] != null && tour['Name'].toString().trim().isNotEmpty)
        ? tour['Name'].toString()
        : (tour['Name1'] != null && tour['Name1'].toString().trim().isNotEmpty)
            ? tour['Name1'].toString()
            : (tour['contactPerson'] != null && tour['contactPerson'].toString().trim().isNotEmpty)
                ? tour['contactPerson'].toString()
                : (tour['PersonName'] != null && tour['PersonName'].toString().trim().isNotEmpty)
                    ? tour['PersonName'].toString()
                    : 'Unknown';

    String dealerType = tour['DealerCategory'] ??
        tour['dealerCategory'] ??
        tour['DealerType'] ??
        'Unknown Type';

    String phone = (tour['MobileNo'] != null && tour['MobileNo'].toString().trim().isNotEmpty)
        ? tour['MobileNo'].toString()
        : (tour['MobileNo1'] != null && tour['MobileNo1'].toString().trim().isNotEmpty)
            ? tour['MobileNo1'].toString()
            : 'N/A';

    String startTime = _formatDateTime(tour['startTime'] ?? tour['StartTime'] ?? '00:00 AM');
    String endTime = _formatDateTime(tour['endTime'] ?? tour['EndTime'] ?? '00:00 PM');
    String fromPlace = tour['fromPlace'] ?? tour['FromPlace'] ?? 'Unknown';
    String toPlace = tour['toPlace'] ?? tour['ToPlace'] ?? 'Unknown';

    bool isPending = _isTourPending(tour);

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$dealerName - $location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.calendar_today, formattedDate),
                _buildDetailRow(Icons.person, personName),
                _buildDetailRow(Icons.business_center, dealerType),
                _buildDetailRow(Icons.phone, phone),
                const Divider(height: 20, thickness: 1),
                _buildCheckInOutItem(fromPlace, startTime, isCheckedIn: true),
                _buildCheckInOutItem(toPlace, endTime, isCheckedIn: false),

                // Status indicator
              ],
            ),
          ),
        ],
      ),
    );
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
          'Daily Tour Details',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
        ),

        actions: [
          IconButton(
            icon: Icon(
              showPendingOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: FlavorConfig.instance.appBarForegroundColor,
            ),


            onPressed: _filterPendingEntries,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Filter',
                style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontSize: 16),
              ),
            ),
          ),
        ],

        // actions: [
        //   IconButton(
        //     icon: Icon(
        //         showPendingOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
        //         color: Colors.white),
        //     onPressed: _filterPendingEntries,
        //   ),
        //   const Padding(
        //     padding: EdgeInsets.only(right: 16.0),
        //     child: Center(
        //       child: Text(
        //         'Filter',
        //         style: TextStyle(color: Colors.white, fontSize: 16),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: Obx(() {
        if (controller.isLoadingWeeklyDetails.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(FlavorConfig.instance.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text('Loading all tour details...'),
              ],
            ),
          );
        }

        if (controller.weeklyDetailsMessage.value.contains('server limit')) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Server Limit Reached',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Tour data is too large to display.\nPlease contact administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchWeeklyDetailsForDisplay(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (controller.weeklyDetailsData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No Tours Found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pull down to refresh or add a new tour',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchWeeklyDetailsForDisplay(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        List<dynamic> displayTours = controller.weeklyDetailsData.reversed.toList();

        // Apply Date Range Filter locally
        if (controller.filterFromDate.value != null || controller.filterToDate.value != null) {
          displayTours = displayTours.where((tour) {
            String rawDate = tour['date'] ?? tour['tourDate'] ?? tour['Date'] ?? tour['Dt'] ?? '';
            if (rawDate.isEmpty) return false;
            
            String cleanDate = rawDate;
            if (cleanDate.contains(' ')) {
              cleanDate = cleanDate.split(' ').first;
            }

            DateTime? tourDate;
            List<String> possibleFormats = [
              'dd-MMM-yyyy',
              'M/d/yyyy',
              'MM/dd/yyyy',
              'dd/MM/yyyy',
              'yyyy-MM-dd',
              'MM-dd-yyyy',
              'dd MMMM yyyy',
            ];
            for (String format in possibleFormats) {
              try {
                tourDate = DateFormat(format).parse(cleanDate);
                break;
              } catch (e) {}
            }
            
            if (tourDate == null) return false;
            
            DateTime tourDay = DateTime(tourDate.year, tourDate.month, tourDate.day);
            
            bool isAfterFrom = true;
            if (controller.filterFromDate.value != null) {
               DateTime fromD = controller.filterFromDate.value!;
               DateTime fromDay = DateTime(fromD.year, fromD.month, fromD.day);
               isAfterFrom = tourDay.isAfter(fromDay) || tourDay.isAtSameMomentAs(fromDay);
            }
            
            bool isBeforeTo = true;
            if (controller.filterToDate.value != null) {
               DateTime toD = controller.filterToDate.value!;
               DateTime toDay = DateTime(toD.year, toD.month, toD.day);
               isBeforeTo = tourDay.isBefore(toDay) || tourDay.isAtSameMomentAs(toDay);
            }
            
            return isAfterFrom && isBeforeTo;
          }).toList();
        }

        if (showPendingOnly) {
          displayTours = displayTours.where(_isTourPending).toList();
        }

        // Count pending tours
        int pendingCount =
            controller.weeklyDetailsData.where(_isTourPending).length;
        int completedCount = controller.weeklyDetailsData.length - pendingCount;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshWeeklyDetails(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: displayTours.length,
                  itemBuilder: (context, index) {
                    return _buildTourCard(displayTours[index], index);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CreateEditTourScreen());
        },
        backgroundColor: FlavorConfig.instance.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
