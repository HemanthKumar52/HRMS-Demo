import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

/// Admin → Settings → Bulk Employees. Export CSV (browser download) +
/// Import CSV (multipart upload). Dry-run validation before commit.
class AdminCsvEmployeesScreen extends StatefulWidget {
  const AdminCsvEmployeesScreen({super.key});

  @override
  State<AdminCsvEmployeesScreen> createState() =>
      _AdminCsvEmployeesScreenState();
}

class _AdminCsvEmployeesScreenState extends State<AdminCsvEmployeesScreen> {
  bool _busy = false;
  Map<String, dynamic>? _lastResult;

  Future<void> _exportCsv() async {
    final url = Uri.parse(ApiService.adminEmployeesExportUrl());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open browser', AppColors.danger);
    }
  }

  Future<void> _importCsv({bool dryRun = true}) async {
    // Simple CSV picker via image_picker is not appropriate; the cleanest
    // path without adding `file_picker` is to ask the user to upload from
    // a local path typed in. For now we use a quick fallback: let them pick
    // the CSV via a text input, then read + POST it as multipart.
    final path = await _pickFilePath();
    if (path == null) return;

    setState(() {
      _busy = true;
      _lastResult = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final uri = Uri.parse(
        '${ApiService.baseUrl}/admin/employees/import-csv?dry_run=${dryRun ? 'true' : 'false'}',
      );
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', path));
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      if (!mounted) return;
      if (streamed.statusCode == 200) {
        setState(() => _lastResult = jsonDecode(body) as Map<String, dynamic>);
        _snack(
          dryRun ? 'Dry-run complete — review below' : 'Import complete',
          dryRun ? AppColors.warning : AppColors.success,
        );
      } else {
        _snack('Failed (${streamed.statusCode}): $body', AppColors.danger);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _pickFilePath() async {
    // Minimal manual file path entry — keeps deps lean. Replace with
    // file_picker in a future round for a real picker.
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV file path'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '/Users/you/employees.csv',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final p = ctrl.text.trim();
              if (p.isEmpty || !File(p).existsSync()) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(const SnackBar(content: Text('File not found')));
                return;
              }
              Navigator.pop(ctx, p);
            },
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Bulk Employees',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export employees as CSV',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Downloads every employee row from the database.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Download CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import employees from CSV',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Required columns: badge_id, first_name, last_name, email, phone, gender, dob, department, designation',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _importCsv(dryRun: true),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Dry-run'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _importCsv(dryRun: false),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Import'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            NeuCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_lastResult!['dry_run'] as bool? ?? false)
                        ? 'Dry-run summary'
                        : 'Import summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Created: ${_lastResult!['created'] ?? 0}'),
                  Text('Updated: ${_lastResult!['updated'] ?? 0}'),
                  Text(
                    'Errors: ${(_lastResult!['errors'] as List?)?.length ?? 0}',
                  ),
                  if ((_lastResult!['errors'] as List?)?.isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 10),
                    for (final err in (_lastResult!['errors'] as List).take(20))
                      Text(
                        '• line ${err['line']}: ${err['reason']}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
