import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

/// Admin → Settings → Geofences. Manages allowed punch-in zones.
class AdminGeofencesScreen extends StatefulWidget {
  const AdminGeofencesScreen({super.key});

  @override
  State<AdminGeofencesScreen> createState() => _AdminGeofencesScreenState();
}

class _AdminGeofencesScreenState extends State<AdminGeofencesScreen> {
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
      final r = await ApiService.getAdminGeofences();
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
      builder: (_) => _GeofenceEditor(existing: existing),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await ApiService.createAdminGeofence(result);
        _showSnack('Geofence added', AppColors.success);
      } else {
        await ApiService.updateAdminGeofence(
          (existing['id'] as num).toInt(),
          result,
        );
        _showSnack('Geofence updated', AppColors.success);
      }
      await _load();
    } catch (e) {
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await (isApplePlatform
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Delete geofence?'),
              content: Text('Remove "${row['name']}" from the allowed zones?'),
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
              title: const Text('Delete geofence?'),
              content: Text('Remove "${row['name']}" from the allowed zones?'),
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
      await ApiService.deleteAdminGeofence((row['id'] as num).toInt());
      _showSnack('Deleted', AppColors.danger);
      await _load();
    } catch (e) {
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row, bool active) async {
    try {
      await ApiService.updateAdminGeofence(
        (row['id'] as num).toInt(),
        {'is_active': active},
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Office Geofences',
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('No geofences yet — tap + to add one'),
                      ),
                    );
                  }
                  final r = _items[i];
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ((r['is_office'] ?? false) as bool)
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ((r['is_office'] ?? false) as bool)
                                ? Icons.business_rounded
                                : Icons.home_work_rounded,
                            color: ((r['is_office'] ?? false) as bool)
                                ? AppColors.primary
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name']?.toString() ?? '—',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(r['latitude'] as num?)?.toStringAsFixed(5)}, ${(r['longitude'] as num?)?.toStringAsFixed(5)} · ${r['radius_meters']}m',
                                style: theme.textTheme.bodySmall,
                              ),
                              Row(
                                children: [
                                  _Pill(
                                    text: ((r['is_office'] ?? false) as bool)
                                        ? 'Office'
                                        : 'WFH',
                                    color: AppColors.primary,
                                  ),
                                  if ((r['has_biometric'] ?? false)
                                      as bool) ...[
                                    const SizedBox(width: 6),
                                    _Pill(
                                      text: 'Biometric',
                                      color: AppColors.warning,
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  _Pill(
                                    text: ((r['is_active'] ?? true) as bool)
                                        ? 'active'
                                        : 'disabled',
                                    color: ((r['is_active'] ?? true) as bool)
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: (r['is_active'] ?? true) as bool,
                          activeColor: AppColors.success,
                          onChanged: (v) => _toggleActive(r, v),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (action) {
                            if (action == 'edit') _openEditor(existing: r);
                            if (action == 'delete') _delete(r);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
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
        label: const Text('Add Zone'),
      ),
    );
  }
}

class _GeofenceEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _GeofenceEditor({this.existing});

  @override
  State<_GeofenceEditor> createState() => _GeofenceEditorState();
}

class _GeofenceEditorState extends State<_GeofenceEditor> {
  late final _name = TextEditingController(
    text: widget.existing?['name']?.toString() ?? '',
  );
  late final _lat = TextEditingController(
    text: widget.existing?['latitude']?.toString() ?? '',
  );
  late final _lng = TextEditingController(
    text: widget.existing?['longitude']?.toString() ?? '',
  );
  late final _radius = TextEditingController(
    text: widget.existing?['radius_meters']?.toString() ?? '50',
  );
  late bool _isOffice = (widget.existing?['is_office'] as bool?) ?? true;
  late bool _hasBiometric =
      (widget.existing?['has_biometric'] as bool?) ?? false;
  late bool _isActive = (widget.existing?['is_active'] as bool?) ?? true;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
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
            widget.existing == null ? 'New geofence' : 'Edit geofence',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Name', icon: Icons.label_outline_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  _lat,
                  'Latitude',
                  icon: Icons.my_location_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _lng,
                  'Longitude',
                  icon: Icons.explore_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            _radius,
            'Radius (meters)',
            icon: Icons.straighten_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: const Text('Office zone'),
            subtitle: const Text('Mark as office location'),
            value: _isOffice,
            onChanged: (v) => setState(() => _isOffice = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isOffice)
            SwitchListTile.adaptive(
              title: const Text('Has biometric device'),
              subtitle: const Text(
                'Blocks mobile check-in (must use biometric)',
              ),
              value: _hasBiometric,
              onChanged: (v) => setState(() => _hasBiometric = v),
              contentPadding: EdgeInsets.zero,
            ),
          SwitchListTile.adaptive(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
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
                    final lat = double.tryParse(_lat.text);
                    final lng = double.tryParse(_lng.text);
                    final radius = int.tryParse(_radius.text);
                    if (_name.text.trim().isEmpty ||
                        lat == null ||
                        lng == null ||
                        radius == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fill name, lat, lng, radius'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'latitude': lat,
                      'longitude': lng,
                      'radius_meters': radius,
                      'is_office': _isOffice,
                      'has_biometric': _isOffice && _hasBiometric,
                      'is_active': _isActive,
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
    margin: const EdgeInsets.only(top: 4),
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
