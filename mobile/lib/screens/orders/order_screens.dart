import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/shopping.dart';
import '../../services/shopping_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetail, int>((ref, id) => ref.watch(orderServiceProvider).get(id));

/// Own order history (UC-053).
class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  OrderStatus? _status;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: Column(children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
                for (final s in OrderStatus.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
                ],
              ],
            ),
          ),
          Expanded(
            child: PagedListView<OrderSummary>(
              queryKey: _status,
              fetch: (page) => ref.read(orderServiceProvider).list(status: _status, page: page),
              emptyMessage: 'You have no orders yet.',
              emptyIcon: Icons.receipt_long_outlined,
              itemBuilder: (context, o, reload) => OrderSummaryCard(
                order: o,
                onTap: () async {
                  await context.push('/orders/${o.id}');
                  reload();
                },
              ),
            ),
          ),
        ]),
      );
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order, required this.onTap, this.showCustomer = false});

  final OrderSummary order;
  final VoidCallback onTap;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (!showCustomer) ...[AppImage(order.firstItemImageUrl, width: 64, height: 64), const SizedBox(width: 12)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('#${order.orderCode}', style: theme.textTheme.titleSmall)),
                  StatusChip.order(order.status),
                ]),
                const SizedBox(height: 4),
                Text(
                  showCustomer
                      ? '${order.customerName} · ${order.customerEmail}'
                      : '${order.firstItemName ?? ''}${order.itemCount > 1 ? ' and more' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Text(formatVnd(order.totalAmount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (order.paymentStatus != null) StatusChip.payment(order.paymentStatus!),
                  const Spacer(),
                  Text(formatDateTime(order.createdAt), style: theme.textTheme.labelSmall),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Own order details, cancellation and payment (UC-054, UC-055, UC-058, UC-059).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.justPlaced = false});

  final int orderId;
  final bool justPlaced;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _CancelDialog());
    if (reason == null || !context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(orderServiceProvider).cancel(orderId, reason: reason.isEmpty ? null : reason),
        success: 'Order cancelled');
    if (ok) ref.invalidate(orderDetailProvider(orderId));
  }

  Future<void> _changePayment(BuildContext context, WidgetRef ref, PaymentMethod method) async {
    final ok = await runGuarded(context, () => ref.read(orderServiceProvider).choosePaymentMethod(orderId, method),
        success: 'Payment method updated');
    if (ok) ref.invalidate(orderDetailProvider(orderId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: Text(order.value == null ? 'Order' : '#${order.value!.orderCode}'),
        leading: justPlaced ? IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.go('/home')) : null,
      ),
      body: AsyncValueView(
        value: order,
        onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        data: (o) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderDetailProvider(orderId).future),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (justPlaced) const _PlacedBanner(),
            OrderOverview(order: o),
            const SizedBox(height: 12),
            if (o.payment != null)
              PaymentCard(
                payment: o.payment!,
                orderCode: o.orderCode,
                onChangeMethod: o.status == OrderStatus.pending && o.payment!.status == PaymentStatus.pending
                    ? (m) => _changePayment(context, ref, m)
                    : null,
              ),
            const SizedBox(height: 12),
            OrderItemsCard(order: o),
            const SizedBox(height: 12),
            StatusTimeline(history: o.statusHistory),
            if (o.canCancel) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel order'),
              ),
            ],
          ]),
        ),
      ),
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
          subtitle: Text('Thank you for shopping with Sport Mate. You can follow your order here.'),
        ),
      );
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Reason (optional)'), maxLength: 500),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep order')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, _reason.text.trim()),
            child: const Text('Cancel order'),
          ),
        ],
      );
}

/// Status, delivery address and totals of an order (shared with the staff view).
class OrderOverview extends StatelessWidget {
  const OrderOverview({super.key, required this.order, this.showCustomer = false});

  final OrderDetail order;
  final bool showCustomer;

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
          if (showCustomer) InfoRow('Customer', order.customerName),
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
  const PaymentCard({super.key, required this.payment, required this.orderCode, this.onChangeMethod, this.actions});

  final Payment payment;
  final String orderCode;
  final void Function(PaymentMethod)? onChangeMethod;
  final Widget? actions;

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
          if (onChangeMethod != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onChangeMethod!(payment.method == PaymentMethod.cod ? PaymentMethod.bankTransfer : PaymentMethod.cod),
                child: Text(payment.method == PaymentMethod.cod ? 'Pay by bank transfer instead' : 'Pay on delivery instead'),
              ),
            ),
          ],
          if (actions != null) ...[const SizedBox(height: 8), actions!],
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

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.history});

  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final h in history.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.circle, size: 12),
                title: Text(h.toStatus.label),
                subtitle: Text([formatDateTime(h.changedAt), if (h.changedBy != null) h.changedBy!, if ((h.note ?? '').isNotEmpty) h.note!].join(' · ')),
              ),
          ]),
        ),
      );
}
