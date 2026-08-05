import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waterman_iattandance/screens/home/view/home_screen.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/tour_voucher_screen_model.dart';
import 'package:waterman_iattandance/screens/tour_voucher/view/insert_tour_voucher_screen.dart';
import 'package:waterman_iattandance/screens/tour_voucher/viewmodel/tour_voucher_screen_controller.dart';
import 'package:waterman_iattandance/screens/tour_voucher/view/edit_tour_voucher_screen.dart';
import 'package:waterman_iattandance/screens/webviews/common_web_view.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../../../flavor_config.dart';

class TourVoucherScreen extends StatefulWidget {
  const TourVoucherScreen({super.key});

  @override
  State<TourVoucherScreen> createState() => _TourVoucherScreenState();
}

class _TourVoucherScreenState extends State<TourVoucherScreen> {
  final TourVoucherController _controller = Get.put(TourVoucherController());

  @override
  void initState() {
    super.initState();
    // Reset dates to null (cleared state) when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fromDate.value = null;
      _controller.toDate.value = null;
      _controller.fetchTourVouchers();
    });
  }

  // --- Date Picker Helper - Allow all past and future dates ---
  Future<void> _selectDate(BuildContext context,
      {required bool isFromDate}) async {
    try {
      // Get current date
      final DateTime? currentDate =
          isFromDate ? _controller.fromDate.value : _controller.toDate.value;

      // Set date range - allow ALL dates (past and future)
      final DateTime firstDate = DateTime(2000, 1, 1); // Very old date
      final DateTime lastDate = DateTime(2100, 12, 31); // Very future date

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: currentDate ?? DateTime.now(),
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: FlavorConfig.instance.primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style:
                    TextButton.styleFrom(foregroundColor: FlavorConfig.instance.primaryColor),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        if (isFromDate) {
          _controller.updateFromDate(picked);
        } else {
          _controller.updateToDate(picked);
        }
      }
    } catch (e) {
      AppSnackBar.error('Error', 'Failed to select date: $e');
    }
  }

  // --- Custom Date Input Widget ---
  Widget _buildDateInput({required bool isFromDate}) {
    final DateTime? date =
        isFromDate ? _controller.fromDate.value : _controller.toDate.value;
    final String label = isFromDate ? 'from date' : 'to date';

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, isFromDate: isFromDate),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              date != null ? DateFormat('dd-MMM-yyyy').format(date) : 'Select Date',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  if (isFromDate) {
                    _controller.fromDate.value = null;
                  } else {
                    _controller.toDate.value = null;
                  }
                  _controller.fetchTourVouchers();
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Voucher Card Widget ---
  Widget _buildVoucherCard(TourVoucherModel voucher) {
    final DateTime? startDate =
        voucher.travelDt != null && voucher.travelDt!.isNotEmpty
            ? _controller.parseApiDate(voucher.travelDt!)
            : null;

    final DateTime? endDate =
        voucher.travelToDt != null && voucher.travelToDt!.isNotEmpty
            ? _controller.parseApiDate(voucher.travelToDt!)
            : startDate;

    final startTime = _controller.parseApiTime(voucher.startTime!) ?? 'N/A';
    final endTime = _controller.parseApiTime(voucher.endTime!) ?? 'N/A';
    final totalAmount = double.tryParse(voucher.totalExpenses ?? '0') ?? 0;
    final totalAmountText = 'Total : ₹${totalAmount.toStringAsFixed(2)}';

    final DateFormat formatter = DateFormat('dd-MMM-yyyy');
    final isSingla = FlavorConfig.instance.isSingla;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Date Range and Status)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${startDate != null ? formatter.format(startDate) : 'N/A'} '
                  '→ ${endDate != null ? formatter.format(endDate) : 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isSingla)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(voucher.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      voucher.status ?? 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Info
                if (!isSingla) ...[
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          voucher.name ?? ' ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Times and Places
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Custom Check/Radio style indicator or timeline capsule for Singla
                     if (isSingla)
                       Container(
                         margin: const EdgeInsets.only(right: 12.0, top: 4),
                         width: 16,
                         height: 38,
                         decoration: BoxDecoration(
                           color: Colors.grey.shade700,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: [
                             Container(
                               width: 6,
                               height: 6,
                               decoration: const BoxDecoration(
                                 color: Colors.white,
                                 shape: BoxShape.circle,
                               ),
                             ),
                             Container(
                               width: 6,
                               height: 6,
                               decoration: const BoxDecoration(
                                 color: Colors.white,
                                 shape: BoxShape.circle,
                               ),
                             ),
                           ],
                         ),
                       )
                     else
                       Container(
                         margin: const EdgeInsets.only(right: 12.0, top: 2),
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border:
                               Border.all(color: Colors.grey.shade400, width: 2),
                           color: Colors.transparent,
                         ),
                       ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlaceTimeRow(
                              voucher.fromPlace ?? ' ', startTime),
                          _buildPlaceTimeRow(voucher.toPlace ?? ' ', endTime),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Transport and Night Hault
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSingla ? Icons.location_on_outlined : Icons.directions_bus,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              voucher.travellingBy ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (!isSingla) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Night Hault: ${voucher.nighHault == 'True' ? 'Yes' : 'No'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                if (!isSingla) ...[
                  const SizedBox(height: 12),
                  // Expense Breakdown
                  if (double.tryParse(voucher.fareAmount ?? '0') != null &&
                      double.parse(voucher.fareAmount!) > 0)
                    _buildExpenseRow('Fare', voucher.fareAmount!),
                  if (double.tryParse(voucher.dailyAllowance ?? '0') != null &&
                      double.parse(voucher.dailyAllowance!) > 0)
                    _buildExpenseRow('Food Allowance', voucher.dailyAllowance!),
                  if (double.tryParse(voucher.lodging ?? '0') != null &&
                      double.parse(voucher.lodging!) > 0)
                    _buildExpenseRow('Lodging', voucher.lodging!),
                  if (double.tryParse(voucher.otherExpenses ?? '0') != null &&
                      double.parse(voucher.otherExpenses!) > 0)
                    _buildExpenseRow('Other', voucher.otherExpenses!),
                ],

                const SizedBox(height: 12),

                // Actions and Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action Buttons (Report, Edit)
                    Row(
                      children: [
                        if (voucher.tourReport != null &&
                            voucher.tourReport!.isNotEmpty)
                          _buildActionButton(
                            isSingla ? Icons.visibility_off : Icons.picture_as_pdf_outlined,
                            'Report',
                            () async {
                              String reportUrl = voucher.tourReport!;
                              // Fix encoding issues (u0026 -> &)
                              reportUrl = reportUrl.replaceAll('u0026', '&');
                              
                              // Check if it's a Crystal Report viewer and try to force PDF
                              if (reportUrl.contains('CRViewer.aspx') && !reportUrl.contains('ExportType=')) {
                                reportUrl += '&ExportType=PDF';
                              }

                              final Uri url = Uri.parse(reportUrl);

                              // Use inAppBrowserView for better native support of PDFs and complex reports
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                AppSnackBar.error('Error', 'Could not open report in-app');
                              }
                            },
                          ),
                        if (voucher.tourReport != null &&
                            voucher.tourReport!.isNotEmpty)
                          const SizedBox(width: 16),
                        // Only show Edit button for vouchers that are not approved/rejected
                        if (voucher.status?.toLowerCase() != 'approved' &&
                            voucher.status?.toLowerCase() != 'rejected' &&
                            voucher.status?.toLowerCase() != 'disapproved')
                          _buildActionButton(
                            Icons.edit,
                            'Edit',
                            () {
                              _controller.setSelectedVoucher(voucher);
                              Get.to(() => EditTourVoucherScreen(
                                    voucher: voucher,
                                  ));
                            },
                          ),
                      ],
                    ),

                    // Total Amount and Open Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isSingla ? 'Total : ${totalAmount.toInt()} ₹' : totalAmountText,
                          style: TextStyle(
                            fontSize: isSingla ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: FlavorConfig.instance.primaryColor,
                          ),
                        ),
                        if (isSingla) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(voucher.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              voucher.status ?? 'Pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (!isSingla) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _showVoucherDetails(voucher);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.yellow.shade800,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Details',
                                style:
                                    TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(String label, String amount) {
    final double value = double.tryParse(amount) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 14)),
          Text('₹${value.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'open':
        return Colors.yellow.shade800;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'disapproved':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  void _showVoucherDetails(TourVoucherModel voucher) {
    Get.dialog(
      AlertDialog(
        title: const Text('Voucher Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee', voucher.name ?? 'N/A'),
              _buildDetailRow('Designation', voucher.designation ?? 'N/A'),
              _buildDetailRow('From Place', voucher.fromPlace ?? 'N/A'),
              _buildDetailRow('To Place', voucher.toPlace ?? 'N/A'),
              _buildDetailRow('Travel By', voucher.travellingBy ?? 'N/A'),
              _buildDetailRow('Status', voucher.status ?? 'N/A'),
              _buildDetailRow('Fare Amount', '₹${voucher.fareAmount ?? '0'}'),
              _buildDetailRow(
                  'Food Allowance', '₹${voucher.dailyAllowance ?? '0'}'),
              _buildDetailRow('Lodging', '₹${voucher.lodging ?? '0'}'),
              _buildDetailRow(
                  'Other Expenses', '₹${voucher.otherExpenses ?? '0'}'),
              _buildDetailRow('Auto Charges', '₹${voucher.autoCharges ?? '0'}'),
              _buildDetailRow('Total', '₹${voucher.totalExpenses ?? '0'}'),
              _buildDetailRow(
                  'Night Hault', voucher.nighHault == 'True' ? 'Yes' : 'No'),
              if (voucher.autoChargesDetail?.isNotEmpty == true)
                _buildDetailRow(
                    'Auto Charges Detail', voucher.autoChargesDetail!),
              if (voucher.otherChargesDetail?.isNotEmpty == true)
                _buildDetailRow(
                    'Other Charges Detail', voucher.otherChargesDetail!),
              if (voucher.tourReport != null && voucher.tourReport!.isNotEmpty)
                _buildDetailRow('Report URL', voucher.tourReport!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Place and Time line
  Widget _buildPlaceTimeRow(String place, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(place,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
          Text(time,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // Helper for Report/Edit buttons
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
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
        leading: FlavorConfig.instance.getAppBarLeading(
          context,
          onPressed: () => Get.to(HomeScreen()),
        ),
        title: Text(
          'Tour Voucher',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: FlavorConfig.instance.appBarForegroundColor),
            onPressed: () {
              _controller.fetchTourVouchers();
            },
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // Always show Date Range & Filter (even when loading/error/no data)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildDateInput(isFromDate: true),
                  const SizedBox(width: 8),
                  _buildDateInput(isFromDate: false),
                ],
              ),
            ),

            // Main content area - shows different states
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        );
      }),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(const CreateTourVoucherScreen());
        },
        backgroundColor: FlavorConfig.instance.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_controller.isLoading.value) {
      return _buildLoadingState();
    }

    if (_controller.errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_controller.tourVouchers.isEmpty) {
      return _buildEmptyState();
    }

    return _buildVoucherList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FlavorConfig.instance.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading tour vouchers...',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_controller.formatDateForDisplay(_controller.fromDate.value)} - ${_controller.formatDateForDisplay(_controller.toDate.value)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(Icons.error_outline, color: Colors.red, size: 64),
            // const SizedBox(height: 16),
            // Text(
            //   'Something Went Wrong',
            //   style: TextStyle(
            //     fontSize: 18,
            //     color: Colors.red,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            // const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Text(
            //   'Selected dates: ${_controller.formatDateForDisplay(_controller.fromDate.value)} - ${_controller.formatDateForDisplay(_controller.toDate.value)}',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey.shade500,
            //   ),
            // ),
            // const SizedBox(height: 24),
            // ElevatedButton(
            //   onPressed: () {
            //     _controller.fetchTourVouchers();
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.red,
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            //   ),
            //   child: const Text('Retry', style: TextStyle(color: Colors.white)),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Tour Vouchers Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No vouchers found for the selected date range.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_controller.formatDateForDisplay(_controller.fromDate.value)} - ${_controller.formatDateForDisplay(_controller.toDate.value)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to create new voucher
              Get.to(const CreateTourVoucherScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlavorConfig.instance.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Create New Voucher',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_controller.tourVouchers.length} Result found',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Voucher list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _controller.fetchTourVouchers();
            },
            color: FlavorConfig.instance.primaryColor,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: _controller.tourVouchers.length,
              itemBuilder: (context, index) {
                return _buildVoucherCard(_controller.tourVouchers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
