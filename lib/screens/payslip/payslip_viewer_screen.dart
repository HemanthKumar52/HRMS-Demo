import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

/// Displays the payslip using the EXACT same template as the web app.
/// Fetches rendered HTML from the web backend and shows it in a WebView.
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
  final _noScreenshot = NoScreenshot.instance;
  WebViewController? _webController;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;
  int? _resolvedId;

  @override
  void initState() {
    super.initState();
    _noScreenshot.screenshotOff();
    _loadPayslip();
  }

  @override
  void dispose() {
    _noScreenshot.screenshotOn();
    super.dispose();
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

  Future<void> _loadPayslip() async {
    try {
      _resolvedId = await _resolvePayslipId();
      if (_resolvedId == null) {
        setState(() {
          _error = 'Payslip not found';
          _isLoading = false;
        });
        return;
      }

      // Try loading from mobile backend HTML endpoint first
      final headers = await ApiService.getAuthHeaders();
      final baseUrl = ApiService.currentBaseUrl;
      final response = await ApiService.getRaw(
        '$baseUrl/payslips/$_resolvedId/html',
        headers: headers,
      );

      if (response.statusCode == 200 && response.body.length > 100) {
        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..loadHtmlString(response.body);

        setState(() => _isLoading = false);
        return;
      }

      // If that fails, show error
      setState(() {
        _error = 'Could not load payslip template';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_resolvedId == null) return;
    setState(() => _isDownloading = true);
    HapticFeedback.mediumImpact();
    try {
      final response = await ApiService.getPayslipPdf(_resolvedId!);
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
          ),
        );
      } else {
        throw Exception('PDF not available');
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
                    child: const Icon(CupertinoIcons.arrow_down_doc, size: 22),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download PDF',
                    onPressed: _downloadPdf,
                  ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isApplePlatform
                ? const CupertinoActivityIndicator(radius: 14)
                : const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Loading payslip...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null || _webController == null) {
      return Center(
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
                      _loadPayslip();
                    },
                    child: const Text('Retry'),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadPayslip();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
          ],
        ),
      );
    }

    return WebViewWidget(controller: _webController!);
  }
}
