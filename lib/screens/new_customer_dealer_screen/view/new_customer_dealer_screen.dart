import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waterman_iattandance/screens/my_portfolio_screen/view_model/my_portfolio_controller.dart';
import 'package:waterman_iattandance/screens/new_customer_dealer_screen/view_model/new_customer_deal_controller.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';
import '../../../flavor_config.dart';

class NewCustomerDealerScreen extends StatefulWidget {
  final String? portfolioId;
  const NewCustomerDealerScreen({super.key, this.portfolioId});

  @override
  State<NewCustomerDealerScreen> createState() =>
      _NewCustomerDealerScreenState();
}

class _NewCustomerDealerScreenState extends State<NewCustomerDealerScreen> {
  final NewCustomerDealerController controller =
      Get.put(NewCustomerDealerController());
  final MyPortfolioController portfolioController =
      Get.put(MyPortfolioController());
  GoogleMapController? _mapController;
  final _formKey = GlobalKey<FormState>();

  XFile? photoFile0;
  XFile? photoFile1;
  XFile? photoFile2;
  XFile? photoFile3;
  XFile? photoFile4;

  String? _imageUrl0;
  String? _imageUrl1;
  String? _imageUrl2;
  String? _imageUrl3;
  String? _imageUrl4;

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = false;

  String? _getValidationError() {
    final companyName = controller.companyNameController.text.trim();
    if (companyName.isEmpty) return 'Company Name is required';

    final city = controller.cityController.text.trim();
    if (city.isEmpty) return 'City is required';

    final contactPersonName = controller.contactPersonNameController.text.trim();
    if (contactPersonName.isEmpty) return 'Contact Person Name is required';

    final contactPersonMobileNo = controller.contactPersonMobileNoController.text.trim();
    if (contactPersonMobileNo.isEmpty) return 'Contact Person Mobile No is required';
    if (contactPersonMobileNo.length != 10) return 'Mobile no. must be exactly 10 digits';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(contactPersonMobileNo)) return 'Contact Person Mobile No must contain only digits';

    final contactPersonEmail = controller.contactPersonEmailController.text.trim();
    if (contactPersonEmail.isEmpty) return 'Contact Person Email is required';
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(contactPersonEmail)) return 'Enter a valid email address';

    final remark = controller.remarkController.text.trim();
    if (remark.isEmpty) return 'Remarks is required';

    return null;
  }

  @override
  void initState() {
    _getCurrentLocation();
    print("PORTFOLIO ID>>>>>>>>>>>: ${widget.portfolioId}");
    if (widget.portfolioId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPortfolioDetails();
      });

    }
    super.initState();
  }



  Future<void> _loadPortfolioDetails() async {
    try {
      final model = await portfolioController.fetchSelectedPortfolioDetails(
        widget.portfolioId!,
      );

      if (model.result == null || model.result!.isEmpty) {
        throw Exception("No portfolio data found");
      }

      final data = model.result!.first;

      controller.companyNameController.text = data.companyName ?? '';
      controller.cityController.text = data.city ?? '';
      controller.contactPersonNameController.text =
          data.contactPersonName ?? '';
      controller.contactPersonMobileNoController.text =
          data.contactPersonMobileNo ?? '';
      controller.contactPersonEmailController.text =
          data.contactPersonEmailId ?? '';
      controller.remarkController.text = data.remarks ?? '';

      if (data.lat != null && data.long != null) {
        controller.currentLatLng = LatLng(
          double.parse(data.lat!),
          double.parse(data.long!),
        );

        controller.markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: controller.currentLatLng!,
          ),
        };
      }

      setState(() {
        _imageUrl0 = data.photoPathShow;
        _imageUrl1 = data.photoPathShow1;
        _imageUrl2 = data.photoPathShow2;
        _imageUrl3 = data.photoPathShow3;
        _imageUrl4 = data.photoPathShow4;
      });

      controller.update(); // single update at end
    } catch (e) {
      debugPrint("EDIT LOAD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data')),
      );
    }
  }


  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update both local state and controller
      _currentPosition = LatLng(position.latitude, position.longitude);
      controller.currentLatLng = _currentPosition;
      controller.markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentPosition!,
        ),
      };

      // Force GetBuilder to rebuild
      controller.update();

      // Move camera if map is already initialized
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16),
      );
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }



  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   // Check service
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return;
  //   }
  //
  //   // Check permission
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) return;
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) return;
  //
  //   // Get position
  //   final Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  //
  //   setState(() {
  //     _currentPosition = LatLng(position.latitude, position.longitude);
  //   });
  //
  //   // Move camera
  //   _mapController?.animateCamera(
  //     CameraUpdate.newLatLngZoom(_currentPosition!, 16),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        leading: FlavorConfig.instance.getAppBarLeading(context),
        // Title from the image
        title: Text(
          'New Customer/Dealer',
          style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor),
        ),
        centerTitle: false,

        actions: [],
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildInputField(
                  icon: Icons.business,
                  hintText: 'enter company name',
                  fieldName: 'Company Name',
                  keyboardType: TextInputType.text,
                  controller: controller.companyNameController,
                ),
                _buildInputField(
                    icon: Icons.bar_chart,
                    hintText: 'enter city',
                    fieldName: 'City',
                    keyboardType: TextInputType.text,
                    controller: controller.cityController),
                _buildInputField(
                    icon: Icons.person,
                    hintText: 'enter contact person name',
                    fieldName: 'Contact Person Name',
                    keyboardType: TextInputType.text,
                    controller: controller.contactPersonNameController),
                _buildInputField(
                    icon: Icons.phone_android,
                    hintText: 'enter contact person mobile no',
                    fieldName: 'Contact Person Mobile No',
                    keyboardType: TextInputType.phone,
                    isMobile: true,
                    controller: controller.contactPersonMobileNoController),
                _buildInputField(
                    icon: Icons.alternate_email,
                    hintText: 'enter contact person email',
                    fieldName: 'Contact Person Email',
                    keyboardType: TextInputType.emailAddress,
                    isEmail: true,
                    controller: controller.contactPersonEmailController),
                _buildInputField(
                    icon: Icons.chat_bubble_outline,
                    hintText: 'enter remarks',
                    fieldName: 'Remarks',
                    keyboardType: TextInputType.multiline,
                    controller: controller.remarkController),

                const SizedBox(height: 32.0),

                Center(
                  child: CameraButton(
                    size: 80.0,
                    imageUrl: _imageUrl0,
                    onImagePicked: (file) {
                      photoFile0 = file;
                    },
                  ),
                ),

                const SizedBox(height: 16.0),

                // Row with 4 smaller photo buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CameraButton(
                      size: 50.0,
                      imageUrl: _imageUrl1,
                      onImagePicked: (file) {
                        photoFile1 = file;
                      },
                    ),
                    CameraButton(
                      size: 50.0,
                      imageUrl: _imageUrl2,
                      onImagePicked: (file) {
                        photoFile2 = file;
                      },
                    ),
                    CameraButton(
                      size: 50.0,
                      imageUrl: _imageUrl3,
                      onImagePicked: (file) {
                        photoFile3 = file;
                      },
                    ),
                    CameraButton(
                      size: 50.0,
                      imageUrl: _imageUrl4,
                      onImagePicked: (file) {
                        photoFile4 = file;
                      },
                    ),
                  ],
                ),

                // CameraButton(size: 80.0),
                //
                // const SizedBox(height: 16.0),
                //
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     CameraButton(size: 50.0),
                //     CameraButton(size: 50.0),
                //     CameraButton(size: 50.0),
                //     CameraButton(size: 50.0),
                //   ],
                // ),

                const SizedBox(height: 32.0),

                SizedBox(
                  height: 220, // IMPORTANT
                  child: GetBuilder<NewCustomerDealerController>(
                    builder: (ctrl) {
                      if (ctrl.currentLatLng == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                              backgroundColor: Colors.redAccent),
                        );
                      }

                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: ctrl.currentLatLng ?? LatLng(0, 0),
                          zoom: 14,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        markers: ctrl.markers,
                        onMapCreated: (mapCtrl) {
                          ctrl.mapController = mapCtrl;
                        },
                        onTap: (latLng) {
                          ctrl.markers = {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: latLng,
                            ),
                          };
                          ctrl.currentLatLng = latLng;
                          ctrl.update(); // ✅ NOT controller.update()
                        },
                      );
                    },
                  ),
                ),

                // Container(
                //   height: 200,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.grey.shade300),
                //   ),
                //   child: ClipRRect(
                //     borderRadius: BorderRadius.circular(8),
                //     child: _currentPosition == null
                //         ? const Center(child: CircularProgressIndicator(backgroundColor: Colors.redAccent,))
                //         : GoogleMap(
                //       initialCameraPosition: CameraPosition(
                //         target: _currentPosition!,
                //         zoom: 14,
                //       ),
                //       myLocationEnabled: true,
                //       myLocationButtonEnabled: true,
                //       zoomControlsEnabled: true,
                //       markers: _markers,
                //       onMapCreated: (controllers) {
                //         _mapController = controllers;
                //       },
                //       onTap: (LatLng latLng) {
                //         setState(() {
                //           _markers = {
                //             Marker(
                //               markerId: const MarkerId('selected_location'),
                //               position: latLng,
                //             ),
                //           };
                //         });
                //       },
                //     ),
                //   ),
                // ),

                const SizedBox(height: 32.0), // Spacer before the submit button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  FocusScope.of(context).unfocus();

                  if (!_formKey.currentState!.validate()) {
                    final errorMsg = _getValidationError() ?? 'Please fill all required fields';
                     CustomSnackBar.show(message: errorMsg,isError: true);
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text(errorMsg)),
                    // );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    // Call the API with 5 photo paths
                    // final response = await controller.insertNewCustomerDealer(
                    //   photoPath: photoFile0?.path,
                    //   photoPath1: photoFile1?.path,
                    //   photoPath2: photoFile2?.path,
                    //   photoPath3: photoFile3?.path,
                    //   photoPath4: photoFile4?.path,
                    // );

                    final response = widget.portfolioId == null
                        ? await controller.insertNewCustomerDealer(
                      photoPath: photoFile0?.path,
                      photoPath1: photoFile1?.path,
                      photoPath2: photoFile2?.path,
                      photoPath3: photoFile3?.path,
                      photoPath4: photoFile4?.path,
                    )
                        : await controller.updateCustomerDealer(
                      portfolioId: widget.portfolioId!,
                      photoPath: photoFile0?.path,
                      photoPath1: photoFile1?.path,
                      photoPath2: photoFile2?.path,
                      photoPath3: photoFile3?.path,
                      photoPath4: photoFile4?.path,
                    );

                    // Check API success
                    if (response.status == "200") {
                      // Small delay to show loader effect
                      Future.delayed(const Duration(milliseconds: 500), () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response.message ?? 'Saved successfully')),
                        );

                        if (mounted) Navigator.of(context).pop(); // Navigate back
                      });
                    } else {
                      // API returned error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.message ?? 'Failed to save')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlavorConfig.instance.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : Text(
                  widget.portfolioId == null ? 'Save' : 'Update',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ),


              const SizedBox(height: 16.0), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    required String fieldName,
    required TextInputType keyboardType,
    required TextEditingController controller,
    int maxLines = 1,
    bool isMobile = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12.0),
            Expanded(
              child: TextFormField(
                controller: controller,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                keyboardType: keyboardType,
                maxLines: maxLines,
                maxLength: isMobile ? 10 : null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$fieldName is required';
                  }
                  if (isMobile) {
                    if (value.trim().length != 10) {
                      return 'Mobile no. must be exactly 10 digits';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                      return '$fieldName must contain only digits';
                    }
                  }
                  if (isEmail) {
                    final emailRegex = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _buildInputPhoneNumberField({
  required IconData icon,
  required String hintText,
  required TextInputType keyboardType,
  required TextEditingController controller,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 12.0),
          Expanded(
            child: TextFormField(
              controller: controller,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    ),
  );
}


class CameraButton extends StatefulWidget {
  final double size;
  final String? imageUrl; // network image URL if editing
  final Function(XFile?)? onImagePicked; // callback to pass picked image
  const CameraButton({super.key, required this.size, this.imageUrl, this.onImagePicked});

  @override
  _CameraButtonState createState() => _CameraButtonState();
}

class _CameraButtonState extends State<CameraButton> {
  File? _imageFile; // this is for displaying in UI
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // Resolve ImageProvider (local file takes priority over loaded network image)
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.imageUrl!);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(widget.size / 2),
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: imageProvider == null ? const Color(0xFF5DB9A6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
          image: imageProvider != null
              ? DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageProvider == null
            ? Center(
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2F4F5B), // dark lens
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.15,
                      height: widget.size * 0.15,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white54, // lens reflection
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Add Photo!"),
          content: const Text("Choose image source"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final XFile? xfile = await _pickFromCamera();
                if (xfile != null) {
                  final file = File(xfile.path); // convert XFile -> File
                  setState(() => _imageFile = file);
                  if (widget.onImagePicked != null) widget.onImagePicked!(xfile);
                }
              },
              child: const Text("Take Photo"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final XFile? xfile = await _pickFromGallery();
                if (xfile != null) {
                  final file = File(xfile.path); // convert XFile -> File
                  setState(() => _imageFile = file);
                  if (widget.onImagePicked != null) widget.onImagePicked!(xfile);
                }
              },
              child: const Text("Choose from Gallery"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<XFile?> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      preferredCameraDevice: CameraDevice.rear,
    );
    return image; // no need to wrap in XFile again
  }

  Future<XFile?> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    return image; // no need to wrap in XFile again
  }
}


// class CameraButton extends StatelessWidget {
//   final double size;
//   const CameraButton({super.key, required this.size});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(size / 2), // Ripple effect inside circle
//       onTap: () {
//         _showCameraDialog(context);
//       },
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           color: Colors.teal,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               spreadRadius: 1,
//               blurRadius: 3,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Icon(
//             Icons.camera_alt,
//             color: Colors.white,
//             size: size * 0.5, // proportional icon
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showCameraDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           title: const Text("Add Photo!"),
//           // content: const Text("Choose an option:"),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//
//                 final file = await pickFromCamera();
//
//                 if (file != null) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Photo captured successfully")),
//                   );
//
//                   // TODO:
//                   // 1️⃣ Save file to controller
//                   // 2️⃣ Upload to server
//                   // 3️⃣ Attach GPS metadata if needed
//                 }
//               },
//               child: const Text("Take Photo"),
//             ),
//
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<File?> pickFromCamera() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 70,
//       preferredCameraDevice: CameraDevice.rear,
//     );
//
//     if (image == null) return null;
//     return File(image.path);
//   }
// }
