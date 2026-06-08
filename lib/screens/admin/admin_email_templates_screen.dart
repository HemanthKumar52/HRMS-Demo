import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

/// Admin → Settings → Email Templates. Edit system email copy without
/// shipping a new build.
class AdminEmailTemplatesScreen extends StatefulWidget {
  const AdminEmailTemplatesScreen({super.key});

  @override
  State<AdminEmailTemplatesScreen> createState() =>
      _AdminEmailTemplatesScreenState();
}

class _AdminEmailTemplatesScreenState extends State<AdminEmailTemplatesScreen> {
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
      final r = await ApiService.getAdminEmailTemplates();
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
      builder: (_) => _TemplateEditor(existing: existing),
    );
    if (result == null) return;

    try {
      await ApiService.saveAdminEmailTemplate(result);
      _snack('Saved', AppColors.success);
      await _load();
    } catch (e) {
      _snack('Failed: $e', AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
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
        title: 'Email Templates',
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
                        child: Text('No templates yet — tap + to add one'),
                      ),
                    );
                  }
                  final r = _items[i];
                  return NeuCard(
                    padding: const EdgeInsets.all(14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.pink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: AppColors.pink,
                        ),
                      ),
                      title: Text(
                        '${r['key']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        r['subject']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.edit_rounded, size: 20),
                      onTap: () => _openEditor(existing: r),
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
        label: const Text('New Template'),
      ),
    );
  }
}

class _TemplateEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _TemplateEditor({this.existing});

  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late final _key = TextEditingController(
    text: widget.existing?['key']?.toString() ?? '',
  );
  late final _subject = TextEditingController(
    text: widget.existing?['subject']?.toString() ?? '',
  );
  late final _body = TextEditingController(
    text: widget.existing?['body']?.toString() ?? '',
  );

  @override
  void dispose() {
    _key.dispose();
    _subject.dispose();
    _body.dispose();
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
            widget.existing == null ? 'New template' : 'Edit template',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            enabled: widget.existing == null,
            decoration: InputDecoration(
              labelText: 'Key (e.g. welcome_employee)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Body (use {{placeholders}})',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    if (_key.text.trim().isEmpty ||
                        _subject.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key + subject required')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'key': _key.text.trim(),
                      'subject': _subject.text.trim(),
                      'body': _body.text,
                      'is_active': true,
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
}
