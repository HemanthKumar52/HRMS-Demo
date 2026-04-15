import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Modal dialog for approving or rejecting a request.
///
/// • Approve mode → optional comment, button is always enabled, label is "Approve".
/// • Reject mode  → mandatory reason, button stays disabled until non-empty, label is "Reject".
///
/// Returns the captured reason string on submit, or `null` on cancel. An empty
/// string is returned for an Approve with no comment.
class RequestActionDialog extends StatefulWidget {
  final bool approve;
  final String requestType;

  const RequestActionDialog({
    super.key,
    required this.approve,
    required this.requestType,
  });

  static Future<String?> show(
    BuildContext context, {
    required bool approve,
    required String requestType,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          RequestActionDialog(approve: approve, requestType: requestType),
    );
  }

  @override
  State<RequestActionDialog> createState() => _RequestActionDialogState();
}

class _RequestActionDialogState extends State<RequestActionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approve = widget.approve;
    final color = approve ? AppColors.success : AppColors.danger;
    final icon = approve ? Icons.check_circle_outline : Icons.cancel_outlined;
    final actionLabel = approve ? 'Approve' : 'Reject';
    final fieldLabel = approve ? 'Comment (optional)' : 'Reason for rejection';
    final hint = approve
        ? 'Add a note for the requester…'
        : 'Why are you rejecting this request?';

    final canSubmit = approve || _controller.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row.
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$actionLabel ${widget.requestType}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        approve
                            ? 'Optionally leave a comment for the requester.'
                            : 'A reason is required to reject this request.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Reason input.
            Text(
              fieldLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.30),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 18),

            // Action buttons.
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: canSubmit
                          ? () => Navigator.of(
                              context,
                            ).pop(_controller.text.trim())
                          : null,
                      icon: Icon(icon, size: 18),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: color.withValues(alpha: 0.35),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
