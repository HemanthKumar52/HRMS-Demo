// Round 3 admin sub-screens — Tier 3 + Tier 4.
// Bundled into one file to keep the round shippable. Each screen is small,
// list-style, and reuses the existing NeuCard / AppColors / fl_chart helpers.
//
// Screens included:
//   • AdminSystemStatsScreen          — disk / DB / media gauges
//   • AdminLiveActivityScreen         — today's punches with lat/lng feed
//   • AdminPushCampaignScreen         — send a notification to a filtered audience
//   • AdminFaceEnrollmentsScreen      — list + delete enrolled face data
//   • AdminWebhooksScreen             — CRUD webhook URLs + secrets + events
//   • AdminGdprToolsScreen            — per-user GDPR export + anonymize
//   • AdminRetentionPoliciesScreen    — per-model max_days policies
//   • AdminConsentLedgerScreen        — read-only consent history feed

// Round 3 admin sub-screens with iOS Cupertino support.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

// ──────────────────────────────────────────────────────────────────────────
// 1. SYSTEM STATS — disk / DB / media gauges (uses fl_chart for the donut)
// ──────────────────────────────────────────────────────────────────────────
class AdminSystemStatsScreen extends StatefulWidget {
  const AdminSystemStatsScreen({super.key});

  @override
  State<AdminSystemStatsScreen> createState() => _AdminSystemStatsScreenState();
}

class _AdminSystemStatsScreenState extends State<AdminSystemStatsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await ApiService.getAdminSystemStats();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _humanSize(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('System Stats'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Disk gauge
                  NeuCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disk',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  value:
                                      ((_data['disk']?['used_bytes'] ?? 0)
                                              as num)
                                          .toDouble(),
                                  color: AppColors.danger,
                                  title: 'Used',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  radius: 40,
                                ),
                                PieChartSectionData(
                                  value:
                                      ((_data['disk']?['free_bytes'] ?? 0)
                                              as num)
                                          .toDouble(),
                                  color: AppColors.success,
                                  title: 'Free',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  radius: 40,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatLine(
                          label: 'Used',
                          value: _humanSize(
                            ((_data['disk']?['used_bytes'] ?? 0) as num),
                          ),
                          color: AppColors.danger,
                        ),
                        _StatLine(
                          label: 'Free',
                          value: _humanSize(
                            ((_data['disk']?['free_bytes'] ?? 0) as num),
                          ),
                          color: AppColors.success,
                        ),
                        _StatLine(
                          label: 'Total',
                          value: _humanSize(
                            ((_data['disk']?['total_bytes'] ?? 0) as num),
                          ),
                          color: AppColors.primary,
                        ),
                        _StatLine(
                          label: '% Used',
                          value: '${_data['disk']?['percent_used'] ?? 0}%',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // DB
                  NeuCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_data['engine'] ?? '-'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        _StatLine(
                          label: 'Size',
                          value: _humanSize(
                            ((_data['db_size_bytes'] ?? 0) as num),
                          ),
                          color: AppColors.primary,
                        ),
                        _StatLine(
                          label: 'Audit log rows',
                          value: '${_data['audit_log_rows'] ?? 0}',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Media
                  NeuCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatLine(
                          label: 'Total size',
                          value: _humanSize(
                            ((_data['media']?['size_bytes'] ?? 0) as num),
                          ),
                          color: AppColors.primary,
                        ),
                        _StatLine(
                          label: 'File count',
                          value: '${_data['media']?['file_count'] ?? 0}',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 2. LIVE ACTIVITY — today's punches with lat/lng (list-style "map")
// ──────────────────────────────────────────────────────────────────────────
class AdminLiveActivityScreen extends StatefulWidget {
  const AdminLiveActivityScreen({super.key});

  @override
  State<AdminLiveActivityScreen> createState() =>
      _AdminLiveActivityScreenState();
}

class _AdminLiveActivityScreenState extends State<AdminLiveActivityScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _asOf = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refreshSilently();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getAdminLiveActivity();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
      _asOf = r['as_of']?.toString() ?? '';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshSilently() async {
    try {
      final r = await ApiService.getAdminLiveActivity();
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
        _asOf = r['as_of']?.toString() ?? '';
      });
    } catch (_) {}
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '—';
    try {
      final parts = iso.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final ampm = h >= 12 ? 'PM' : 'AM';
      return '${(h % 12 == 0 ? 12 : h % 12).toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Live Activity'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "Today's punches (${_items.length}) · ${_asOf.isNotEmpty ? _asOf.split('T').last.substring(0, 8) : ''}",
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  final r = _items[i - 1];
                  final hasLoc = r['lat'] != null && r['lng'] != null;
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasLoc
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasLoc
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            color: hasLoc
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['employee_name']?.toString() ?? '—',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'in ${_fmtTime(r['punch_in']?.toString())} · ${r['source'] ?? ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (hasLoc)
                                Text(
                                  '${(r['lat'] as num).toStringAsFixed(4)}, ${(r['lng'] as num).toStringAsFixed(4)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (r['punch_out'] != null)
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 3. PUSH CAMPAIGN — send a notification to a filtered audience
// ──────────────────────────────────────────────────────────────────────────
class AdminPushCampaignScreen extends StatefulWidget {
  const AdminPushCampaignScreen({super.key});

  @override
  State<AdminPushCampaignScreen> createState() =>
      _AdminPushCampaignScreenState();
}

class _AdminPushCampaignScreenState extends State<AdminPushCampaignScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final r = await ApiService.sendAdminPushCampaign(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sent to ${r['sent']} ${_audience == 'managers' ? 'manager' : 'employee'}(s)",
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _title.clear();
      _body.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Push Announcement'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compose',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Body',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Audience', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in const ['all', 'managers'])
                      ChoiceChip(
                        label: Text(a),
                        selected: _audience == a,
                        onSelected: (_) => setState(() => _audience = a),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Sending…' : 'Send'),
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
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 4. FACE ENROLLMENTS — list + delete
// ──────────────────────────────────────────────────────────────────────────
class AdminFaceEnrollmentsScreen extends StatefulWidget {
  const AdminFaceEnrollmentsScreen({super.key});

  @override
  State<AdminFaceEnrollmentsScreen> createState() =>
      _AdminFaceEnrollmentsScreenState();
}

class _AdminFaceEnrollmentsScreenState
    extends State<AdminFaceEnrollmentsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getAdminFaceEnrollments();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final ok = await (isApplePlatform
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Delete face data?'),
              content: Text(
                '${r['employee_name']} will need to re-enroll their face.',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          )
        : showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete face data?'),
              content: Text(
                '${r['employee_name']} will need to re-enroll their face.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ));
    if (ok != true) return;
    try {
      await ApiService.deleteAdminFaceEnrollment(
        (r['employee_id'] as num).toInt(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Face data deleted')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _addEnrollment() async {
    // 1. Pick employee by searching
    final employees = await ApiService.getEmployees();
    if (!mounted) return;
    final emp = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EmployeePickerSheet(
        employees: List<Map<String, dynamic>>.from(employees),
      ),
    );
    if (emp == null || !mounted) return;

    // 2. Capture photo
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      final shot = await controller.takePicture();
      await controller.dispose();

      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrolling face...'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      await ApiService.enrollFace(
        employeeId: (emp['id'] as num).toInt(),
        imageBase64: b64,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face enrolled for ${emp['name']}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Face Enrollments'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEnrollment,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.isEmpty ? 1 : _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('No face enrollments yet. Tap + to add.'),
                      ),
                    );
                  }
                  final r = _items[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.12,
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      '${r['employee_name']}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${r['num_samples']} sample(s)${r['updated_at'] != null ? ' · ${DateFormat('dd MMM').format(DateTime.parse(r['updated_at'].toString()).toLocal())}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: () => _delete(r),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _EmployeePickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  const _EmployeePickerSheet({required this.employees});

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  String _search = '';

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return widget.employees;
    final q = _search.toLowerCase();
    return widget.employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Select Employee',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final e = _filtered[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      (e['name']?.toString() ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    e['name']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    e['email']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => Navigator.pop(context, e),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 5. WEBHOOKS — CRUD
// ──────────────────────────────────────────────────────────────────────────
class AdminWebhooksScreen extends StatefulWidget {
  const AdminWebhooksScreen({super.key});

  @override
  State<AdminWebhooksScreen> createState() => _AdminWebhooksScreenState();
}

class _AdminWebhooksScreenState extends State<AdminWebhooksScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getAdminWebhooks();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editor({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WebhookEditor(existing: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await ApiService.createAdminWebhook(result);
      } else {
        await ApiService.updateAdminWebhook(
          (existing['id'] as num).toInt(),
          result,
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    try {
      await ApiService.deleteAdminWebhook((r['id'] as num).toInt());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Webhooks'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.length + (_items.isEmpty ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('No webhooks yet — tap + to add one'),
                      ),
                    );
                  }
                  final r = _items[i];
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.webhook_rounded,
                        color: ((r['is_active'] ?? true) as bool)
                            ? AppColors.success
                            : Colors.grey,
                      ),
                      title: Text(
                        '${r['name']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${r['url']}\nevents: ${(r['events'] as List?)?.join(", ")}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _editor(existing: r);
                          } else if (v == 'delete') {
                            await _delete(r);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_rounded),
                              title: Text('Edit'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                              ),
                              title: Text('Delete'),
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _editor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Hook'),
      ),
    );
  }
}

class _WebhookEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _WebhookEditor({this.existing});

  @override
  State<_WebhookEditor> createState() => _WebhookEditorState();
}

class _WebhookEditorState extends State<_WebhookEditor> {
  late final _name = TextEditingController(
    text: widget.existing?['name']?.toString() ?? '',
  );
  late final _url = TextEditingController(
    text: widget.existing?['url']?.toString() ?? '',
  );
  late final _events = TextEditingController(
    text:
        ((widget.existing?['events'] as List?)?.join(',')) ??
        'request_approved,request_rejected',
  );
  late final _secret = TextEditingController(
    text: widget.existing?['secret']?.toString() ?? '',
  );
  late bool _active = (widget.existing?['is_active'] as bool?) ?? true;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _events.dispose();
    _secret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'New webhook' : 'Edit webhook',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _f(_name, 'Name'),
          const SizedBox(height: 12),
          _f(_url, 'URL'),
          const SizedBox(height: 12),
          _f(_events, 'Events (comma-separated)'),
          const SizedBox(height: 12),
          _f(_secret, 'Secret (HMAC-SHA256)'),
          SwitchListTile.adaptive(
            title: const Text('Active'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_url.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL required')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'url': _url.text.trim(),
                      'events': _events.text.trim(),
                      'secret': _secret.text.trim(),
                      'is_active': _active,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String label) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// 6. GDPR TOOLS — export + delete a single user
// ──────────────────────────────────────────────────────────────────────────
class AdminGdprToolsScreen extends StatefulWidget {
  const AdminGdprToolsScreen({super.key});

  @override
  State<AdminGdprToolsScreen> createState() => _AdminGdprToolsScreenState();
}

class _AdminGdprToolsScreenState extends State<AdminGdprToolsScreen> {
  final _idCtl = TextEditingController();
  Map<String, dynamic>? _result;
  bool _busy = false;

  @override
  void dispose() {
    _idCtl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final id = int.tryParse(_idCtl.text.trim());
    if (id == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      _result = await ApiService.adminGdprExport(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final id = int.tryParse(_idCtl.text.trim());
    if (id == null) return;
    final ok = await (isApplePlatform
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Anonymize this user?'),
              content: const Text(
                'PII (name, email, phone, address) will be replaced with anonymized values. '
                'Face data will be deleted. The user will be deactivated and all their tokens revoked. '
                'Aggregates (attendance count, leave totals) are preserved.',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Anonymize'),
                ),
              ],
            ),
          )
        : showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Anonymize this user?'),
              content: const Text(
                'PII (name, email, phone, address) will be replaced with anonymized values. '
                'Face data will be deleted. The user will be deactivated and all their tokens revoked. '
                'Aggregates (attendance count, leave totals) are preserved.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Anonymize',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ));
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ApiService.adminGdprDelete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User anonymized')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('GDPR Tools'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per-user actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find user IDs in the Users tab.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _idCtl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _export,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text('Anonymize'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            NeuCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export preview',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in _result!.entries.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${entry.key}: ${entry.value is List
                            ? "${(entry.value as List).length} item(s)"
                            : entry.value is Map
                            ? "{...}"
                            : entry.value}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy raw JSON'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: jsonEncode(_result)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 7. RETENTION POLICIES — per-table max-days
// ──────────────────────────────────────────────────────────────────────────
class AdminRetentionPoliciesScreen extends StatefulWidget {
  const AdminRetentionPoliciesScreen({super.key});

  @override
  State<AdminRetentionPoliciesScreen> createState() =>
      _AdminRetentionPoliciesScreenState();
}

class _AdminRetentionPoliciesScreenState
    extends State<AdminRetentionPoliciesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getAdminRetentionPolicies();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final modelCtl = TextEditingController(
      text: existing?['model_name']?.toString() ?? '',
    );
    final daysCtl = TextEditingController(
      text: existing?['max_days']?.toString() ?? '365',
    );
    final title = existing == null ? 'New retention policy' : 'Edit policy';
    void Function() onSave(BuildContext ctx) =>
        () => Navigator.pop(ctx, {
          'model_name': modelCtl.text.trim().toLowerCase(),
          'max_days': int.tryParse(daysCtl.text.trim()) ?? 365,
        });

    final result = await (isApplePlatform
        ? showCupertinoDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: Text(title),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoTextField(
                      controller: modelCtl,
                      enabled: existing == null,
                      placeholder: 'Model name (e.g. auditlog)',
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: daysCtl,
                      keyboardType: TextInputType.number,
                      placeholder: 'Keep for (days)',
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: onSave(ctx),
                  child: const Text('Submit'),
                ),
              ],
            ),
          )
        : showDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: modelCtl,
                    enabled: existing == null,
                    decoration: const InputDecoration(
                      labelText: 'Model name (e.g. auditlog)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: daysCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Keep for (days)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: onSave(ctx),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ));
    if (result == null) return;
    try {
      await ApiService.saveAdminRetentionPolicy(
        result['model_name'] as String,
        result['max_days'] as int,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Retention Policies'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.length + (_items.isEmpty ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'No retention policies — add one to start auto-purging old data',
                        ),
                      ),
                    );
                  }
                  final r = _items[i];
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.policy_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        '${r['model_name']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        'Keep for ${r['max_days']} days · ${(r['is_active'] ?? false) as bool ? "active" : "paused"}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _edit(existing: r),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Policy'),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 8. CONSENT LEDGER — read-only feed
// ──────────────────────────────────────────────────────────────────────────
class AdminConsentLedgerScreen extends StatefulWidget {
  const AdminConsentLedgerScreen({super.key});

  @override
  State<AdminConsentLedgerScreen> createState() =>
      _AdminConsentLedgerScreenState();
}

class _AdminConsentLedgerScreenState extends State<AdminConsentLedgerScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getAdminConsentLedger();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Consent Ledger'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.length + (_items.isEmpty ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No consent records yet')),
                    );
                  }
                  final r = _items[i];
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.gavel_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        '${r['user_name'] ?? 'user #${r['user_id']}'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${r['consent_key']} · ${r['ip_address'] ?? ''}',
                      ),
                      trailing: Text(
                        DateFormat('dd MMM, hh:mm a').format(
                          DateTime.parse(r['accepted_at'].toString()).toLocal(),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
