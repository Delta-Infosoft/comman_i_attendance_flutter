// tour_voucher_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterman_iattandance/screens/TourVoucharApproval/model/tour_vouchar_model.dart';
import 'package:waterman_iattandance/screens/TourVoucharApproval/viewmodel/tour_vouchar_controller.dart';
import '../../../flavor_config.dart';

class TourVoucherApprovalScreen extends StatefulWidget {
  final String mobileNo; // Pass mobile number from login

  const TourVoucherApprovalScreen({super.key, required this.mobileNo});

  @override
  State<TourVoucherApprovalScreen> createState() =>
      _TourVoucherApprovalScreenState();
}

class _TourVoucherApprovalScreenState extends State<TourVoucherApprovalScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current date or empty
    final String initialFrom = _formatDate(DateTime.now());
    final String initialTo = _formatDate(DateTime.now());
    _fromDateController.text = initialFrom;
    _toDateController.text = initialTo;

    // Push initial dates to controller so search validation passes immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseController =
          Provider.of<TourExpenseController>(context, listen: false);
      expenseController.updateSelectedDates(initialFrom, initialTo);
    });
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${_getMonthAbbreviation(date.month)}-${date.year}";
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

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = _formatDate(picked);
      });
      // Update dates in controller
      final expenseController =
          Provider.of<TourExpenseController>(context, listen: false);
      expenseController.updateSelectedDates(
          _fromDateController.text, _toDateController.text);
    }
  }

  void _fetchData(BuildContext context) {
    final controller =
        Provider.of<TourExpenseController>(context, listen: false);
    controller.updateSelectedDates(
        _fromDateController.text, _toDateController.text);
    controller.fetchTourExpenseData(widget.mobileNo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        elevation: 0,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        centerTitle: false,
        title: Text(
          "Tour Voucher Approval",
          style: TextStyle(
            color: FlavorConfig.instance.appBarForegroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: FlavorConfig.instance.getAppBarLeading(context),
      ),
      body: ChangeNotifierProvider(
        create: (context) => TourExpenseController(),
        child: Consumer<TourExpenseController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE FILTER BAR
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FILTER ROW WITH SEARCH BUTTON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_drop_down,
                                    size: 35, color: Colors.black87),
                                SizedBox(width: 4),
                                Text(
                                  "Filter",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FlavorConfig.instance.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                              ),
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _fetchData(context),
                              child: controller.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      "Search",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // FROM & TO DATE ROW
                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                controller: _fromDateController,
                                label: "from date",
                                onTap: () =>
                                    _selectDate(context, _fromDateController),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateField(
                                controller: _toDateController,
                                label: "to date",
                                onTap: () =>
                                    _selectDate(context, _toDateController),
                              ),
                            ),
                          ],
                        ),

                        // ERROR MESSAGE
                        if (controller.errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              controller.errorMessage,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LOADING INDICATOR
                  if (controller.isLoading)
                     Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(FlavorConfig.instance.primaryColor),
                        ),
                      ),
                    ),

                  // TOUR EXPENSE CARDS
                  if (!controller.isLoading &&
                      controller.tourExpenses.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.tourExpenses.length,
                      itemBuilder: (context, index) {
                        return _voucherCardUI(
                          controller.tourExpenses[index],
                          index,
                          controller,
                        );
                      },
                    ),

                  // NO DATA MESSAGE
                  if (!controller.isLoading &&
                      controller.tourExpenses.isEmpty &&
                      controller.errorMessage.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          "No tour expense data found for selected dates",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                Text(
                  controller.text.isEmpty ? "Select date" : controller.text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _voucherCardUI(TourExpenseModel expense, int index,
      TourExpenseController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    formatApiDate(expense.fromDate,'dd-MMM-yyyy'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_right_alt_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    formatApiDate(expense.toDate,'dd-MMM-yyyy'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     Flexible(
            //       child: Text(
            //         expense.fromDate,
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 17,
            //           fontWeight: FontWeight.w500,
            //         ),
            //         overflow: TextOverflow.ellipsis,
            //       ),
            //     ),
            //     const SizedBox(width: 4),
            //     const Icon(
            //       Icons.arrow_right_alt_outlined,
            //       color: Colors.white,
            //       size: 24,
            //     ),
            //     const SizedBox(width: 4),
            //     Flexible(
            //       child: Text(
            //         expense.toDate,
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 17,
            //           fontWeight: FontWeight.w500,
            //         ),
            //         overflow: TextOverflow.ellipsis,
            //       ),
            //     ),
            //   ],
            // ),
          ),

          const SizedBox(height: 10),

          // PERSON ROWS
          if (expense.persons.isNotEmpty)
            ...expense.persons.asMap().entries.map((entry) {
              final idx = entry.key;
              final person = entry.value;
              return _personRowUI(
                name: person.name,
                time: formatApiDate(person.time,'hh:mm a'),
                showLine: idx < expense.persons.length - 1,
              );
            }).toList(),

          const Divider(height: 25, thickness: 1),

          // TRANSPORT ROW
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 14),
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 30,
          //         height: 30,
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.circular(6),
          //           color: Colors.grey.shade200,
          //         ),
          //         alignment: Alignment.center,
          //         child: const Icon(
          //           Icons.directions_bike_sharp,
          //           size: 20,
          //           color: Colors.black87,
          //         ),
          //       ),
          //       const SizedBox(width: 10),
          //       Text(expense.transportType,
          //           style: const TextStyle(fontSize: 15)),
          //     ],
          //   ),
          // ),
          //
          // const SizedBox(height: 18),

          // TOTAL ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(
                        Icons.directions_bike_sharp,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      expense.transportType,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),

                Text(
                  "Total : ${double.tryParse(expense.totalAmount)?.toStringAsFixed(2)} ₹",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FlavorConfig.instance.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // STATUS DROPDOWN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Status",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: ['Approved', 'Disapproved'].contains(expense.status)
                      ? expense.status
                      : null,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text("Select Status"),
                  items: ['Approved', 'Disapproved'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      controller.updateExpenseStatus(index, newValue);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // REMARKS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "remarks: ${expense.remarks}",
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),

          const SizedBox(height: 10),

          // SUBMIT BUTTON
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FlavorConfig.instance.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: controller.isLoading
                  ? null
                  : () {
                      controller.submitTourApproval(index);
                    },
              child: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "SUBMIT",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _personRowUI({
    required String name,
    required String time,
    bool showLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDE: Circle
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // RIGHT SIDE: Name - Time
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Text(
              "$name  -  $time",
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  String formatApiDate(String? dateStr ,String format11) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';

    final formats = [
      "MM/dd/yyyy hh:mm:ss a",
      "M/d/yyyy hh:mm:ss a",
      "M/d/yyyy HH:mm:ss",
      "dd/MMM/yyyy HH:mm:ss a",
      "dd-MMM-yyyy HH:mm:ss a",
      "dd/MMM/yyyy hh:mm:ss a",
    ];

    for (final format in formats) {
      try {
        final parsed = DateFormat(format).parseStrict(dateStr);
        return DateFormat(format11).format(parsed);
      } catch (_) {}
    }

    return dateStr; // fallback original if parsing fails
  }
}
// import 'package:flutter/material.dart';

// class TourVoucherApprovalScreen extends StatelessWidget {
//   const TourVoucherApprovalScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color(0xfff23a2e),
//         elevation: 0,
//         centerTitle: false,
//         title: const Text(
//           "Tour Voucher Approval",
//           style: TextStyle(
//               color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {},
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // DATE FILTER BAR
//             Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 12),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 4,
//                       offset: const Offset(0, 1),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ---------------- TOP RIGHT FILTER ----------------
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: const [
//                         Icon(Icons.arrow_drop_down,
//                             size: 35, color: Colors.black87),
//                         SizedBox(width: 4),
//                         Text(
//                           "Filter",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.black54,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),

//                     // const SizedBox(height: 12),

//                     // ---------------- FROM & TO DATE ROW ----------------
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _dateField(
//                             label: "from date",
//                             date: "01-Nov-2025",
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _dateField(
//                             label: "to date",
//                             date: "22-Nov-2025",
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 )),

//             const SizedBox(height: 16),

//             // VOUCHER CARD
//             _voucherCardUI(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dateField({required String label, required String date}) {
//     return Container(
//       width: 130,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.calendar_today, size: 20),
//           const SizedBox(width: 6),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label,
//                   style: const TextStyle(fontSize: 12, color: Colors.black45)),
//               Text(date,
//                   style: const TextStyle(
//                       fontSize: 14, fontWeight: FontWeight.w600)),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Widget _voucherCardUI() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       padding: EdgeInsets.zero,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 6,
//               offset: const Offset(0, 2))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // CARD HEADER
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: const BoxDecoration(
//               color: Color(0xfff23a2e),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: const [
//                 Text(
//                   "18-Nov-2025",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Icon(
//                   Icons.arrow_right_alt_outlined, // THIS MAKES THE → ARROW
//                   color: Colors.white,
//                   size: 30,
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   "18-Nov-2025",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // PERSON ROWS
//           _personRowUI(name: "Ahmd", time: "11:33 AM", showLine: true),
//           _personRowUI(name: "Pln", time: "11:37 AM", showLine: false),

//           const Divider(height: 25, thickness: 1),

//           // BIKE ROW
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             child: Row(
//               children: [
//                 Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(6),
//                     color: Colors.grey.shade200,
//                   ),
//                   alignment: Alignment.center,
//                   child: const Icon(Icons.directions_bike_sharp,
//                       size: 20, color: Colors.black87),
//                 ),
//                 const SizedBox(width: 10),
//                 const Text("Bike", style: TextStyle(fontSize: 15)),
//               ],
//             ),
//           ),

//           const SizedBox(height: 18),

//           // TOTAL ROW
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: const [
//                 Text(
//                   "Total : 60 ₹",
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xfff23a2e)),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 14),

//           // STATUS
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 14),
//             child: InkWell(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("status",
//                       style: TextStyle(fontSize: 15, color: Colors.black54)),
//                   Icon(Icons.keyboard_arrow_down, color: Colors.red, size: 28)
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // REMARKS
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 14),
//             child: Text("remarks",
//                 style: TextStyle(fontSize: 15, color: Colors.black54)),
//           ),

//           const SizedBox(height: 10),

//           // SUBMIT BUTTON
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xfff23a2e),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(6)),
//               ),
//               onPressed: () {},
//               child: const Text(
//                 "SUBMIT",
//                 style: TextStyle(
//                     fontSize: 17,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _personRowUI({
//     required String name,
//     required String time,
//     bool showLine = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // LEFT SIDE: Circle + dotted line
//           Column(
//             children: [
//               // Circle (0)
//               Container(
//                 width: 14,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   shape: BoxShape.circle,
//                 ),
//               ),

//               // // Dotted Line (only when showLine = true)
//               // if (showLine)
//               //   Container(
//               //     width: 1,
//               //     height: 20,
//               //     decoration: const BoxDecoration(
//               //       border: Border(
//               //         right: BorderSide(
//               //           color: Colors.grey,
//               //           width: 1,
//               //           style: BorderStyle.solid,
//               //         ),
//               //       ),
//               //     ),
//               //   ),
//             ],
//           ),

//           const SizedBox(width: 12),

//           // RIGHT SIDE: Name - Time
//           Padding(
//             padding: const EdgeInsets.only(top: 0),
//             child: Text(
//               "$name  -  $time",
//               style: const TextStyle(fontSize: 15),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
