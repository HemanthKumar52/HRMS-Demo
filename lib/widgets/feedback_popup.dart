import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// App feedback popup that shows when the user is about to leave the app.
///
/// Logic:
///   1. If user already gave feedback for this version → never show.
///   2. If user dismissed today → don't show again today.
///   3. Otherwise show on app close/background.
///   4. Once submitted → stored in DB, never shown again for this version.
class FeedbackManager {
  FeedbackManager._();
  static const _version = '1.0.0';
  static const _dismissKey = 'feedback_dismissed_date';

  /// Call this when the app goes to background or user logs out.
  /// Shows the feedback bottom sheet if conditions are met.
  static Future<void> maybeShowFeedback(BuildContext context) async {
    try {
      // 1. Check if already submitted for this version.
      final hasIt = await ApiService.hasFeedback(_version);
      if (hasIt) return;

      // 2. Check if dismissed today.
      final prefs = await SharedPreferences.getInstance();
      final lastDismiss = prefs.getString(_dismissKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (lastDismiss == today) return;

      // 3. Show the popup.
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => const _FeedbackSheet(version: _version),
      );
    } catch (_) {
      // Network error or not logged in — silently skip.
    }
  }

  /// Record that the user dismissed without submitting.
  static Future<void> _recordDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_dismissKey, today);
  }
}

class _FeedbackSheet extends StatefulWidget {
  final String version;
  const _FeedbackSheet({required this.version});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await ApiService.submitFeedback(
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        version: widget.version,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _dismiss() {
    FeedbackManager._recordDismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'How was your experience?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps us improve PPULSE',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = star);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: _rating >= star ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _rating >= star
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 40,
                      color: _rating >= star
                          ? const Color(0xFFFFB800)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          if (_rating > 0)
            Text(
              ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][_rating],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _rating >= 4
                    ? AppColors.success
                    : (_rating >= 3 ? AppColors.warning : AppColors.danger),
              ),
            ),
          const SizedBox(height: 16),

          // Comment
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any suggestions? (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _dismiss,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Maybe Later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _rating == 0 || _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
