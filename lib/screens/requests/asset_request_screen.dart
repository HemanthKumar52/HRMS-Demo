import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';

class AssetRequestScreen extends StatefulWidget {
  const AssetRequestScreen({super.key});

  @override
  State<AssetRequestScreen> createState() => _AssetRequestScreenState();
}

class _AssetRequestScreenState extends State<AssetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedUser;
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _users = [
    'Venkat Kumar',
    'Priya Sharma',
    'Rahul Verma',
    'Anita Desai',
  ];

  final List<String> _categories = [
    'Laptop',
    'Monitor',
    'Keyboard & Mouse',
    'Headset',
    'Mobile Phone',
    'ID Card',
    'Access Card',
    'Furniture',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackbar(context, 'Asset request submitted');
      NotificationService.instance.showRequestApplied('Asset');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Asset Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asset Request', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              formFieldGap,

              const FormLabel('Requesting User'),
              formLabelGap,
              FormDropdown(
                value: _selectedUser,
                hint: 'Select user',
                items: _users,
                onChanged: (v) => setState(() => _selectedUser = v),
              ),
              formFieldGap,

              const FormLabel('Asset Category'),
              formLabelGap,
              FormDropdown(
                value: _selectedCategory,
                hint: 'Select category',
                items: _categories,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Description',
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit, buttonColor: AppColors.neonPurple),
            ],
          ),
        ),
      ),
    );
  }
}
