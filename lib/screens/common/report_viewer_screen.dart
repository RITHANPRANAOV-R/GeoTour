import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/file_service.dart';

class ReportViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const ReportViewerScreen({
    super.key,
    required this.url,
    this.title = "Medical Report",
  });

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  bool get _isPdf =>
      widget.url.toLowerCase().contains('.pdf') ||
      widget.url.contains('/raw/upload/');

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final fileName =
        "Medical_Report_${DateTime.now().millisecondsSinceEpoch}.${_isPdf ? 'pdf' : 'jpg'}";

    await FileService.downloadFile(
      context: context,
      url: widget.url,
      fileName: fileName,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: _downloadFile,
            ),
        ],
      ),
      body: _isPdf ? _buildPdfViewer() : _buildImageViewer(),
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (details) {
        debugPrint("PDF Load Failed: ${details.description}");
      },
    );
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.url),
      loadingBuilder: (context, event) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Text(
          "Could not load image",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
    );
  }
}
