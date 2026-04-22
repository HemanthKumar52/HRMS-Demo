import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

/// Displays the payslip using the same HTML template as the web app.
/// Shows the HTML payslip inline in a WebView, with download PDF option.
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
  WebViewController? _webController;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayslipHTML();
  }

  Future<int?> _resolvePayslipId() async {
    if (widget.payslipId != null) return widget.payslipId;

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
    final payslips = List<Map<String, dynamic>>.from(list['payslips'] ?? []);
    final match = payslips
        .where((p) => (p['month'] as num?)?.toInt() == monthIndex)
        .toList();
    if (match.isNotEmpty) {
      return (match.first['id'] as num?)?.toInt();
    }
    return null;
  }

  Future<void> _loadPayslipHTML() async {
    try {
      final payslipId = await _resolvePayslipId();
      if (payslipId == null) {
        setState(() {
          _error = 'Payslip not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch HTML from the mobile backend (same template as web)
      final headers = await ApiService.getAuthHeaders();
      final baseUrl = ApiService.currentBaseUrl;
      final url = '$baseUrl/payslips/$payslipId/html';

      final response = await ApiService.getRaw(url, headers: headers);

      if (response.statusCode == 200) {
        final htmlContent = response.body;

        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..loadHtmlString(htmlContent);

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = 'Failed to load payslip (${response.statusCode})';
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
    setState(() => _isDownloading = true);
    HapticFeedback.mediumImpact();
    try {
      final payslipId = await _resolvePayslipId();
      if (payslipId == null) throw Exception('Payslip not found');

      final response = await ApiService.getPayslipPdf(payslipId);
      if (response.statusCode == 200 && response.bodyBytes.length > 500) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'payslip_${widget.month}_${widget.year}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

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
      } else {
        throw Exception('PDF generation failed');
      }
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
    if (mounted) setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: adaptiveAppBar(
        context: context,
        title: '${widget.month} ${widget.year}',
        showBackButton: true,
        actions: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 10)
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
            )
          else
            isApplePlatform
                ? CupertinoButton(
                    padding: const EdgeInsets.only(right: 16),
                    onPressed: _downloadPdf,
                    child: const Icon(
                      CupertinoIcons.arrow_down_doc,
                      size: 22,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download PDF',
                    onPressed: _downloadPdf,
                  ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isApplePlatform
                      ? const CupertinoActivityIndicator(radius: 14)
                      : const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading payslip...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null || _webController == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isApplePlatform
                        ? CupertinoIcons.doc_text
                        : Icons.description_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Could not load payslip',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  isApplePlatform
                      ? CupertinoButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadPayslipHTML();
                          },
                          child: const Text('Retry'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadPayslipHTML();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                ],
              ),
            )
          : WebViewWidget(controller: _webController!),
    );
  }
}
