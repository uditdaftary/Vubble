import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/rating_provider.dart';

// ─────────────────────────────────────────────
//  RATING SHEET  — bottom sheet with stars + review
// ─────────────────────────────────────────────

/// Shows a rating bottom sheet. Returns `true` if submitted successfully.
Future<bool?> showRatingSheet(
  BuildContext context, {
  required String targetUserId,
  required String reviewerUserId,
  required String sourceId,
  required String sourceType,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RatingSheet(
      targetUserId: targetUserId,
      reviewerUserId: reviewerUserId,
      sourceId: sourceId,
      sourceType: sourceType,
    ),
  );
}

class _RatingSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String reviewerUserId;
  final String sourceId;
  final String sourceType;

  const _RatingSheet({
    required this.targetUserId,
    required this.reviewerUserId,
    required this.sourceId,
    required this.sourceType,
  });

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  int _stars = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _submitting = true);

    try {
      await ref
          .read(ratingServiceProvider)
          .submitRating(
            targetUserId: widget.targetUserId,
            reviewerUserId: widget.reviewerUserId,
            sourceId: widget.sourceId,
            sourceType: widget.sourceType,
            stars: _stars,
            review: _reviewCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted! ⭐', style: AppText.body(size: 14)),
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit review',
            style: AppText.body(size: 14),
          ),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────────
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ─────────────────────────────
              Text('Rate your experience', style: AppText.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'How was your ${widget.sourceType == 'gig' ? 'gig' : 'rental'} experience?',
                style: AppText.body(size: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // ── Star selector ─────────────────────
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 42,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                unratedColor: AppColors.surfaceHigh,
                glowColor: AppColors.amber.withOpacity(0.3),
                itemBuilder: (_, _) =>
                    const Icon(Icons.star_rounded, color: AppColors.amber),
                onRatingUpdate: (rating) {
                  setState(() => _stars = rating.toInt());
                },
              ),
              const SizedBox(height: 8),
              Text(
                _starLabel,
                style: AppText.label(size: 12, color: AppColors.amber),
              ),
              const SizedBox(height: 20),

              // ── Review text ───────────────────────
              TextFormField(
                controller: _reviewCtrl,
                style: AppText.input(),
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Write a quick review (optional)',
                ),
              ),
              const SizedBox(height: 20),

              // ── Submit button ─────────────────────
              GradientButton(
                label: 'Submit Review',
                isLoading: _submitting,
                onTap: _stars > 0 ? _submit : null,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _starLabel {
    switch (_stars) {
      case 1:
        return 'POOR';
      case 2:
        return 'FAIR';
      case 3:
        return 'GOOD';
      case 4:
        return 'GREAT';
      case 5:
        return 'EXCELLENT';
      default:
        return 'TAP TO RATE';
    }
  }
}
