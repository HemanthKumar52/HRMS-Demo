import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

class AdminBiometricDevicesScreen extends StatefulWidget {
  const AdminBiometricDevicesScreen({super.key});

  @override
  State<AdminBiometricDevicesScreen> createState() =>
      _AdminBiometricDevicesScreenState();
}

class _AdminBiometricDevicesScreenState
    extends State<AdminBiometricDevicesScreen> {
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
      final r = await ApiService.getAdminBiometricDevices();
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DeviceEditor(existing: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await ApiService.createAdminBiometricDevice(result);
        _showSnack('Device added', AppColors.success);
      } else {
        await ApiService.updateAdminBiometricDevice(
          existing['id'].toString(),
          result,
        );
        _showSnack('Device updated', AppColors.success);
      }
      await _load();
    } catch (e) {
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row, bool active) async {
    try {
      await ApiService.updateAdminBiometricDevice(
        row['id'].toString(),
        {'is_active': active},
      );
      await _load();
    } catch (e) {
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text('Remove "${row['name']}"?'),
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
    );
    if (ok != true) return;
    try {
      await ApiService.deleteAdminBiometricDevice(row['id'].toString());
      _showSnack('Deleted', AppColors.danger);
      await _load();
    } catch (e) {
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'zk':
        return Icons.fingerprint;
      case 'cosec':
        return Icons.face_retouching_natural_rounded;
      case 'dahua':
        return Icons.face_retouching_natural_rounded;
      case 'anviz':
        return Icons.cloud_sync_rounded;
      case 'etimeoffice':
        return Icons.access_time_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'zk':
        return AppColors.primary;
      case 'cosec':
        return AppColors.secondary;
      case 'dahua':
        return AppColors.success;
      case 'anviz':
        return AppColors.warning;
      case 'etimeoffice':
        return const Color(0xFF0EA5E9);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Biometric Devices',
        showBackButton: true,
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Biometric devices are managed via the web app.\n'
                    'In production, both apps share the same database.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.fingerprint,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text('No biometric devices configured'),
                              SizedBox(height: 4),
                              Text(
                                'Tap + to add a device',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = _items[i];
                        final isActive = (r['is_active'] ?? true) as bool;
                        final type = r['machine_type']?.toString();
                        final lastSync = r['last_sync']?.toString();
                        String syncText = 'Never synced';
                        if (lastSync != null) {
                          try {
                            syncText =
                                'Last sync: ${DateFormat('dd MMM, hh:mm a').format(DateTime.parse(lastSync).toLocal())}';
                          } catch (_) {
                            syncText = 'Last sync: $lastSync';
                          }
                        }
                        return NeuCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _colorForType(
                                    type,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconForType(type),
                                  color: _colorForType(type),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name']?.toString() ?? '—',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r['machine_type_label']?.toString() ?? '',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if ((r['machine_ip'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        '${r['machine_ip']}${r['port'] != null ? ':${r['port']}' : ''}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _Pill(
                                          text:
                                              r['direction_label']
                                                  ?.toString() ??
                                              'System',
                                          color: AppColors.primary,
                                        ),
                                        if ((r['is_scheduler'] ?? false)
                                            as bool) ...[
                                          const SizedBox(width: 6),
                                          _Pill(
                                            text:
                                                'Poll: ${r['scheduler_duration']}',
                                            color: AppColors.success,
                                          ),
                                        ],
                                        if ((r['is_live'] ?? false)
                                            as bool) ...[
                                          const SizedBox(width: 6),
                                          const _Pill(
                                            text: 'LIVE',
                                            color: AppColors.danger,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      syncText,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: isActive,
                                activeTrackColor: AppColors.success,
                                onChanged: (v) => _toggleActive(r, v),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                ),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _openEditor(existing: r);
                                  }
                                  if (action == 'delete') {
                                    _delete(r);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Device'),
      ),
    );
  }
}

// ── Editor bottom sheet ──────────────────────────────────────────
class _DeviceEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _DeviceEditor({this.existing});

  @override
  State<_DeviceEditor> createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<_DeviceEditor> {
  late final _name = TextEditingController(
    text: widget.existing?['name']?.toString() ?? '',
  );
  late final _ip = TextEditingController(
    text: widget.existing?['machine_ip']?.toString() ?? '',
  );
  late final _port = TextEditingController(
    text: widget.existing?['port']?.toString() ?? '',
  );
  late String _type = widget.existing?['machine_type']?.toString() ?? 'zk';
  late String _direction =
      widget.existing?['device_direction']?.toString() ?? 'system';

  static const _types = {
    'zk': 'ZKTeco / eSSL',
    'anviz': 'Anviz',
    'cosec': 'Matrix COSEC',
    'dahua': 'Dahua',
    'etimeoffice': 'e-Time Office',
  };

  static const _directions = {
    'in': 'In Device',
    'out': 'Out Device',
    'alternate': 'Alternate In/Out',
    'system': 'System Direction',
  };

  @override
  void dispose() {
    _name.dispose();
    _ip.dispose();
    _port.dispose();
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.existing == null ? 'New biometric device' : 'Edit device',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Device Name', icon: Icons.label_outline_rounded),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: InputDecoration(
              labelText: 'Device Type',
              prefixIcon: const Icon(Icons.fingerprint, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _types.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'zk'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  _ip,
                  'IP Address',
                  icon: Icons.lan_rounded,
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: _field(
                  _port,
                  'Port',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _direction,
            decoration: InputDecoration(
              labelText: 'Direction',
              prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _directions.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _direction = v ?? 'system'),
          ),
          const SizedBox(height: 16),
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
                    if (_name.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'machine_type': _type,
                      'machine_ip': _ip.text.trim(),
                      'port': int.tryParse(_port.text),
                      'device_direction': _direction,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    IconData? icon,
    TextInputType? keyboardType,
  }) => TextField(
    controller: c,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}
