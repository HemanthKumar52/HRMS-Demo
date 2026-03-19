import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../theme/app_theme.dart';

class PayslipViewerScreen extends StatefulWidget {
  final String month;
  final int year;
  const PayslipViewerScreen({super.key, required this.month, required this.year});

  @override
  State<PayslipViewerScreen> createState() => _PayslipViewerScreenState();
}

class _PayslipViewerScreenState extends State<PayslipViewerScreen> {
  late PdfControllerPinch _pdfController;
  int _totalPages = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/sample.pdf'),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        onDocumentLoaded: (document) {
          setState(() {
            _totalPages = document.pagesCount;
          });
        },
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
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
                Text(
                  'Failed to load PDF',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
