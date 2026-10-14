import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../models/review.dart';

/// Network image that resolves server-relative upload paths and shows a placeholder.
class AppImage extends StatelessWidget {
  const AppImage(this.url, {super.key, this.fit = BoxFit.cover, this.borderRadius = 8, this.width, this.height});

  final String? url;
  final BoxFit fit;
  final double borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.outline),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: resolved == null
          ? placeholder
          : Image.network(
              resolved,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
            ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final icon = rating >= i + 1 ? Icons.star : rating >= i + 0.5 ? Icons.star_half : Icons.star_border;
          return Icon(icon, size: size, color: Colors.amber.shade700);
        }),
      );
}

/// Tappable 1–5 star selector.
class RatingInput extends StatelessWidget {
  const RatingInput({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) => IconButton(
              tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
              onPressed: () => onChanged(i + 1),
              icon: Icon(i < value ? Icons.star : Icons.star_border, color: Colors.amber.shade700, size: 32),
            )),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  factory StatusChip.order(OrderStatus status) => StatusChip(status.label, color: switch (status) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.confirmed => Colors.blue,
        OrderStatus.shipping => Colors.indigo,
        OrderStatus.completed => Colors.green,
        OrderStatus.cancelled => Colors.grey,
      });

  // Worded so it can't be confused with the order status shown next to it.
  factory StatusChip.payment(PaymentStatus status) => StatusChip(switch (status) {
        PaymentStatus.pending => 'Unpaid',
        PaymentStatus.paid => 'Paid',
        PaymentStatus.failed => 'Payment failed',
        PaymentStatus.refunded => 'Refunded',
      }, color: switch (status) {
        PaymentStatus.pending => Colors.orange,
        PaymentStatus.paid => Colors.green,
        PaymentStatus.failed => Colors.red,
        PaymentStatus.refunded => Colors.purple,
      });

  factory StatusChip.review(ReviewStatus status) => StatusChip(status.label, color: switch (status) {
        ReviewStatus.approved => Colors.green,
        ReviewStatus.hidden => Colors.orange,
        ReviewStatus.rejected => Colors.red,
      });

  factory StatusChip.active(bool isActive) => StatusChip(isActive ? 'Active' : 'Inactive', color: isActive ? Colors.green : Colors.grey);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color.withValues(alpha: 1), fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 99});

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Decrease',
            onPressed: onChanged == null || value <= min ? null : () => onChanged!(value - 1),
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Increase',
            onPressed: onChanged == null || value >= max ? null : () => onChanged!(value + 1),
            icon: const Icon(Icons.add, size: 18),
          ),
        ]),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

/// Label/value row used in summaries (order totals, details).
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false, this.valueColor});

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: style?.copyWith(color: bold ? null : Theme.of(context).colorScheme.onSurfaceVariant))),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: style?.copyWith(color: valueColor))),
      ]),
    );
  }
}

/// Primary button that shows a spinner while [onPressed] runs.
class BusyButton extends StatefulWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.icon, this.outlined = false});

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final child = _busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 18), const SizedBox(width: 8)],
            Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
          ]);
    return widget.outlined ? OutlinedButton(onPressed: onPressed, child: child) : FilledButton(onPressed: onPressed, child: child);
  }
}
