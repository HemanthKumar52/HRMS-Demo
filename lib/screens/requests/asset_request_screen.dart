import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/form_fields.dart';

class AssetRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const AssetRequestScreen({super.key, this.editData});

  @override
  State<AssetRequestScreen> createState() => _AssetRequestScreenState();
}

class _AssetRequestScreenState extends State<AssetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late String _selectedCategory;
  bool _isSubmitting = false;

  bool get _isEditing => widget.editData != null;
  String? get _editId => widget.editData?['id']?.toString();

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
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _prefillFromEditData();
  }

  void _prefillFromEditData() {
    final data = widget.editData;
    if (data == null) return;
    final cat = data['asset_category']?.toString() ?? '';
    if (_categories.contains(cat)) {
      _selectedCategory = cat;
    }
    _descriptionController.text = data['description']?.toString() ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'asset_category': _selectedCategory,
        'description': _descriptionController.text,
      };
      if (_isEditing) {
        await ApiService.updateAssetRequest(int.parse(_editId!), payload);
      } else {
        await ApiService.post('/assets/request', payload);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: _isEditing
            ? 'Asset request updated'
            : 'Asset request submitted',
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: _isEditing ? 'Edit Asset Request' : 'Asset Request',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: isApplePlatform
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormLabel('Asset Category', required: true),
              formLabelGap,
              FormDropdown(
                value: _selectedCategory,
                hint: 'Select category',
                items: _categories,
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? _categories.first),
              ),
              formFieldGap,

              const FormLabel('Reason', required: true),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Reason',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Reason is required' : null,
              ),
              formSectionGap,

              FormActionButtons(
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
                buttonColor: AppColors.neonPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
