import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/neu_card.dart';

class SubmitClaimScreen extends StatefulWidget {
  const SubmitClaimScreen({super.key});

  @override
  State<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends State<SubmitClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedType;
  String? _selectedEmployee;
  DateTime? _date;
  final List<String> _images = [];
  bool _isSubmitting = false;

  final List<String> _claimTypes = [
    'Travel Reimbursement',
    'Food & Beverage',
    'Client Entertainment',
    'Office Supplies',
    'Medical',
    'Other',
  ];

  final List<String> _employees = [
    'Venkat Kumar',
    'Priya Sharma',
    'Rahul Verma',
    'Anita Desai',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addImage() {
    setState(() => _images.add('receipt_${_images.length + 1}.jpg'));
    showSuccessSnackbar(context, 'Image added successfully');
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackbar(context, 'Claim submitted successfully');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Submit Claim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Reimbursement / Encashment', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              formFieldGap,

              const FormLabel('Title'),
              formLabelGap,
              FormInput(
                controller: _titleController,
                hint: 'Title',
                validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              formFieldGap,

              const FormLabel('Type'),
              formLabelGap,
              FormDropdown(
                value: _selectedType,
                hint: 'Select type',
                items: _claimTypes,
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              formFieldGap,

              const FormLabel('Employee'),
              formLabelGap,
              FormDropdown(
                value: _selectedEmployee,
                hint: 'Select employee',
                items: _employees,
                onChanged: (v) => setState(() => _selectedEmployee = v),
              ),
              formFieldGap,

              const FormLabel('Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_date),
                hasValue: _date != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _date, accentColor: AppColors.success);
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(controller: _descriptionController, hint: 'Enter claim description...', maxLines: 4),
              formFieldGap,

              const FormLabel('Upload Images'),
              formLabelGap,
              if (_images.isNotEmpty) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _images.asMap().entries.map((entry) {
                    return NeuCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_rounded, size: 18, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(entry.value, style: textTheme.bodySmall),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _images.removeAt(entry.key)),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              NeuCard(
                onTap: _addImage,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 22, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    const SizedBox(width: 10),
                    Text('Add Image', style: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ],
                ),
              ),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit, buttonColor: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}
