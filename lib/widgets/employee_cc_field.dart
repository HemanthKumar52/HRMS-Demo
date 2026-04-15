import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Reusable CC field for request submission screens.
///
/// Usage:
/// ```dart
/// final _ccUserIds = <int>[];
/// final _ccUsers   = <Map<String, dynamic>>[];   // local copy for chips
///
/// EmployeeCcField(
///   selected: _ccUsers,
///   onChanged: (list) => setState(() {
///     _ccUsers..clear()..addAll(list);
///     _ccUserIds..clear()..addAll(list.map((u) => u['user_id'] as int));
///   }),
/// );
/// ```
///
/// Then include `_ccUserIds` in the submit body as `'cc': _ccUserIds`.
class EmployeeCcField extends StatefulWidget {
  final List<Map<String, dynamic>> selected;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final String label;
  final String hint;

  const EmployeeCcField({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label = 'CC',
    this.hint = 'Search by name or email…',
  });

  @override
  State<EmployeeCcField> createState() => _EmployeeCcFieldState();
}

class _EmployeeCcFieldState extends State<EmployeeCcField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Hide after a tiny delay so the tap on a suggestion still fires.
        Future<void>.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    setState(() {
      _showSuggestions = true;
      _loading = true;
    });
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final res = await ApiService.searchEmployees(q);
        if (!mounted) return;
        setState(() {
          _suggestions = res
              // Hide already-selected users.
              .where(
                (u) =>
                    !widget.selected.any((s) => s['user_id'] == u['user_id']),
              )
              .toList();
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
    });
  }

  void _add(Map<String, dynamic> user) {
    final next = [...widget.selected, user];
    widget.onChanged(next);
    _ctrl.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _remove(Map<String, dynamic> user) {
    final next = widget.selected
        .where((u) => u['user_id'] != user['user_id'])
        .toList();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focus.hasFocus
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final u in widget.selected)
                Chip(
                  label: Text(
                    (u['name'] ?? u['email'] ?? '?').toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                    child: Text(
                      ((u['name'] ?? '?').toString().isNotEmpty
                              ? (u['name'] ?? '?').toString()[0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _remove(u),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: widget.selected.isEmpty
                        ? widget.hint
                        : 'Add another…',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Suggestions dropdown.
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('No matches', style: theme.textTheme.bodySmall),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) {
                      final u = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            (u['name'] ?? '?').toString().isNotEmpty
                                ? (u['name'] ?? '?').toString()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          u['name']?.toString() ?? '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          u['email']?.toString() ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.add_rounded, size: 18),
                        onTap: () => _add(u),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
