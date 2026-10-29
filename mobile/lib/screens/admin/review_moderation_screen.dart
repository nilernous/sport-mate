import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/review.dart';
import '../../services/admin_service.dart';
import '../../services/review_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

/// Review moderation for Staff and Admin (UC-069, UC-072).
class ReviewModerationScreen extends ConsumerStatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  ConsumerState<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends ConsumerState<ReviewModerationScreen> {
  ReviewStatus? _status;
  int _version = 0;

  Future<void> _moderate(Review review, ReviewStatus status) async {
    final ok = await runGuarded(context, () => ref.read(adminServiceProvider).moderateReview(review.id, status), success: 'Review ${status.label.toLowerCase()}');
    if (ok) setState(() => _version++);
  }

  Future<void> _delete(Review review) async {
    if (!await confirmDialog(context, title: 'Delete review', message: 'Permanently delete this review?', confirmLabel: 'Delete', destructive: true)) return;
    if (!mounted) return;
    final ok = await runGuarded(context, () => ref.read(reviewServiceProvider).delete(review.id), success: 'Review deleted');
    if (ok) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reviews')),
        body: Column(children: [
          SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
              ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              for (final s in ReviewStatus.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
              ],
            ]),
          ),
          Expanded(
            child: PagedListView<Review>(
              queryKey: (_status, _version),
              fetch: (page) => ref.read(adminServiceProvider).reviews(status: _status, page: page),
              emptyMessage: 'No reviews to show.',
              emptyIcon: Icons.rate_review_outlined,
              itemBuilder: (context, r, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(r.productName, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      StatusChip.review(r.status),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      RatingStars(r.rating.toDouble(), size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${r.userName} · ${formatDateTime(r.createdAt)}', style: Theme.of(context).textTheme.labelSmall)),
                    ]),
                    if ((r.comment ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.comment!)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      for (final s in ReviewStatus.values)
                        if (s != r.status)
                          OutlinedButton(onPressed: () => _moderate(r, s), child: Text(switch (s) {
                            ReviewStatus.approved => 'Approve',
                            ReviewStatus.hidden => 'Hide',
                            ReviewStatus.rejected => 'Reject',
                          })),
                      TextButton(onPressed: () => _delete(r), child: const Text('Delete')),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}
