import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/platform_adaptive.dart';
import 'neu_card.dart';

class FormLabel extends StatelessWidget {
  final String label;
  const FormLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
  }
}

class FormDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const FormDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return _buildIOSDropdown(context, textTheme, isDark);
    }
    return _buildAndroidDropdown(context, textTheme, isDark);
  }

  Widget _buildIOSDropdown(BuildContext context, TextTheme textTheme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showCupertinoPicker(context, isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: value != null
                    ? textTheme.bodyLarge
                    : textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
            Icon(CupertinoIcons.chevron_down, size: 16, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ],
        ),
      ),
    );
  }

  void _showCupertinoPicker(BuildContext context, bool isDark) {
    int selectedIndex = value != null ? items.indexOf(value!) : 0;
    if (selectedIndex < 0) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      onChanged(items[selectedIndex]);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                magnification: 1.2,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 36,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (index) => selectedIndex = index,
                children: items.map((item) => Center(
                  child: Text(item, style: TextStyle(fontSize: 18, color: isDark ? AppColors.darkText : AppColors.lightText)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidDropdown(BuildContext context, TextTheme textTheme, bool isDark) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: textTheme.bodyLarge))).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }
}

class FormDateField extends StatelessWidget {
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const FormDateField({
    super.key,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 18, color: hasValue ? AppColors.primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: hasValue ? textTheme.bodyLarge : textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ],
          ),
        ),
      );
    }

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: hasValue ? AppColors.primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: hasValue ? textTheme.bodyLarge : textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
        ],
      ),
    );
  }
}

class FormTimeField extends StatelessWidget {
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const FormTimeField({
    super.key,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.clock, size: 18, color: hasValue ? AppColors.primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: hasValue ? textTheme.bodyLarge : textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ],
          ),
        ),
      );
    }

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, size: 18, color: hasValue ? AppColors.primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: hasValue ? textTheme.bodyLarge : textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
        ],
      ),
    );
  }
}

class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const FormInput({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: CupertinoTextField(
          controller: controller,
          maxLines: maxLines,
          placeholder: hint,
          placeholderStyle: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          style: textTheme.bodyLarge,
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(), // remove default decoration
        ),
      );
    }

    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
        style: textTheme.bodyLarge,
        validator: validator,
      ),
    );
  }
}

class FormAttachment extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const FormAttachment({
    super.key,
    required this.fileName,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.paperclip, size: 20, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName ?? 'No file chosen',
                  style: textTheme.bodyMedium?.copyWith(
                    color: fileName != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                ),
              ),
              if (fileName != null && onRemove != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(24, 24),
                  onPressed: onRemove,
                  child: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: AppColors.danger),
                ),
            ],
          ),
        ),
      );
    }

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, size: 20, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName ?? 'No file chosen',
              style: textTheme.bodyMedium?.copyWith(
                color: fileName != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ),
          if (fileName != null && onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

class FormActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Color? buttonColor;

  const FormActionButtons({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isApplePlatform) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w600, fontSize: 15,
                )),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: buttonColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                onPressed: isSubmitting ? null : () {
                  HapticFeedback.mediumImpact();
                  onSubmit();
                },
                child: isSubmitting
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
                side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor ?? AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard spacing after a field section
const formFieldGap = SizedBox(height: 20);
const formSectionGap = SizedBox(height: 28);
const formLabelGap = SizedBox(height: 8);

/// Attachment toggle widget — asks "Add attachment?" with a switch.
/// When toggled on, shows the FormAttachment below.
class FormAttachmentToggle extends StatelessWidget {
  final bool enabled;
  final String? fileName;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const FormAttachmentToggle({
    super.key,
    required this.enabled,
    required this.fileName,
    required this.onToggle,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_file_rounded, size: 20, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add attachment?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (enabled) ...[
          const SizedBox(height: 12),
          FormAttachment(
            fileName: fileName,
            onTap: onPick,
            onRemove: onRemove,
          ),
        ],
      ],
    );
  }
}

String formatDate(DateTime? date) {
  if (date == null) return 'Select Date';
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

String formatTime(TimeOfDay? time) {
  if (time == null) return 'Select Time';
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Platform-adaptive date picker
/// iOS: Cupertino wheel picker in a bottom sheet
/// Android: Material date picker dialog
Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? firstDate, DateTime? lastDate, Color? accentColor}) {
  final now = DateTime.now();

  if (isApplePlatform) {
    return _showCupertinoDatePicker(
      context,
      initial: initial ?? now,
      firstDate: firstDate ?? now.subtract(const Duration(days: 90)),
      lastDate: lastDate ?? now.add(const Duration(days: 365)),
    );
  }

  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: firstDate ?? now.subtract(const Duration(days: 90)),
    lastDate: lastDate ?? now.add(const Duration(days: 365)),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: accentColor ?? AppColors.primary, onPrimary: Colors.white)),
      child: child!,
    ),
  );
}

Future<DateTime?> _showCupertinoDatePicker(BuildContext context, {required DateTime initial, required DateTime firstDate, required DateTime lastDate}) async {
  DateTime selectedDate = initial;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final result = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground.resolveFrom(ctx),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkSubtext : CupertinoColors.systemGrey)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, selectedDate);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (date) {
                HapticFeedback.selectionClick();
                selectedDate = date;
              },
            ),
          ),
        ],
      ),
    ),
  );
  return result;
}

/// Platform-adaptive time picker
Future<TimeOfDay?> pickTime(BuildContext context, {TimeOfDay? initial}) {
  if (isApplePlatform) {
    return _showCupertinoTimePicker(context, initial: initial ?? TimeOfDay.now());
  }

  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary, onPrimary: Colors.white)),
      child: child!,
    ),
  );
}

Future<TimeOfDay?> _showCupertinoTimePicker(BuildContext context, {required TimeOfDay initial}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final now = DateTime.now();
  DateTime selectedTime = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

  final result = await showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (ctx) => Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground.resolveFrom(ctx),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkSubtext : CupertinoColors.systemGrey)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, TimeOfDay(hour: selectedTime.hour, minute: selectedTime.minute));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: selectedTime,
              onDateTimeChanged: (dt) {
                HapticFeedback.selectionClick();
                selectedTime = dt;
              },
            ),
          ),
        ],
      ),
    ),
  );
  return result;
}

/// Platform-adaptive snackbar/toast
void showSuccessSnackbar(BuildContext context, String message) {
  if (isApplePlatform) {
    _showIOSToast(context, message, AppColors.success, CupertinoIcons.checkmark_circle_fill);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

void showErrorSnackbar(BuildContext context, String message) {
  if (isApplePlatform) {
    _showIOSToast(context, message, AppColors.danger, CupertinoIcons.xmark_circle_fill);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

void _showIOSToast(BuildContext context, String message, Color color, IconData icon) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (ctx) => _IOSToast(message: message, color: color, icon: icon),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () => entry.remove());
}

class _IOSToast extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _IOSToast({required this.message, required this.color, required this.icon});

  @override
  State<_IOSToast> createState() => _IOSToastState();
}

class _IOSToastState extends State<_IOSToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Platform-adaptive dialog
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = 'Cancel',
  String confirmText = 'Confirm',
  bool isDestructive = false,
}) {
  if (isApplePlatform) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelText)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText, style: TextStyle(color: isDestructive ? AppColors.danger : AppColors.primary)),
        ),
      ],
    ),
  );
}
