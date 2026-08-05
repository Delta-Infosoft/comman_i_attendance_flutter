import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/model/project_journey_model.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/widget/bottom_sheet.dart';
import '../viewmodel/Project_journey_controller.dart';
import 'create_project_journey_cycle.dart';
import '../../../flavor_config.dart';

class JourneyCalendarScreen extends StatefulWidget {
  const JourneyCalendarScreen({super.key});

  @override
  State<JourneyCalendarScreen> createState() => _JourneyCalendarScreenState();
}

class _JourneyCalendarScreenState extends State<JourneyCalendarScreen> {
  final JourneyCycleController journeyController =
      Get.find<JourneyCycleController>();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    print('Calendar Screen Initialized');
    _initializeData();
  }

  void _initializeData() async {
    try {
      // STEP 1: Fetch back-dated rights when screen opens
      print('Step 1: Fetching Back-Dated Rights...');
      await journeyController.fetchBackDatedRights();

      // STEP 2: Fetch PJC data for calendar
      print('Step 2: Fetching PJC Data for calendar...');
      final mobileNo = _getUserMobileNumber();
      if (mobileNo.isNotEmpty) {
        await journeyController.fetchPJCData(mobileNo, _focusedDay);
      }

      print('All initial APIs called successfully');
    } catch (e) {
      print('Error in _initializeData: $e');
    }
  }

  String _getUserMobileNumber() {
    try {
      final localDb = LocalDbController.to;
      if (!localDb.loggedIn) {
        return '';
      }
      final mobileNo = localDb.mobileNo;
      return mobileNo.isNotEmpty ? mobileNo : '';
    } catch (e) {
      return '';
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      _loadPJCData();
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      _loadPJCData();
    });
  }

  void _loadPJCData() {
    final mobileNo = _getUserMobileNumber();
    if (mobileNo.isNotEmpty) {
      journeyController.fetchPJCData(mobileNo, _focusedDay);
    }
  }

  void _onDateSelected(DateTime date) {
    print('Date Selected: $date');

    // Call PJC Event API when date is selected
    final mobileNo = _getUserMobileNumber();
    if (mobileNo.isNotEmpty) {
      print('Calling PJC Event API for selected date...');
      journeyController.fetchPJCEventData(mobileNo, date);
    }

    final events = journeyController.getEventsForDate(date);
    _showEventDetailSheet(date, events);
  }

  Widget _buildDaysOfWeekHeader() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: days
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }

  void _showEventDetailSheet(DateTime date, List<PJCData> events) {
    print('Showing bottom sheet for date: $date with ${events.length} events');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return PJCBottomSheet(
          date: date,
          pjcEvents: events,
        );
      },
    ).whenComplete(() {
      print('Bottom sheet closed');
    });
  }

  Widget _buildDayCell(DateTime date) {
    return Obx(() {
      final events = journeyController.getEventsForDate(date);
      final hasEvents = events.isNotEmpty;

      return GestureDetector(
        onTap: () => _onDateSelected(date),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            color: date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year
                ? FlavorConfig.instance.primaryColor.withOpacity(0.1)
                : Colors.white,
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: date.month != _focusedDay.month
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (hasEvents)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length > 2 ? 2 : events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 1),
                        decoration: BoxDecoration(
                          color: FlavorConfig.instance.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          event.place.isNotEmpty ? event.place : 'Journey Plan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                )
              else
                const Spacer(),
              if (events.length > 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '+${events.length - 2} more',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 7,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startDay =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    const totalDays = 42;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: FlavorConfig.instance.appBarColor,
          bottom: FlavorConfig.instance.getAppBarBottom(),
          leading: FlavorConfig.instance.getAppBarLeading(context),
          title: Text(
            'Project Journey Cycle',
            style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
          ),
        ),
        body: Obx(() {
          if (journeyController.isLoading.value) {
            return Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FlavorConfig.instance.primaryColor),
            ),);
          }

          return Column(
            children: [
              // Month Navigation Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: FlavorConfig.instance.flavor == AppFlavor.singla
                      ? FlavorConfig.instance.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: FlavorConfig.instance.flavor == AppFlavor.singla
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: FlavorConfig.instance.flavor == AppFlavor.singla
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      '${DateFormat.MMM().format(_focusedDay)} ${_focusedDay.year}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: FlavorConfig.instance.flavor == AppFlavor.singla
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: FlavorConfig.instance.flavor == AppFlavor.singla
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

              // Date restrictions info
              if (journeyController.backDatedRights.value != null)
                if(FlavorConfig.instance.isWaterman)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'You can select dates from today to next ${journeyController.allowedDays} days',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Day of the Week Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildDaysOfWeekHeader(),
              ),

              // Calendar Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: totalDays,
                    itemBuilder: (context, index) {
                      final currentDate = startDay.add(Duration(days: index));
                      return _buildDayCell(currentDate);
                    },
                  ),
                ),
              ),
            ],
          );
        }),
        // In project_journey_cycle.dart - FAB onPressed
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('Navigating to Create Journey Screen...');
            Get.to(() => const CreateJourneyScreen())?.then((result) {
              if (result == true) {
                print(
                    'Returned from Create screen with success, refreshing data...');
                final mobileNo = _getUserMobileNumber();
                if (mobileNo.isNotEmpty) {
                  journeyController.fetchPJCData(mobileNo, _focusedDay);
                }
              }
            });
          },
          backgroundColor: FlavorConfig.instance.primaryColor,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
