import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom sheet showing detailed attendance info: location, device, IP.
class AttendanceDetailPopup extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool showIp;

  const AttendanceDetailPopup({
    super.key,
    required this.record,
    this.showIp = false,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> record,
    bool showIp = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceDetailPopup(record: record, showIp: showIp),
    );
  }

  String _val(String key) {
    final v = record[key];
    if (v == null) return 'N/A';
    final s = v.toString().trim();
    return s.isEmpty ? 'N/A' : s;
  }

  String _coord(String latKey, String lngKey) {
    final lat = record[latKey];
    final lng = record[lngKey];
    if (lat == null && lng == null) return 'N/A';
    return '${lat ?? '-'}, ${lng ?? '-'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            _val('date'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Worked: ${_val('worked_hours')}',
            style: TextStyle(fontSize: 14, color: subtitleColor),
          ),
          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 16),

          // Punch In section
          _SectionHeader(
            icon: Icons.login_rounded,
            title: 'Punch In',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _DetailRow(label: 'Time', value: _val('punch_in'), color: textColor),
          _DetailRow(
            label: 'Location',
            value: _val('punch_in_location'),
            color: textColor,
          ),
          _DetailRow(
            label: 'Coordinates',
            value: _coord('punch_in_lat', 'punch_in_lng'),
            color: textColor,
          ),
          _DetailRow(label: 'Device', value: _val('device'), color: textColor),
          _DetailRow(
            label: 'Source',
            value: _val('source'),
            color: textColor,
          ),
          if (showIp)
            _DetailRow(
              label: 'IP Address',
              value: _val('punch_in_ip'),
              color: textColor,
              highlight: true,
            ),

          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 16),

          // Punch Out section
          _SectionHeader(
            icon: Icons.logout_rounded,
            title: 'Punch Out',
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Time',
            value: _val('punch_out'),
            color: textColor,
          ),
          _DetailRow(
            label: 'Location',
            value: _val('punch_out_location'),
            color: textColor,
          ),
          _DetailRow(
            label: 'Coordinates',
            value: _coord('punch_out_lat', 'punch_out_lng'),
            color: textColor,
          ),
          _DetailRow(
            label: 'Device',
            value: _val('punch_out_device'),
            color: textColor,
          ),
          if (showIp)
            _DetailRow(
              label: 'IP Address',
              value: _val('punch_out_ip'),
              color: textColor,
              highlight: true,
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.withAlpha(153),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: highlight ? AppColors.primary : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
