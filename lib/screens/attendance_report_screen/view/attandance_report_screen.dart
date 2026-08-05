import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/screens/attendance_report_screen/view_model/attendance_report_screen_controller.dart';

import '../../../constant/local_db/local_db.dart';
import '../../../flavor_config.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final AttendanceReportScreenController controller =
      Get.put(AttendanceReportScreenController());

  late final TextEditingController monthController;

  String? selectedMonth = '';
  List<String> statusList = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var userName = ''.obs;


  @override
  void initState() {

    monthController = TextEditingController();

    final String defaultMonth =
    DateFormat('MMM yyyy').format(DateTime.now());

    fetchMonthList(defaultMonth);
    loadUserName();
    super.initState();
  }

  Future<void> loadUserName() async {
    userName.value = LocalDbController.to.usersName;
  }

  Future<void> fetchMonthList(String? defaultMonth) async {
    try {
      final response = await controller.getMonthList();

      final months =
      response.result!.map((e) => e.month.toString()).toList();

      setState(() {
        statusList = months;
        isLoading = false;

        if (defaultMonth != null && months.contains(defaultMonth)) {
          selectedMonth = defaultMonth;
        } else if (months.isNotEmpty) {
          selectedMonth = months.first;
        }

        // 🔥 THIS IS THE KEY LINE
        monthController.text = selectedMonth ?? '';
      });

      if (selectedMonth != null && selectedMonth!.isNotEmpty) {
        await controller.fetchLastAttandances(selectedMonth!);
      }
    } catch (e) {
      isLoading = false;
    }
  }



  // Future<void> fetchMonthList(String? month) async {
  //   try {
  //     final response = await controller.getMonthList();
  //
  //     setState(() {
  //       // Map 'Text' field from each object in 'result'
  //       statusList = response.result!.map((e) => e.month.toString()).toList();
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     print("Error fetching month list: $e");
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: Text(
          'Attendance Report',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
        centerTitle: false,
        actions: const [],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.black, size: 24), // The location pin icon
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => _buildStatusBottomSheet(context),
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Select Month",
                          border: InputBorder.none,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        controller:monthController,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // A separator line, though not strictly in the image, helps organization.
          const Divider(height: 2, thickness: 1),

          Obx(() {
             if (controller.isLoading.value) {
              // Show loader while fetching
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: FlavorConfig.instance.tableColor),
                ),
              );
            }

            if (controller.lastAttendances.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No attendance data yet."),
                ),
              );
            }

            return Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SafeArea(
                  maintainBottomViewPadding: true,
                  child: Column(
                    children: [
                      // Unified Table Card with Rounded Corners and Shadow
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: FlavorConfig.instance.primaryColor.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                              color: FlavorConfig.instance.primaryColor.withOpacity(0.15)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Header row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: FlavorConfig.instance.primaryColor,
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 2,
                                    child: Text("Name",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text("In Time",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  SizedBox(
                                    width: 54,
                                    child: Text("Status",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text("Out Time",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            // Records List
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: controller.lastAttendances.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: FlavorConfig.instance.primaryColor.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final item = controller.lastAttendances[index];
                            final isEven = index % 2 == 0;
                            final statusColor = _singlaStatusColor(item.status ?? '');
                            return Container(
                              color: isEven
                                  ? Colors.white
                                  : FlavorConfig.instance.primaryColor.withOpacity(0.03),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      userName.value,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.inTime ?? '—',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 54,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.status ?? '—',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.outTime ?? '—',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );

          })
        ],
      ),
    );
  }

  Widget _buildStatusBottomSheet(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statusList.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final status = statusList[index];
                  return ListTile(
                    title: Text(status),
                    onTap: () async {
                      setState(() {
                        selectedMonth = status;
                        monthController.text = status;
                      });

                      Navigator.pop(context);

                      await controller.fetchLastAttandances(status);
                    },

                    // onTap: () {
                    //   setState(() {
                    //     selectedMonth = status;
                    //   });
                    //   Navigator.pop(context);
                    // },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  // Color _singlaStatusColor(String status) {
  //   switch (status.toUpperCase()) {
  //     case 'P':
  //       return Colors.green.shade600;
  //     case 'A':
  //       return Colors.red.shade600;
  //     case 'H':
  //       return Colors.orange.shade600;
  //     case 'L':
  //       return Colors.blue.shade600;
  //     default:
  //       return Colors.grey.shade600;
  //   }
  // }
}
  Color _singlaStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'P':
        return Colors.green.shade600;
      case 'A':
        return Colors.red.shade600;
      case 'H':
        return Colors.orange.shade600;
      case 'L':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }}
