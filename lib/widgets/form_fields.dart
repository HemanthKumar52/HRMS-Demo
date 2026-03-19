import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? firstDate, DateTime? lastDate, Color? accentColor}) {
  final now = DateTime.now();
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

Future<TimeOfDay?> pickTime(BuildContext context, {TimeOfDay? initial}) {
  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary, onPrimary: Colors.white)),
      child: child!,
    ),
  );
}

void showSuccessSnackbar(BuildContext context, String message) {
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
