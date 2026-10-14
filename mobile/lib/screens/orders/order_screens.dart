import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/shopping.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Order confirmation shown right after checkout (UC-052). It displays the order returned by
/// the place-order call, so it needs no extra request.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, this.order});

  final OrderDetail? order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Scaffold(
      appBar: AppBar(
        title: Text(o == null ? 'Order placed' : '#${o.orderCode}'),
        leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.go('/home')),
      ),
      body: o == null
          ? EmptyView(
              message: 'Your order has been placed.',
              icon: Icons.check_circle_outline,
              action: FilledButton(onPressed: () => context.go('/home'), child: const Text('Continue shopping')),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              const _PlacedBanner(),
              OrderOverview(order: o),
              const SizedBox(height: 12),
              if (o.payment != null) PaymentCard(payment: o.payment!),
              const SizedBox(height: 12),
              OrderItemsCard(order: o),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.go('/home'), child: const Text('Continue shopping')),
            ]),
    );
  }
}

class _PlacedBanner extends StatelessWidget {
  const _PlacedBanner();

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.green.withValues(alpha: 0.1),
        margin: const EdgeInsets.only(bottom: 12),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green, size: 36),
          title: Text('Order placed!'),
          subtitle: Text('Thank you for shopping with Sport Mate.'),
        ),
      );
}

/// Status, delivery address and totals of an order.
class OrderOverview extends StatelessWidget {
  const OrderOverview({super.key, required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Placed ${formatDateTime(order.createdAt)}', style: theme.textTheme.bodySmall)),
            StatusChip.order(order.status),
          ]),
          const Divider(height: 24),
          Text('Deliver to', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text('${order.recipientName} · ${order.phoneNumber}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(order.deliveryAddress),
          if ((order.note ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text('Note: ${order.note}', style: theme.textTheme.bodySmall)],
          const Divider(height: 24),
          InfoRow('Subtotal', formatVnd(order.subtotal)),
          InfoRow('Shipping (${order.shippingMethod.apiName})', order.shippingFee == 0 ? 'Free' : formatVnd(order.shippingFee)),
          InfoRow('Total', formatVnd(order.totalAmount), bold: true),
        ]),
      ),
    );
  }
}

class OrderItemsCard extends StatelessWidget {
  const OrderItemsCard({super.key, required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: Text('Items', style: Theme.of(context).textTheme.titleMedium)),
          for (final item in order.items)
            ListTile(
              leading: AppImage(item.imageUrl, width: 48, height: 48),
              title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${item.color} / ${item.size} · ${formatVnd(item.unitPrice)} × ${item.quantity}'),
              trailing: Text(formatVnd(item.lineTotal)),
              onTap: () => context.push('/products/${item.productId}'),
            ),
        ]),
      );
}

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bank = payment.bankTransferInstructions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Payment', style: theme.textTheme.titleMedium)),
            StatusChip.payment(payment.status),
          ]),
          const SizedBox(height: 8),
          InfoRow('Method', payment.method.label),
          InfoRow('Amount', formatVnd(payment.amount)),
          if (payment.transferReference != null) InfoRow('Reference', payment.transferReference!),
          if (payment.confirmedAt != null) InfoRow('Confirmed', '${formatDateTime(payment.confirmedAt!)} by ${payment.confirmedBy ?? '-'}'),
          if ((payment.note ?? '').isNotEmpty) InfoRow('Note', payment.note!),
          if (bank != null) ...[
            const Divider(height: 24),
            Text('Bank transfer details', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Please transfer the exact amount with the content below. We will confirm it within one business day.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _CopyRow('Bank', bank.bankName),
            _CopyRow('Account number', bank.accountNumber),
            _CopyRow('Account name', bank.accountName),
            _CopyRow('Amount', bank.amount.toStringAsFixed(0), display: formatVnd(bank.amount)),
            _CopyRow('Transfer content', bank.transferContent),
          ],
        ]),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow(this.label, this.value, {this.display});

  final String label;
  final String value;
  final String? display;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(display ?? value, style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copy $label',
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            showMessage(context, '$label copied');
          },
        ),
      ]);
}
