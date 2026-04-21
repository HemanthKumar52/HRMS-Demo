import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Displays the payslip PDF fetched from the web backend — same template
/// as the web app with company logo, earnings/deductions tables, YTD.
class PayslipViewerScreen extends StatefulWidget {
  final String month;
  final int year;
  final int? payslipId;
  const PayslipViewerScreen({
    super.key,
    required this.month,
    required this.year,
    this.payslipId,
  });

  @override
  State<PayslipViewerScreen> createState() => _PayslipViewerScreenState();
}

class _PayslipViewerScreenState extends State<PayslipViewerScreen> {
  PdfControllerPinch? _pdfController;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _error;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      int? payslipId = widget.payslipId;

      if (payslipId == null) {
        final monthIndex =
            [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ].indexOf(widget.month) +
            1;
        final list = await ApiService.getPayslipsList(year: widget.year);
        final payslips = List<Map<String, dynamic>>.from(
          list['payslips'] ?? [],
        );
        final match = payslips
            .where((p) => (p['month'] as num?)?.toInt() == monthIndex)
            .toList();
        if (match.isNotEmpty) {
          payslipId = (match.first['id'] as num?)?.toInt();
        }
      }

      if (payslipId == null) {
        setState(() {
          _error = 'Payslip not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch PDF via ApiService — this calls the web backend's PDF API
      final response = await ApiService.getPayslipPdf(payslipId);

      if (response.statusCode == 200 && response.bodyBytes.length > 500) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/payslip_$payslipId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        _savedPath = file.path;

        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(file.path),
        );
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = 'Failed to load PDF (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_savedPath == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'payslip_${widget.month}_${widget.year}.pdf';
      final dest = File('${dir.path}/$fileName');
      await File(_savedPath!).copy(dest.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Downloaded: $fileName')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.month} ${widget.year}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_savedPath != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download PDF',
              onPressed: _downloadPdf,
            ),
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading payslip...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null || _pdfController == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PDF not available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : PdfViewPinch(
              controller: _pdfController!,
              onDocumentLoaded: (document) {
                setState(() => _totalPages = document.pagesCount);
              },
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                errorBuilder: (_, error) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to render PDF',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
