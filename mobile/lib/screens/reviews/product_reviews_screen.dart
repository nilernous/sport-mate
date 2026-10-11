import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../services/review_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import '../products/product_detail_screen.dart';

final _myReviewProvider = FutureProvider.autoDispose.family<MyReviewStatus, int>((ref, productId) => ref.watch(reviewServiceProvider).mine(productId));

/// All approved reviews of a product, plus the customer's own review actions (UC-068 – UC-071).
class ProductReviewsScreen extends ConsumerStatefulWidget {
  const ProductReviewsScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  int _version = 0;

  void _refresh() {
    ref.invalidate(_myReviewProvider(widget.productId));
    ref.invalidate(productReviewsPreviewProvider(widget.productId));
    ref.invalidate(productDetailProvider(widget.productId));
    setState(() => _version++);
  }

  Future<void> _edit(Review? existing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewForm(productId: widget.productId, existing: existing),
    );
    if (saved == true) _refresh();
  }

  Future<void> _delete(Review review) async {
    if (!await confirmDialog(context, title: 'Delete review', message: 'Delete your review of this product?', confirmLabel: 'Delete', destructive: true)) return;
    if (!mounted) return;
    final ok = await runGuarded(context, () => ref.read(reviewServiceProvider).delete(review.id), success: 'Review deleted');
    if (ok) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = ref.watch(authProvider).isCustomer;
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: PagedListView<Review>(
        queryKey: _version,
        padding: const EdgeInsets.symmetric(vertical: 8),
        separator: const Divider(height: 1),
        emptyMessage: 'No reviews yet.',
        emptyIcon: Icons.rate_review_outlined,
        header: Column(children: [
          _SummaryHeader(productId: widget.productId, version: _version),
          if (isCustomer) _MyReviewCard(productId: widget.productId, onWrite: () => _edit(null), onEdit: _edit, onDelete: _delete),
        ]),
        fetch: (page) async => (await ref.read(reviewServiceProvider).forProduct(widget.productId, page: page)).reviews,
        itemBuilder: (_, r, _) => ReviewTile(r),
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  const _SummaryHeader({required this.productId, required this.version});

  final int productId;
  final int version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(productReviewsPreviewProvider(productId)).value?.summary;
    if (summary == null) return const SizedBox(height: 120, child: LoadingView());
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Column(children: [
          Text(summary.averageRating.toStringAsFixed(1), style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
          RatingStars(summary.averageRating),
          const SizedBox(height: 4),
          Text('${summary.reviewCount} reviews', style: theme.textTheme.labelMedium),
        ]),
        const SizedBox(width: 24),
        Expanded(
          child: Column(children: [
            for (var star = 5; star >= 1; star--)
              Row(children: [
                SizedBox(width: 14, child: Text('$star')),
                const SizedBox(width: 6),
                Expanded(
                  child: LinearProgressIndicator(
                    value: summary.reviewCount == 0 ? 0 : (summary.ratingCounts[star] ?? 0) / summary.reviewCount,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(width: 24, child: Text('${summary.ratingCounts[star] ?? 0}', textAlign: TextAlign.end)),
              ]),
          ]),
        ),
      ]),
    );
  }
}

class _MyReviewCard extends ConsumerWidget {
  const _MyReviewCard({required this.productId, required this.onWrite, required this.onEdit, required this.onDelete});

  final int productId;
  final VoidCallback onWrite;
  final void Function(Review) onEdit;
  final void Function(Review) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_myReviewProvider(productId)).value;
    if (status == null) return const SizedBox.shrink();
    final review = status.review;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: review != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Your review', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 8),
                    if (review.status != ReviewStatus.approved) StatusChip.review(review.status),
                    const Spacer(),
                    if (review.status != ReviewStatus.rejected)
                      IconButton(tooltip: 'Edit review', icon: const Icon(Icons.edit_outlined), onPressed: () => onEdit(review)),
                    IconButton(tooltip: 'Delete review', icon: const Icon(Icons.delete_outline), onPressed: () => onDelete(review)),
                  ]),
                  RatingStars(review.rating.toDouble()),
                  if ((review.comment ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(review.comment!)),
                  if (review.status != ReviewStatus.approved)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('This review is not shown publicly.', style: Theme.of(context).textTheme.labelSmall),
                    ),
                ])
              : status.canReview
                  ? Row(children: [
                      const Expanded(child: Text('You bought this product. Share your experience!')),
                      FilledButton.tonal(onPressed: onWrite, child: const Text('Write a review')),
                    ])
                  : Text(status.reason ?? 'You cannot review this product yet.'),
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.productId, this.existing});

  final int productId;
  final Review? existing;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late int _rating = widget.existing?.rating ?? 5;
  late final _comment = TextEditingController(text: widget.existing?.comment);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(reviewServiceProvider);
    final comment = _comment.text.trim().isEmpty ? null : _comment.text.trim();
    final ok = await runGuarded(context, () async {
      if (widget.existing == null) {
        await service.create(widget.productId, _rating, comment);
      } else {
        await service.update(widget.existing!.id, _rating, comment);
      }
    }, success: 'Thanks for your review!');
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.existing == null ? 'Write a review' : 'Edit your review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Center(child: RatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v))),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Comment (optional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          BusyButton(label: 'Submit', onPressed: _save),
        ]),
      );
}
