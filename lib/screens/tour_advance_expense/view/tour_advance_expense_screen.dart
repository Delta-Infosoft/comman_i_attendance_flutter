import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../flavor_config.dart';
import '../model/tour_advance_expense_model.dart';
import '../view_model/tour_advance_expense_controller.dart';

class TourAdvanceExpenseScreen extends StatefulWidget {
  const TourAdvanceExpenseScreen({super.key});

  @override
  State<TourAdvanceExpenseScreen> createState() =>
      _TourAdvanceExpenseScreenState();
}

class _TourAdvanceExpenseScreenState extends State<TourAdvanceExpenseScreen> {
  late final TourAdvanceExpenseController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TourAdvanceExpenseController>()) {
      Get.delete<TourAdvanceExpenseController>(force: true);
    }
    controller = Get.put(TourAdvanceExpenseController());
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        elevation: 0.5,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: const Text(
          'Tour Advance Expense',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () {
          controller.openAddForm();
          _openFormSheet(context, isEdit: false);
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // ── Date Range Filter ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Obx(() => Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'From Date',
                        value: DateFormat('dd-MMM-yyyy')
                            .format(controller.fromDate.value),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: controller.fromDate.value,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) controller.setFromDate(picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'To Date',
                        value: DateFormat('dd-MMM-yyyy')
                            .format(controller.toDate.value),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: controller.toDate.value,
                            firstDate: controller.fromDate.value,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) controller.setToDate(picked);
                        },
                      ),
                    ),
                  ],
                )),
          ),
          const Divider(height: 1),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }
              if (controller.expenseList.isEmpty) {
                return _EmptyState(primaryColor: primaryColor);
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: controller.expenseList.length,
                itemBuilder: (context, index) {
                  final item = controller.expenseList[index];
                  return _ExpenseCard(
                    item: item,
                    primaryColor: primaryColor,
                    onEdit: () {
                      controller.openEditForm(item);
                      _openFormSheet(context, isEdit: true);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet form for Add / Edit
  void _openFormSheet(BuildContext context, {required bool isEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(
        controller: controller,
        isEdit: isEdit,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Date Picker Field Widget
// ══════════════════════════════════════════════════════════════════════════════
class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF9F9FB),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Expense Card
// ══════════════════════════════════════════════════════════════════════════════
class _ExpenseCard extends StatelessWidget {
  final TourAdvanceExpenseItem item;
  final Color primaryColor;
  final VoidCallback onEdit;

  const _ExpenseCard({
    required this.item,
    required this.primaryColor,
    required this.onEdit,
  });

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd-MMM-yyyy').format(dt);
    } catch (_) {
      // Try M/d/yyyy h:mm:ss a format
      try {
        final dt = DateFormat('M/d/yyyy h:mm:ss a').parse(raw);
        return DateFormat('dd-MMM-yyyy').format(dt);
      } catch (_) {
        return raw;
      }
    }
  }

  String _formatAmount(String raw) {
    try {
      final amount = double.parse(raw);
      return NumberFormat('#,##,##0.##').format(amount);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with employee name + edit icon
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.employeeName.isNotEmpty
                        ? item.employeeName
                        : 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: primaryColor,
                  text: _formatDate(item.requestDt),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  text: '${_formatAmount(item.advanceAmount)}',
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                if (item.remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    iconColor: Colors.blueGrey,
                    text: item.remarks,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final TextStyle? textStyle;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty State
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final Color primaryColor;

  const _EmptyState({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Records Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add a new advance expense',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom Sheet Form
// ══════════════════════════════════════════════════════════════════════════════
class _ExpenseFormSheet extends StatelessWidget {
  final TourAdvanceExpenseController controller;
  final bool isEdit;

  const _ExpenseFormSheet({
    required this.controller,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.primaryColor;
    final buttonColor = FlavorConfig.instance.buttonColor;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Let the sheet grow but cap at 90% of screen height
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Scrollable form content ──────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      isEdit ? 'Edit Advance Expense' : 'Add Advance Expense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name (read-only)
                    _FormField(
                      label: 'Name',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Request Date — tappable date picker
                    Obx(() => _FormField(
                          label: 'Request Date',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.requestDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(DateTime.now().year + 5),
                              );
                              if (picked != null) {
                                controller.setRequestDate(picked);
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.requestDtFormatted,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 14),

                    // Advance Amount
                    _FormField(
                      label: 'Advance Amount',
                      child: TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Enter amount',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                          prefixText: '₹  ',
                          prefixStyle: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Advance amount is required';
                          }
                          if (double.tryParse(val.trim()) == null) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Remarks
                    _FormField(
                      label: 'Remark',
                      child: TextFormField(
                        controller: controller.remarkController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Enter remark',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Remark is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Fixed Submit Button in SafeArea ──────────────────────
            SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          disabledBackgroundColor:
                              buttonColor.withOpacity(0.6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    )),
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}

/// Floating-label input container — same style as dealer check-in screen
class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400, width: 1.2),
          ),
          child: child,
        ),
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
