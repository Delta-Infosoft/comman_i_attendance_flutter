import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterman_iattandance/screens/tour_voucher/model/Insert_tour_voucher_model.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final UploadedDocument document;

  const DocumentPreviewScreen({super.key, required this.document});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(widget.document.fileName);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.document.fileName,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _previousScale = _scale;
        },
        onScaleUpdate: (details) {
          setState(() {
            _scale = (_previousScale * details.scale).clamp(0.5, 5.0);
          });
        },
        onDoubleTap: () {
          setState(() {
            _scale = _scale == 1.0 ? 2.0 : 1.0;
          });
        },
        child: Center(
          child: isImage ? _buildImagePreview() : _buildDocumentPreview(),
        ),
      ),
      bottomNavigationBar: _buildBottomInfo(),
    );
  }

  Widget _buildImagePreview() {
    return Transform.scale(
      scale: _scale,
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.5,
        maxScale: 5.0,
        child: Image.network(
          widget.document.file1,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${widget.document.file1}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getFileIcon(widget.document.fileName),
          color: Colors.white,
          size: 100,
        ),
        const SizedBox(height: 20),
        Text(
          _getFileType(widget.document.fileName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.document.fileName,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('File:', widget.document.fileName),
            const SizedBox(height: 8),
            _buildInfoItem('Uploaded:', widget.document.insertedOn),
            const SizedBox(height: 8),
            _buildInfoItem('Type:', _getFileType(widget.document.fileName)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return Icons.image;
    } else if (['pdf'].contains(extension)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(extension)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(extension)) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return 'Image';
    } else if (['pdf'].contains(extension)) {
      return 'PDF';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'Word Document';
    } else if (['xls', 'xlsx'].contains(extension)) {
      return 'Excel Sheet';
    } else {
      return 'File';
    }
  }
}
