import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/employee_cc_field.dart';
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
  late String _selectedType;
  DateTime? _date;
  final List<XFile> _images = [];
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _ccUsers = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _claimTypes = [
    'Travel Reimbursement',
    'Food & Beverage',
    'Client Entertainment',
    'Office Supplies',
    'Medical',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = _claimTypes.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _images.add(image));
        if (mounted) showSuccessSnackbar(context, 'Image added successfully');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not pick image');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _images.add(image));
        if (mounted) showSuccessSnackbar(context, 'Photo captured');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Could not take photo');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitClaim({
        'title': _titleController.text,
        'claim_type': _selectedType,
        'amount': 0,
        'date': (_date ?? DateTime.now()).toIso8601String().split('T')[0],
        'description': _descriptionController.text,
        'cc': _ccUsers.map((u) => u['user_id']).toList(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: 'Claim submitted successfully',
      );
      // (Single notification only — SuccessOverlay above covers it.)
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showErrorSnackbar(
        context,
        'Failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Submit Claim',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Reimbursement / Encashment',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              formFieldGap,

              const FormLabel('Type'),
              formLabelGap,
              FormDropdown(
                value: _selectedType,
                hint: 'Select type',
                items: _claimTypes,
                onChanged: (v) =>
                    setState(() => _selectedType = v ?? _claimTypes.first),
              ),
              formFieldGap,

              const FormLabel('Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_date),
                hasValue: _date != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _date,
                    accentColor: AppColors.success,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Title'),
              formLabelGap,
              FormInput(
                controller: _titleController,
                hint: 'Title',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Enter claim description...',
                maxLines: 4,
              ),
              formFieldGap,

              const FormLabel('Upload Images'),
              formLabelGap,
              if (_images.isNotEmpty) ...[
                Column(
                  children: _images.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeuCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image_rounded,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value.name,
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _images.removeAt(entry.key)),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
              NeuCard(
                onTap: _addImage,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 22,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Add Image',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              formSectionGap,

              EmployeeCcField(
                selected: _ccUsers,
                onChanged: (next) => setState(() {
                  _ccUsers
                    ..clear()
                    ..addAll(next);
                }),
              ),
              formSectionGap,

              FormActionButtons(
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
                buttonColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
