import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/order.dart';
import '../../models/shopping.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import '../orders/order_screens.dart';

/// Search and list all orders (UC-056).
class AdminOrderListScreen extends ConsumerStatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  ConsumerState<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends ConsumerState<AdminOrderListScreen> {
  String? _keyword;
  OrderStatus? _status;
  PaymentStatus? _paymentStatus;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Order code, customer name, email or phone', prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
              ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              for (final s in OrderStatus.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
              ],
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Awaiting payment'),
                selected: _paymentStatus == PaymentStatus.pending,
                onSelected: (on) => setState(() => _paymentStatus = on ? PaymentStatus.pending : null),
              ),
            ]),
          ),
          Expanded(
            child: PagedListView<OrderSummary>(
              queryKey: (_keyword, _status, _paymentStatus),
              fetch: (page) => ref.read(adminServiceProvider).orders(keyword: _keyword, status: _status, paymentStatus: _paymentStatus, page: page),
              emptyMessage: 'No orders match these filters.',
              emptyIcon: Icons.receipt_long_outlined,
              itemBuilder: (context, o, reload) => OrderSummaryCard(
                order: o,
                showCustomer: true,
                onTap: () async {
                  await context.push('/admin/orders/${o.id}');
                  reload();
                },
              ),
            ),
          ),
        ]),
      );
}

final _adminOrderProvider = FutureProvider.autoDispose.family<OrderDetail, int>((ref, id) => ref.watch(adminServiceProvider).order(id));

/// Process an order: status transitions and payment handling (UC-057, UC-060).
class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  void _refresh(WidgetRef ref) => ref.invalidate(_adminOrderProvider(orderId));

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, OrderStatus target) async {
    final destructive = target == OrderStatus.cancelled;
    if (!await confirmDialog(context,
        title: '${target.label} order?',
        message: destructive ? 'The order will be cancelled and its stock returned.' : 'Move this order to ${target.label}.',
        confirmLabel: target.label,
        destructive: destructive)) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(adminServiceProvider).updateOrderStatus(orderId, target), success: 'Order updated');
    if (ok) _refresh(ref);
  }

  Future<void> _confirmTransfer(BuildContext context, WidgetRef ref, OrderDetail order) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _ConfirmTransferDialog(order: order));
    if (saved == true) _refresh(ref);
  }

  Future<void> _setPayment(BuildContext context, WidgetRef ref, Payment payment, PaymentStatus status) async {
    if (!await confirmDialog(context, title: 'Mark payment as ${status.label}?', message: 'This change is recorded with your name.', confirmLabel: status.label)) return;
    if (!context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(adminServiceProvider).updatePaymentStatus(payment.id, status), success: 'Payment updated');
    if (ok) _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(_adminOrderProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: Text(order.value == null ? 'Order' : '#${order.value!.orderCode}')),
      body: AsyncValueView(
        value: order,
        onRetry: () => _refresh(ref),
        data: (o) {
          final payment = o.payment;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(_adminOrderProvider(orderId).future),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              OrderOverview(order: o, showCustomer: true),
              const SizedBox(height: 12),
              if (o.allowedNextStatuses.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Update status', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final s in o.allowedNextStatuses)
                          s == OrderStatus.cancelled
                              ? OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                  onPressed: () => _changeStatus(context, ref, s),
                                  child: const Text('Cancel order'),
                                )
                              : FilledButton(onPressed: () => _changeStatus(context, ref, s), child: Text('Mark ${s.label}')),
                      ]),
                      if (payment?.method == PaymentMethod.bankTransfer && payment?.status != PaymentStatus.paid && o.status == OrderStatus.confirmed)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Bank-transfer orders ship only after the payment is confirmed.', style: TextStyle(fontSize: 12)),
                        ),
                    ]),
                  ),
                ),
              const SizedBox(height: 12),
              if (payment != null)
                PaymentCard(
                  payment: payment,
                  orderCode: o.orderCode,
                  actions: Wrap(spacing: 8, runSpacing: 8, children: [
                    if (payment.method == PaymentMethod.bankTransfer && payment.status == PaymentStatus.pending && o.status != OrderStatus.cancelled)
                      FilledButton.icon(
                        onPressed: () => _confirmTransfer(context, ref, o),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Confirm transfer'),
                      ),
                    if (payment.method == PaymentMethod.cod && payment.status == PaymentStatus.pending && o.status != OrderStatus.cancelled)
                      OutlinedButton(onPressed: () => _setPayment(context, ref, payment, PaymentStatus.paid), child: const Text('Cash collected')),
                    if (payment.status == PaymentStatus.pending)
                      OutlinedButton(onPressed: () => _setPayment(context, ref, payment, PaymentStatus.failed), child: const Text('Mark failed')),
                    if (payment.status == PaymentStatus.paid)
                      OutlinedButton(onPressed: () => _setPayment(context, ref, payment, PaymentStatus.refunded), child: const Text('Mark refunded')),
                  ]),
                ),
              const SizedBox(height: 12),
              OrderItemsCard(order: o),
              const SizedBox(height: 12),
              StatusTimeline(history: o.statusHistory),
            ]),
          );
        },
      ),
    );
  }
}

class _ConfirmTransferDialog extends ConsumerStatefulWidget {
  const _ConfirmTransferDialog({required this.order});

  final OrderDetail order;

  @override
  ConsumerState<_ConfirmTransferDialog> createState() => _ConfirmTransferDialogState();
}

class _ConfirmTransferDialogState extends ConsumerState<_ConfirmTransferDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late final _reference = TextEditingController(text: widget.order.orderCode);
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(
      context,
      () => ref.read(adminServiceProvider).confirmTransfer(
            widget.order.payment!.id,
            parseMoney(_amount.text)!.toDouble(),
            _reference.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
      success: 'Payment confirmed',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Confirm bank transfer'),
        content: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Check your bank statement first. Amount due: ${formatVnd(widget.order.payment!.amount)}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount received (VND)'),
                validator: (v) => Validators.money(v, allowZero: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(labelText: 'Transfer reference'),
                validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the reference from the bank statement' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          BusyButton(label: 'Confirm', onPressed: _save),
        ],
      );
}
