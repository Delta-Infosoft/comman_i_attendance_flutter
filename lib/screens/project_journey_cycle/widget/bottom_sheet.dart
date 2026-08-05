// widgets/pjc_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waterman_iattandance/screens/project_journey_cycle/model/project_journey_model.dart';
import 'package:waterman_iattandance/flavor_config.dart';

class PJCBottomSheet extends StatelessWidget {
  final DateTime date;
  final List<PJCData> pjcEvents; // ✅ Change this to PJCData

  const PJCBottomSheet({
    super.key,
    required this.date,
    required this.pjcEvents, // ✅ Now accepts PJCData
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(date);

    return Container(
      height: _calculateHeight(pjcEvents.length),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          // Header Section (Red Bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: FlavorConfig.instance.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pjcEvents.isEmpty ? "No Plans" : "Today's Plan And Follow Up",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          if (pjcEvents.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No Journey Plans for this date',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: pjcEvents.length,
                itemBuilder: (context, index) {
                  final event = pjcEvents[index];
                  return _buildPlanItem(event, index + 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(PJCData event, int planNumber) {
    // ✅ Change parameter to PJCData
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Plan Number
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: FlavorConfig.instance.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Plan $planNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: FlavorConfig.instance.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Station Row
          Row(
            children: [
              Icon(Icons.location_on, color: FlavorConfig.instance.primaryColor),
              const SizedBox(width: 10),
              const Text('Station',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  event.place.isNotEmpty
                      ? event.place
                      : 'Not specified', // ✅ Uses PJCData.place
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Agenda Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, color: FlavorConfig.instance.primaryColor),
              const SizedBox(width: 10),
              const Text('Agenda',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 25),
              Expanded(
                child: Text(
                  event.notes.isNotEmpty
                      ? event.notes
                      : 'Not specified', // ✅ Uses PJCData.notes
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateHeight(int eventCount) {
    if (eventCount == 0) return 200;

    final headerHeight = 65.0;
    const paddingHeight = 40.0;
    const perEventHeight = 140.0;
    const maxHeight = 500.0;

    final calculatedHeight =
        headerHeight + paddingHeight + (eventCount * perEventHeight);
    return calculatedHeight > maxHeight ? maxHeight : calculatedHeight;
  }
}

// // widgets/pjc_bottom_sheet.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:waterman_iattandance/screens/project_journey_cycle/model/project_journey_model.dart';

// class PJCBottomSheet extends StatelessWidget {
//   final DateTime date;
//   final List<PJCData> pjcEvents;

//   const PJCBottomSheet({
//     super.key,
//     required this.date,
//     required this.pjcEvents,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.8,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Center(
//             child: Text(
//               DateFormat('dd MMMM yyyy').format(date),
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red,
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Events Count
//           Text(
//             'Journey Plans: ${pjcEvents.length}',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Scrollable Events List
//           if (pjcEvents.isEmpty)
//             const Center(
//               child: Text(
//                 'No Journey Plans for this date',
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 physics: const BouncingScrollPhysics(),
//                 itemCount: pjcEvents.length,
//                 itemBuilder: (context, index) {
//                   final event = pjcEvents[index];
//                   return _buildEventCard(event, index + 1);
//                 },
//               ),
//             ),

//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventCard(PJCData event, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with index
//             Row(
//               children: [
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade100,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     'Plan $index',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   'Line: ${event.lnNo}',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Station/Place
//             if (event.place.isNotEmpty)
//               _buildInfoRow('📍 Station', event.place),

//             // Notes/Agenda
//             if (event.notes.isNotEmpty) _buildInfoRow('📝 Agenda', event.notes),

//             // Additional info
//             _buildInfoRow('🏢 Area', event.area),

//             const SizedBox(height: 8),

//             // Divider for multiple events
//             if (event.notes.isNotEmpty || event.place.isNotEmpty)
//               const Divider(height: 1),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value.isNotEmpty ? value : 'Not specified',
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
