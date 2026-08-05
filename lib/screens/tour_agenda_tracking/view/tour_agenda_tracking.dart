import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../flavor_config.dart';

class TourAgendaTracking extends StatefulWidget {
  const TourAgendaTracking({super.key});

  @override
  State<TourAgendaTracking> createState() => _TourAgendaTrackingState();
}

class _TourAgendaTrackingState extends State<TourAgendaTracking> {
  // Dummy controllers and variables
  String? selectedState;
  String? selectedDistrict;
  String? selectedBusinessCategory;
  String? selectedDealerCategory;
  String? selectedBusinessCenter;
  String? selectedEntityName; // Store selected Dealer/SubDealer/ServiceCenter name

  final TextEditingController employeeNameController = TextEditingController(text: 'Chetan Parmar');

  final List<String> states = ['Bihar', 'Uttar Pradesh', 'Delhi', 'Maharashtra'];
  final List<String> districts = ['Sitamarhi', 'Patna', 'Gaya', 'Muzaffarpur'];
  final List<String> dealerCategories = ['Dealer', 'Sub Dealer', 'Service Center'];
  
  // Mock Data for specific categories
  final List<String> dealerList = ['Ganga Electrical Work', 'Vijay Sales', 'Rohan Motors'];
  final List<String> subDealerList = ['Sai Traders', 'Om Agencies', 'Hari Hardware'];
  final List<String> serviceCenterList = ['Latur Service Hub', 'Pune Repair Center', 'Mumbai Care'];

  // Meeting State
  bool isMeetingStarted = false;
  String checkInTime = '--:--';
  String checkOutTime = '--:--';
  Timer? _timer;
  Duration _duration = Duration.zero;

  // Mock Data for Agenda
  final List<Map<String, dynamic>> agendaItems = [
    {
      'title': 'Budget Vs Achieved',
      'subtitle': '150 / 100 - Running Less in Target',
      'isCompleted': false,
    },
    {
      'title': 'New Order Follow-up',
      'subtitle': 'Take New Order for Turbo Pumps',
      'isCompleted': false,
    },
    {
      'title': 'Hording Status',
      'subtitle': 'We had spent 20,000 for Hoardings at Jaipur, ask update on same',
      'isCompleted': false,
    },
    {
      'title': 'Budget Vs Achieved',
      'subtitle': 'TELANGANA DBT SCHEME APPROVAL',
      'isCompleted': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Listen to changes in employee name to enable/disable State tab
    employeeNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    employeeNameController.dispose();
    super.dispose();
  }

  void _resetMeetingData() {
    // Only resets meeting specific data, keeps form selections
    setState(() {
      checkInTime = '--:--';
      checkOutTime = '--:--';
      isMeetingStarted = false;
      _duration = Duration.zero;
      _timer?.cancel();
    });
  }

  void _toggleMeeting() {
    setState(() {
      if (!isMeetingStarted) {
        // Start Meeting
        isMeetingStarted = true;
        checkInTime = DateFormat('HH:mm').format(DateTime.now());
        checkOutTime = '--:--';
        _duration = Duration.zero;
        _startTimer();
      } else {
        // Stop Meeting
        // User requested: "only clear data of start meeting threw data showed that data only remove not all"
        _resetMeetingData();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String get _formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    bool isEmployeeEntered = employeeNameController.text.isNotEmpty;
    bool isStateSelected = selectedState != null;
    bool isDistrictSelected = selectedDistrict != null;
    bool isBusinessCenterSelected = selectedBusinessCenter != null;
    bool isDealerCategorySelected = selectedDealerCategory != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        title: Text(
          'Tour Agenda Tracking',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: FlavorConfig.instance.appBarForegroundColor,
          ),
        ),
        leading: FlavorConfig.instance.getAppBarLeading(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderTabs(isEmployeeEntered, isStateSelected, isDistrictSelected),
                  const SizedBox(height: 16),
                  
                  // Dealer Category Dropdown - Enabled only if Business Center is selected
                  IgnorePointer(
                    ignoring: !isBusinessCenterSelected,
                    child: Opacity(
                      opacity: isBusinessCenterSelected ? 1.0 : 0.5,
                      child: _buildGenericDropdown(
                        'Select Category', 
                        dealerCategories, 
                        selectedDealerCategory, 
                        (val) => setState(() {
                           selectedDealerCategory = val;
                           // Reset downstream
                           selectedEntityName = null;
                        })
                      ),
                    ),
                  ),
                  
                  // Specific Dropdown (Dealer / Sub Dealer / Service Center) - Visible after Category selected
                  if (isDealerCategorySelected) ...[
                    const SizedBox(height: 16),
                    _buildGenericDropdown(
                      'Select ${selectedDealerCategory!}', 
                      _getCategoryList(selectedDealerCategory!), 
                      selectedEntityName, 
                      (val) => setState(() => selectedEntityName = val)
                    ),
                  ],

                  // Dealer Details Card - Visible if Entity Name is selected
                  if (selectedEntityName != null) ...[
                    const SizedBox(height: 16),
                    _buildDealerDetailsCard(),
                    
                    const SizedBox(height: 24),
                    // Action Row: Button + Timer
                    Row(
                      children: [
                        Expanded(child: _buildStartMeetingButton()),
                        const SizedBox(width: 16),
                        Text(
                          _formattedDuration,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildStatusSection(),
                    
                    // Agenda List (Visible only when meeting started)
                    if (isMeetingStarted) ...[
                       const SizedBox(height: 24),
                       _buildAgendaList(),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getCategoryList(String category) {
    switch (category) {
      case 'Dealer':
        return dealerList;
      case 'Sub Dealer':
        return subDealerList;
      case 'Service Center':
        return serviceCenterList;
      default:
        return [];
    }
  }

  Widget _buildHeaderTabs(bool isEmployeeEntered, bool isStateSelected, bool isDistrictSelected) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTabItem('Employee Name', '', [], (val) {}, isEditable: true, controller: employeeNameController),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IgnorePointer(
                ignoring: !isEmployeeEntered,
                child: Opacity(
                  opacity: isEmployeeEntered ? 1.0 : 0.5,
                  child: _buildTabItem('State', selectedState ?? 'Select State', states, (val) => setState(() {
                    selectedState = val;
                    // Reset downstream
                    selectedDistrict = null;
                    selectedBusinessCenter = null;
                    selectedDealerCategory = null;
                    selectedEntityName = null;
                  }), isDropdown: true),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: !isStateSelected,
                child: Opacity(
                  opacity: isStateSelected ? 1.0 : 0.5,
                  child: _buildTabItem('District', selectedDistrict ?? 'Select District', districts, (val) => setState(() {
                    selectedDistrict = val;
                    // Reset downstream
                    selectedBusinessCenter = null;
                    selectedDealerCategory = null;
                    selectedEntityName = null;
                  }), isDropdown: true),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IgnorePointer(
                ignoring: !isDistrictSelected,
                child: Opacity(
                  opacity: isDistrictSelected ? 1.0 : 0.5,
                  child: _buildTabItem('Business Center', selectedBusinessCenter ?? 'Select Center', ['Latur', 'Pune', 'Mumbai'], (val) => setState(() {
                    selectedBusinessCenter = val;
                    // Reset downstream
                    selectedDealerCategory = null;
                    selectedEntityName = null;
                  }), isDropdown: true),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(String label, String value, List<String> items, Function(String?) onChanged, {bool isDropdown = false, bool isEditable = false, TextEditingController? controller}) {
    // The visual container for the tab
    return Container(
      // margin: const EdgeInsets.only(right: 8), // Margin handled by parent Row
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (isEditable && controller != null)
             SizedBox(
               height: 20,
               child: TextField(
                 controller: controller,
                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                 decoration: const InputDecoration(
                   isDense: true,
                   contentPadding: EdgeInsets.zero,
                   border: InputBorder.none,
                   hintText: 'Enter Name',
                   hintStyle: TextStyle(fontSize: 10, color: Colors.grey),
                 ),
               ),
             )
          else if (isDropdown)
            DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                customButton: Row(
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                  ],
                ),
                items: items
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  offset: const Offset(0, -4),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 40,
                  padding: EdgeInsets.only(left: 16, right: 16),
                ),
              ),
            )
          else
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDealerDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ganga Electrical Work',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, color: Colors.black54, size: 18)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48), // Align with text start
            child: Text(
              'Dealer Name',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildDetailItem(Icons.person, 'Chandrkant', 'Contact Person'),
               _buildDetailItem(Icons.category, 'C', 'Category'),
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.call, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('8275173499', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
               )
            ],
          ),
           const SizedBox(height: 16),
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Icon(Icons.location_on, color: Colors.red, size: 18),
               const SizedBox(width: 8),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text(
                       'Ahmedapur',
                       style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                     ),
                     const SizedBox(height: 2),
                     Text(
                       'Akshya Nagar 1st Block 1st Cross, Ramurthy nagar,-560016',
                       style: TextStyle(color: Colors.grey[700], fontSize: 12),
                     ),
                   ],
                 ),
               )
             ],
           )
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black54, size: 16),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildGenericDropdown(String hint, List<String> items, String? currentValue, Function(String?) onChanged) {
      return DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          )).toList(),
          value: currentValue,
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
  }

  Widget _buildStartMeetingButton() {
    return GestureDetector(
      onTap: _toggleMeeting,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 50,
        decoration: BoxDecoration(
          color: isMeetingStarted ? Colors.red : Colors.green,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isMeetingStarted ? Colors.red : Colors.green).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isMeetingStarted ? 'Stop Meeting' : 'Start Meeting',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeStatus('Check-In', checkInTime),
          _buildTimeStatus('Check-Out', checkOutTime),
        ],
      ),
    );
  }

  Widget _buildTimeStatus(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAgendaList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agendaItems.length,
      itemBuilder: (context, index) {
        final item = agendaItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                color: Colors.red,
                margin: const EdgeInsets.only(right: 12, top: 2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (item['isCompleted'])
                const Icon(Icons.check_box, color: Colors.red)
              else
                Icon(Icons.check_box_outline_blank, color: Colors.red.shade300),
            ],
          ),
        );
      },
    );
  }
}
