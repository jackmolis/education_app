import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/providers/connectivity_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String pdfUrl;
  final String title;
  final String lessonId;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.lessonId,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;
  File? _localPdfFile;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pdf_${widget.lessonId}.pdf');
      final isOffline = ref.read(isOfflineProvider);

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPdfFile = file;
          });
        }
      } else {
        if (isOffline) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = "PDF not downloaded for offline viewing.";
            });
          }
          return;
        }

        // Online and file doesn't exist -> download it
        final dio = Dio();
        await dio.download(widget.pdfUrl, file.path);
        
        if (mounted) {
          setState(() {
            _localPdfFile = file;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load PDF: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 1) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.5;
              }
            },
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.5;
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: () {
              _pdfViewerController.previousPage();
            },
            tooltip: 'Previous Page',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () {
              _pdfViewerController.nextPage();
            },
            tooltip: 'Next Page',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (_localPdfFile != null)
            SfPdfViewer.file(
              _localPdfFile!,
              controller: _pdfViewerController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = details.description;
                  });
                }
              },
            ),
          if (_isLoading && _errorMessage == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing PDF...'),
                ],
              ),
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Offline Access Unavailable',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
