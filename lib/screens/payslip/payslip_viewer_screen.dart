import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PayslipViewerScreen extends StatefulWidget {
  final String month;
  final int year;
  final int? payslipId;
  const PayslipViewerScreen({super.key, required this.month, required this.year, this.payslipId});

  @override
  State<PayslipViewerScreen> createState() => _PayslipViewerScreenState();
}

class _PayslipViewerScreenState extends State<PayslipViewerScreen> {
  PdfControllerPinch? _pdfController;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _error;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      int? payslipId = widget.payslipId;

      // If no ID, fetch by month/year first
      if (payslipId == null) {
        final monthIndex = [
          'January','February','March','April','May','June',
          'July','August','September','October','November','December'
        ].indexOf(widget.month) + 1;
        final payslip = await ApiService.get('/payslips?month=$monthIndex&year=${widget.year}');
        payslipId = payslip['id'] is int ? payslip['id'] : int.tryParse(payslip['id']?.toString() ?? '');
      }

      if (payslipId == null) {
        setState(() { _error = 'Payslip not found'; _isLoading = false; });
        return;
      }

      // Download PDF bytes from the API
      final response = await ApiService.getPayslipPdf(payslipId);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Save to temp file
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/payslip_${payslipId}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        _pdfPath = file.path;

        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(file.path),
        );
        setState(() => _isLoading = false);
      } else {
        setState(() { _error = 'Failed to load PDF (${response.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.month} ${widget.year} Payslip'),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Loading payslip PDF...', style: TextStyle(color: Colors.grey)),
              ],
            ))
          : _error != null || _pdfController == null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('PDF not available', style: Theme.of(context).textTheme.titleMedium),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                      ),
                    ],
                  ],
                ))
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
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                          const SizedBox(height: 16),
                          Text('Failed to render PDF', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
