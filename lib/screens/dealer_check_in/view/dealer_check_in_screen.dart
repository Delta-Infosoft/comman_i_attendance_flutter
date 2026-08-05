import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../flavor_config.dart';
import '../model/dealer_check_in_model.dart';
import '../view_model/dealer_check_in_controller.dart';
import 'dealer_check_in_report_screen.dart';

class DealerCheckInScreen extends StatefulWidget {
  const DealerCheckInScreen({super.key});

  @override
  State<DealerCheckInScreen> createState() => _DealerCheckInScreenState();
}

class _DealerCheckInScreenState extends State<DealerCheckInScreen> {
  late final DealerCheckInController controller;

  @override
  void initState() {
    super.initState();
    // Always create a fresh controller when the screen opens
    // so stale state from previous navigation is never reused.
    if (Get.isRegistered<DealerCheckInController>()) {
      Get.delete<DealerCheckInController>(force: true);
    }
    controller = Get.put(DealerCheckInController());
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.primaryColor;
    final buttonColor = FlavorConfig.instance.buttonColor;

    return Scaffold(
      backgroundColor:  Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        elevation: 0.5,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: const Text(
          "Dealer Check-In",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: primaryColor),
            tooltip: "Route & Report Map",
            onPressed: () => Get.to(() => const DealerCheckInReportScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Active Status Banner (if checked in) ───────────────
                    Obx(() {
                      if (!controller.isCheckedIn.value) return const SizedBox.shrink();
                      final active = controller.activeCheckInItem.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    active?.statusMsgShow.isNotEmpty == true
                                        ? active!.statusMsgShow
                                        : "Currently Checked-In at ${active?.dealerName ?? active?.dealerCategory}",
                                    style: const TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap Check-Out to open Daily Tour and complete check-out.",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ── 1. Dealer Category Dropdown ──────────────────────────
                    Obx(() {
                      final isLoading = controller.isLoadingCategories.value;
                      final catList = controller.categories;
                      final selected = controller.selectedCategory.value;
                      final isCheckedIn = controller.isCheckedIn.value;

                      return _buildInputContainer(
                        label: "Dealer Category",
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : isCheckedIn && selected != null
                                // When checked-in, show a non-interactive read-only text
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selected.text,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 18),
                                    ],
                                  )
                                : DropdownButtonHideUnderline(
                                    child: DropdownButton<DealerCategoryModel>(
                                      value: selected,
                                      isExpanded: true,
                                      hint: const Text(
                                        "Select Category",
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                      icon: Icon(Icons.arrow_drop_down, color: primaryColor, size: 28),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: catList.map((DealerCategoryModel cat) {
                                        return DropdownMenuItem<DealerCategoryModel>(
                                          value: cat,
                                          child: Text(cat.text),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          controller.onCategorySelected(val);
                                        }
                                      },
                                    ),
                                  ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // ── 2. Dealer Name (Dropdown or TextField) ───────────────
                    Obx(() {
                      final isManual = controller.isManualDealerName.value;
                      final isLoading = controller.isLoadingDealerNames.value;
                      final dealerList = controller.dealerNameList;
                      final selectedDealer = controller.selectedDealerItem.value;
                      final isCheckedIn = controller.isCheckedIn.value;

                      return _buildInputContainer(
                        label: "Dealer Name",
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : !isManual
                                ? DropdownButtonHideUnderline(
                                    child: DropdownButton<DealerNameItemModel>(
                                      value: selectedDealer != null && dealerList.any((item) => item.dealerId == selectedDealer.dealerId)
                                          ? dealerList.firstWhere((item) => item.dealerId == selectedDealer.dealerId)
                                          : null,
                                      hint: Text(
                                        dealerList.isEmpty
                                            ? "No dealer found"
                                            : "Select Dealer Name",
                                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: primaryColor, size: 28),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: dealerList.map((DealerNameItemModel item) {
                                        return DropdownMenuItem<DealerNameItemModel>(
                                          value: item,
                                          child: Text(item.dealerName),
                                        );
                                      }).toList(),
                                      onChanged: isCheckedIn
                                          ? null  // lock when checked-in
                                          : (val) {
                                              controller.selectedDealerItem.value = val;
                                              if (val != null) {
                                                controller.dealerNameController.text = val.dealerName;
                                              }
                                            },
                                    ),
                                  )
                                : TextField(
                                    controller: controller.dealerNameController,
                                    readOnly: isCheckedIn, // lock when checked-in
                                    style: TextStyle(
                                      color: isCheckedIn ? Colors.black87 : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      hintText: "Enter dealer name",
                                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                      suffixIcon: isCheckedIn
                                          ? Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 18)
                                          : null,
                                    ),
                                  ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // ── 3. Remark Input ──────────────────────────────────────
                    _buildInputContainer(
                      label: "Remark",
                      child: TextField(
                        controller: controller.remarkController,
                        maxLines: 3,
                        readOnly: false, // always editable
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          hintText: "Enter remarks",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          suffixIcon: null, // no lock icon for remark
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 4. GPS Photo Capture Card (MANDATORY) ───────────────
                    Obx(() {
                      final photo = controller.photoFile.value;
                      final isCapturing = controller.isCapturingPhoto.value;
                      final photoCaptured = photo != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Required label row
                          Row(
                            children: [
                              Text(
                                "GPS Photo",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: photoCaptured
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  photoCaptured ? "✓ Captured" : "* Required",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: photoCaptured
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                // Red border when photo not yet taken, green when captured
                                color: photoCaptured
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFEF5350),
                                width: photoCaptured ? 1 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: photoCaptured
                                      ? Colors.green.withOpacity(0.05)
                                      : Colors.red.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (photo == null)
                                  GestureDetector(
                                    onTap: isCapturing
                                        ? null
                                        : () => controller.captureGpsPhoto(context),
                                    child: Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF5F5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFEF5350).withOpacity(0.5),
                                          style: BorderStyle.solid,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (isCapturing)
                                            CircularProgressIndicator(color: primaryColor)
                                          else ...[
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFEBEE),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 36,
                                                color: Color(0xFFC62828),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Tap to Capture GPS Photo",
                                              style: TextStyle(
                                                color: Color(0xFFC62828),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Location & timestamp will be attached",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEBEE),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFFEF9A9A)),
                                              ),
                                              child: const Text(
                                                "⚠ Mandatory for Check-In & Check-Out",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFC62828),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Image.file(
                                              photo,
                                              height: 240,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              color: Colors.black.withOpacity(0.65),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (controller.currentAddress.value.isNotEmpty)
                                                    Text(
                                                      "Location: ${controller.currentAddress.value}",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  Text(
                                                    controller.formattedDateTime.value,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => controller.captureGpsPhoto(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      photoCaptured
                                          ? Icons.check_circle_rounded
                                          : Icons.error_outline_rounded,
                                      color: photoCaptured
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFC62828),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      photoCaptured
                                          ? "GPS Photo Captured Successfully"
                                          : "GPS Photo Not Captured — Required!",
                                      style: TextStyle(
                                        color: photoCaptured
                                            ? Colors.black87
                                            : const Color(0xFFC62828),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── 5. Bottom Dynamic Action Button (Check-In or Check-Out) ─────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Obx(() {
                final isSubmitting = controller.isSubmitting.value;
                final isCheckedIn = controller.isCheckedIn.value;
                final buttonText = isCheckedIn ? "Check-Out" : "Check-In";
                final btnColor = isCheckedIn ? const Color(0xFFC62828) : buttonColor;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => controller.handleMainActionButton(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      disabledBackgroundColor: btnColor.withOpacity(0.6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({required String label, required Widget child}) {
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
            color: const Color(0xFFF9F9FB),
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
