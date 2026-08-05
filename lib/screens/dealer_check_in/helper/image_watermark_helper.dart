import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageWatermarkHelper {
  /// Merges Rear photo and Front selfie photo side-by-side with a bottom location & timestamp banner.
  static Future<File> mergePhotosWithWatermark({
    required File backPhoto,
    required File? frontPhoto,
    required String address,
    required String dateTime,
  }) async {
    // 1. Decode back photo bytes
    final backBytes = await backPhoto.readAsBytes();
    final backCodec = await ui.instantiateImageCodec(backBytes);
    final backFrame = await backCodec.getNextFrame();
    final ui.Image backUiImg = backFrame.image;

    ui.Image? frontUiImg;
    if (frontPhoto != null && await frontPhoto.exists()) {
      try {
        final frontBytes = await frontPhoto.readAsBytes();
        final frontCodec = await ui.instantiateImageCodec(frontBytes);
        final frontFrame = await frontCodec.getNextFrame();
        frontUiImg = frontFrame.image;
      } catch (e) {
        debugPrint("Error decoding front photo: $e");
      }
    }

    // 2. Target Dimensions
    // Normalize image height to 1000px for crisp quality
    const double targetPhotoHeight = 1000.0;
    final double backWidth =
        (backUiImg.width / backUiImg.height) * targetPhotoHeight;
    final double frontWidth = frontUiImg != null
        ? (frontUiImg.width / frontUiImg.height) * targetPhotoHeight
        : 0.0;

    final double totalWidth =
        frontUiImg != null ? (backWidth + frontWidth) : backWidth;
    const double bannerHeight = 180.0;
    final double totalHeight = targetPhotoHeight + bannerHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
    );

    // 3. Draw Back Image on left
    canvas.drawImageRect(
      backUiImg,
      Rect.fromLTWH(
          0, 0, backUiImg.width.toDouble(), backUiImg.height.toDouble()),
      Rect.fromLTWH(0, 0, backWidth, targetPhotoHeight),
      Paint(),
    );

    // 4. Draw Front Image on right (if present)
    if (frontUiImg != null) {
      canvas.drawImageRect(
        frontUiImg,
        Rect.fromLTWH(
            0, 0, frontUiImg.width.toDouble(), frontUiImg.height.toDouble()),
        Rect.fromLTWH(backWidth, 0, frontWidth, targetPhotoHeight),
        Paint(),
      );

      // Draw white divider line between images
      final dividerPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 6.0;
      canvas.drawLine(
        Offset(backWidth, 0),
        Offset(backWidth, targetPhotoHeight),
        dividerPaint,
      );

      // Draw camera tags
      _drawLabelOnCanvas(canvas, "REAR CAMERA", 24, 24);
      _drawLabelOnCanvas(canvas, "FRONT SELFIE", backWidth + 24, 24);
    } else {
      _drawLabelOnCanvas(canvas, "REAR CAMERA", 24, 24);
    }

    final String locationText =
        address.isNotEmpty ? "Location: $address" : "Location: Not Available";
    final String dateText = dateTime.isNotEmpty ? "Date & Time: $dateTime" : "";

    // 6. Draw Dark Banner at Bottom
    final bannerPaint = Paint()..color = const Color(0xFF111111); // Solid dark black
    canvas.drawRect(
      Rect.fromLTWH(0, targetPhotoHeight, totalWidth, bannerHeight),
      bannerPaint,
    );

    // Top green accent border line for banner
    final borderPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 10.0;
    canvas.drawLine(
      Offset(0, targetPhotoHeight),
      Offset(totalWidth, targetPhotoHeight),
      borderPaint,
    );

    // Draw Location & Timestamp Text on Bottom Banner
    final locationTp = TextPainter(
      text: TextSpan(
        text: locationText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    locationTp.layout(maxWidth: totalWidth - 48);
    locationTp.paint(canvas, Offset(24, targetPhotoHeight + 20));

    if (dateText.isNotEmpty) {
      final dateTp = TextPainter(
        text: TextSpan(
          text: dateText,
          style: const TextStyle(
            color: Color(0xFFFFD54F), // Bright golden yellow for Date/Time
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dateTp.layout(maxWidth: totalWidth - 48);
      dateTp.paint(canvas, Offset(24, targetPhotoHeight + 110));
    }

    // 7. Convert Canvas to PNG byte data
    final picture = recorder.endRecording();
    final mergedUiImg =
        await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
    final byteData =
        await mergedUiImg.toByteData(format: ui.ImageByteFormat.png);

    // 8. Save merged file to temporary directory
    final tempDir = Directory.systemTemp;
    final mergedFilePath =
        "${tempDir.path}/MERGED_CHECKIN_${DateTime.now().millisecondsSinceEpoch}.png";
    final mergedFile = File(mergedFilePath);
    await mergedFile.writeAsBytes(byteData!.buffer.asUint8List());

    return mergedFile;
  }

  static void _drawLabelOnCanvas(
      Canvas canvas, String label, double x, double y) {
    final bgPaint = Paint()..color = const Color(0xCC000000);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final rect = Rect.fromLTWH(x - 10, y - 6, tp.width + 20, tp.height + 12);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    tp.paint(canvas, Offset(x, y));
  }
}
