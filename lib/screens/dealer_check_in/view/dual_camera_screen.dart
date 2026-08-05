import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterman_iattandance/widget/custom_snackbar.dart';

class DualCameraScreen extends StatefulWidget {
  const DualCameraScreen({super.key});

  @override
  State<DualCameraScreen> createState() => _DualCameraScreenState();
}

class _DualCameraScreenState extends State<DualCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String _captureStepText = "Step 1 of 2: Rear Camera";
  int _currentLensDirection = 0; // 0: back, 1: front

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        AppSnackBar.error("Error", "No camera available on this device");
        return;
      }

      int backIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      int initIndex = backIndex != -1 ? backIndex : 0;
      await _setupController(_cameras[initIndex]);
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _currentLensDirection =
            camera.lensDirection == CameraLensDirection.front ? 1 : 0;
      });
    }

    if (_controller != null) {
      final oldController = _controller;
      _controller = null;
      try {
        await oldController?.dispose();
      } catch (e) {
        debugPrint("Error disposing old camera controller: $e");
      }
    }

    final newController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await newController.initialize();
      if (mounted) {
        setState(() {
          _controller = newController;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Setup Controller Error: $e");
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _captureBothCameras() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
        _captureStepText = "Capturing Rear Photo...";
      });

      // 1. Capture Back
      final backImage = await _controller!.takePicture();

      // CRITICAL: Wait before switching cameras so the native capture process finishes
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Switch to Front
      int frontIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );

      if (frontIndex != -1) {
        if (mounted) {
          setState(() {
            _captureStepText = "Switching to Front Camera...";
          });
        }
        await _setupController(_cameras[frontIndex]);

        // Increased delay to let camera settle fully on slower devices
        await Future.delayed(const Duration(milliseconds: 1200));

        if (_controller != null && _controller!.value.isInitialized) {
          if (mounted) {
            setState(() {
              _captureStepText = "Capturing Front Photo...";
            });
          }
          // 3. Capture Front
          final frontImage = await _controller!.takePicture();

          // Wait briefly before popping to prevent native camera crash upon immediate disposal
          await Future.delayed(const Duration(milliseconds: 500));

          Get.back(result: {'back': backImage.path, 'front': frontImage.path});
        } else {
          Get.back(result: {'back': backImage.path, 'front': ''});
        }
      } else {
        // No front camera, just return back
        Get.back(result: {'back': backImage.path, 'front': ''});
      }
    } catch (e) {
      debugPrint('Capture Error: $e');
      if (mounted) {
        AppSnackBar.error('Error', 'Failed to capture photos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _isInitialized &&
        _controller != null &&
        _controller!.value.isInitialized;

    if (!isReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _currentLensDirection == 0
                ? "Rear Camera (Step 1/2)"
                : "Switching to Front Camera (Step 2/2)...",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _isCapturing
                    ? _captureStepText
                    : _currentLensDirection == 0
                        ? "Initializing Rear Camera..."
                        : "Initializing Front Selfie Camera...",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _currentLensDirection == 0
              ? "Rear Camera (Step 1/2)"
              : "Front Camera (Step 2/2)",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Preview safely guarded
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Top Instruction Banner
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentLensDirection == 0
                        ? Icons.camera_rear
                        : Icons.camera_front,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _currentLensDirection == 0
                          ? "Point rear camera at location/client & tap capture"
                          : "Look at the front camera for selfie",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay when capturing
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _captureStepText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please hold the camera steady",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Control Panel
          if (!_isCapturing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _captureBothCameras,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black87,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap to Capture Dual Photo (Rear + Front)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
