import 'package:flutter/material.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
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

  List<String> _users = [];

  final List<String> _categories = [
    'Laptop', 'Monitor', 'Keyboard & Mouse', 'Headset',
    'Mobile Phone', 'ID Card', 'Access Card', 'Furniture', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await ApiService.getEmployees();
      if (!mounted) return;
      setState(() { _users = emps.map<String>((e) => e['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList(); });
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/assets/request', {
        'asset_category': _selectedCategory ?? '',
        'description': _descriptionController.text,
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(context, message: 'Asset request submitted');
      NotificationService.instance.showRequestApplied('Asset');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showErrorSnackbar(context, 'Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(context: context, title: 'Asset Request', showBackButton: true),
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
