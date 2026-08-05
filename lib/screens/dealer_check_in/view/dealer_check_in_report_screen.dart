import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waterman_iattandance/constant/local_db/local_db.dart';
import 'package:intl/intl.dart';
import '../../../flavor_config.dart';
import '../model/dealer_check_in_model.dart';
import '../repository/dealer_check_in_repository.dart';

class DealerCheckInReportScreen extends StatefulWidget {
  const DealerCheckInReportScreen({super.key});

  @override
  State<DealerCheckInReportScreen> createState() =>
      _DealerCheckInReportScreenState();
}

class _DealerCheckInReportScreenState
    extends State<DealerCheckInReportScreen> {
  final DealerCheckInRepository _repository = DealerCheckInRepository();
  GoogleMapController? _mapController;

  bool _isLoading = true;
  List<DealerCheckInStatusItem> _checkInRecords = [];
  List<MapDetailItem> _mapDetails = [];
  LatLng? _userStartLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double _totalDistanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final mobileNo = LocalDbController.to.mobileNo ?? '';

      // 1. Fetch user current/start location
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _userStartLocation = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        _userStartLocation = const LatLng(23.0225, 72.5714); // default fallback
      }

      // 2. Fetch all dealer check-ins for today from API
      final list = await _repository.checkDealerStatus(mobileNo: mobileNo);
      _checkInRecords = list;

      // 3. Fetch map details for today (API_MapDetails.aspx)
      final todayStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
      try {
        _mapDetails = await _repository.fetchMapDetails(
          mobileNo: mobileNo,
          date: todayStr,
        );
      } catch (e) {
        debugPrint("Error fetching map details: $e");
        _mapDetails = [];
      }

      _buildMapMarkersAndRoute();
    } catch (e) {
      debugPrint("Error loading report data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildMapMarkersAndRoute() {
    Set<Marker> newMarkers = {};
    List<LatLng> routePoints = [];
    double calculatedKm = 0.0;

    if (_mapDetails.isNotEmpty) {
      for (int i = 0; i < _mapDetails.length; i++) {
        final item = _mapDetails[i];
        final double? lat = double.tryParse(item.lat);
        final double? lng = double.tryParse(item.long);

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final pt = LatLng(lat, lng);
          routePoints.add(pt);

          // Customize marker color and title by type
          double hue = BitmapDescriptor.hueBlue;
          String title = item.type;

          if (item.type == 'AttendanceCheckIn') {
            hue = BitmapDescriptor.hueAzure;
            title = 'Attendance Check-In';
          } else if (item.type == 'DealerCheckIn') {
            hue = BitmapDescriptor.hueRed;
            title = 'Client Check-In';
          } else if (item.type == 'DealerCheckOut') {
            hue = BitmapDescriptor.hueOrange;
            title = 'Client Check-Out';
          } else if (item.type.toLowerCase().contains('checkout')) {
            hue = BitmapDescriptor.hueOrange;
          } else if (item.type.toLowerCase().contains('checkin')) {
            hue = BitmapDescriptor.hueRed;
          }

          newMarkers.add(
            Marker(
              markerId: MarkerId('map_detail_${item.type}_${item.insertedOn}_$i'),
              position: pt,
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: title,
                snippet: "Time: ${item.insertedOn}",
              ),
            ),
          );
        }
      }
    } else {
      // Fallback: original logic using _userStartLocation and _checkInRecords
      if (_userStartLocation != null) {
        routePoints.add(_userStartLocation!);
        newMarkers.add(
          Marker(
            markerId: const MarkerId('user_start_loc'),
            position: _userStartLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: "User Daily Check-In Location",
              snippet: "Start Point",
            ),
          ),
        );
      }

      for (int i = 0; i < _checkInRecords.length; i++) {
        final item = _checkInRecords[i];
        final double? lat = double.tryParse(item.lat);
        final double? lng = double.tryParse(item.long);

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final pt = LatLng(lat, lng);
          routePoints.add(pt);

          newMarkers.add(
            Marker(
              markerId: MarkerId('dealer_${item.dealerCheckInId}_$i'),
              position: pt,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: item.dealerName.isNotEmpty ? item.dealerName : item.dealerCategory,
                snippet: "In: ${item.inTime} | Category: ${item.dealerCategory}",
              ),
            ),
          );
        }
      }
    }

    // Calculate Total Travel Distance (KM)
    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];
      final meters = Geolocator.distanceBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );
      calculatedKm += (meters / 1000.0);
    }

    // Create Polyline
    Set<Polyline> newPolylines = {};
    if (routePoints.length > 1) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('dealer_travel_route'),
          points: routePoints,
          color: FlavorConfig.instance.primaryColor,
          width: 5,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
      _totalDistanceKm = calculatedKm;
    });

    // Fit map bounds
    if (routePoints.isNotEmpty && _mapController != null) {
      _fitMapBounds(routePoints);
    }
  }

  void _fitMapBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        elevation: 0.5,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        title: const Text(
          "Client Check-In Route & Report",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // ── 1. Map View Header Container ─────────────────────────────
                SafeArea(
                  maintainBottomViewPadding: true,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.84,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _userStartLocation ?? const LatLng(23.0225, 72.5714),
                            zoom: 13,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onMapCreated: (ctrl) {
                            _mapController = ctrl;
                            if (_markers.isNotEmpty) {
                              final points = _markers.map((m) => m.position).toList();
                              _fitMapBounds(points);
                            }
                          },
                        ),

                        // Distance Card Overlay
                        Positioned(
                          top: 12,
                          left: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricItem(
                                  icon: Icons.map_rounded,
                                  iconColor: primaryColor,
                                  label: "Total Distance",
                                  value: "${_totalDistanceKm.toStringAsFixed(2)} KM",
                                ),
                                // Container(height: 30, width: 1, color: Colors.grey.shade300),
                                // _buildMetricItem(
                                //   icon: Icons.storefront_rounded,
                                //   iconColor: const Color(0xFF2E7D32),
                                //   label: "Dealer Visits",
                                //   value: "${_checkInRecords.length}",
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. List Header ───────────────────────────────────────────
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text(
                //         "Today's Dealer Check-Ins",
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       Text(
                //         "${_checkInRecords.length} Items",
                //         style: TextStyle(
                //           fontSize: 13,
                //           color: Colors.grey.shade600,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                //
                // // ── 3. Check-In Records List ────────────────────────────────
                // Expanded(
                //   child: _checkInRecords.isEmpty
                //       ? Center(
                //           child: Column(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
                //               const SizedBox(height: 10),
                //               Text(
                //                 "No dealer check-ins recorded for today.",
                //                 style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                //               ),
                //             ],
                //           ),
                //         )
                //       : ListView.builder(
                //           physics: const BouncingScrollPhysics(),
                //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                //           itemCount: _checkInRecords.length,
                //           itemBuilder: (context, index) {
                //             final item = _checkInRecords[index];
                //             return _buildRecordCard(item, index + 1, primaryColor);
                //           },
                //         ),
                // ),
              ],
            ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordCard(DealerCheckInStatusItem item, int index, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "#$index",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dealerName.isNotEmpty ? item.dealerName : item.dealerCategory,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  "Category: ${item.dealerCategory}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "In: ${item.inTime}",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    if (item.outTime.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.logout_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Out: ${item.outTime}",
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ],
                ),
                if (item.remarks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Remark: ${item.remarks}",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
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
