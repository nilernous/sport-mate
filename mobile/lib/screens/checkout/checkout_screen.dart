import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/shopping.dart';
import '../../models/user.dart';
import '../../providers/shopping_providers.dart';
import '../../services/shopping_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Checkout (UC-051, UC-052). All totals come from the server preview.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _addressId;
  ShippingMethod _shipping = ShippingMethod.standard;
  PaymentMethod _payment = PaymentMethod.cod;
  final _note = TextEditingController();

  CheckoutPreview? _preview;
  Object? _error;
  bool _loading = true;

  /// One key per checkout attempt, so a retried submit cannot create a second order (BR-036).
  final String _idempotencyKey = List.generate(32, (_) => Random.secure().nextInt(16).toRadixString(16)).join();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final addresses = await ref.read(addressServiceProvider).list();
      if (addresses.isNotEmpty) _addressId = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first).id;
    } catch (_) {
      // The preview reports the missing address.
    }
    await _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    setState(() => _loading = true);
    try {
      final preview = await ref.read(orderServiceProvider).preview(addressId: _addressId, shippingMethod: _shipping);
      setState(() {
        _preview = preview;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseAddress() async {
    final selected = await context.push<Address>('/addresses?select=1');
    if (selected != null) {
      _addressId = selected.id;
      await _refreshPreview();
    }
  }

  Future<void> _placeOrder() async {
    final preview = _preview;
    if (preview == null || _addressId == null) return;
    try {
      final order = await ref.read(orderServiceProvider).place(
            addressId: _addressId!,
            shippingMethod: _shipping,
            paymentMethod: _payment,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            idempotencyKey: _idempotencyKey,
          );
      ref.invalidate(cartProvider);
      if (mounted) context.pushReplacement('/orders/confirmation', extra: order);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      // Stock or prices may have changed: show the latest server totals.
      await _refreshPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: preview == null
          ? (_error != null ? ErrorView(error: _error!, onRetry: _refreshPreview) : const LoadingView())
          : Stack(children: [
              ListView(padding: const EdgeInsets.all(16), children: [
                Text('Delivery address', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(preview.address?.recipientName ?? 'Add a delivery address'),
                    subtitle: preview.address == null ? null : Text('${preview.address!.phoneNumber}\n${preview.address!.fullAddress}'),
                    isThreeLine: preview.address != null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseAddress,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Items (${preview.items.fold<int>(0, (s, i) => s + i.quantity)})', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in preview.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      AppImage(item.imageUrl, width: 56, height: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${item.color} / ${item.size} × ${item.quantity}', style: theme.textTheme.bodySmall),
                        ]),
                      ),
                      Text(formatVnd(item.lineTotal)),
                    ]),
                  ),
                const SizedBox(height: 12),
                Text('Shipping', style: theme.textTheme.titleMedium),
                RadioGroup<ShippingMethod>(
                  groupValue: _shipping,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _shipping = v);
                    _refreshPreview();
                  },
                  child: Column(children: [
                    for (final option in preview.shippingOptions)
                      RadioListTile<ShippingMethod>(
                        contentPadding: EdgeInsets.zero,
                        value: option.method,
                        title: Text('${option.method.apiName} · ${option.fee == 0 ? 'Free' : formatVnd(option.fee)}'),
                        subtitle: Text(option.description),
                      ),
                  ]),
                ),
                Text('Payment', style: theme.textTheme.titleMedium),
                RadioGroup<PaymentMethod>(
                  groupValue: _payment,
                  onChanged: (v) => setState(() => _payment = v ?? _payment),
                  child: Column(children: [
                    for (final method in PaymentMethod.values)
                      RadioListTile<PaymentMethod>(
                        contentPadding: EdgeInsets.zero,
                        value: method,
                        title: Text(method.label),
                        subtitle: Text(method == PaymentMethod.cod
                            ? 'Pay in cash when your order arrives.'
                            : 'Transfer to our bank account; we confirm it before shipping.'),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                TextField(controller: _note, maxLength: 500, decoration: const InputDecoration(labelText: 'Note for the shop (optional)')),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      InfoRow('Subtotal', formatVnd(preview.subtotal)),
                      InfoRow('Shipping', preview.shippingFee == 0 ? 'Free' : formatVnd(preview.shippingFee)),
                      const Divider(),
                      InfoRow('Total', formatVnd(preview.total), bold: true),
                    ]),
                  ),
                ),
                for (final problem in preview.problems)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(problem, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 80),
              ]),
              if (_loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
            ]),
      bottomNavigationBar: preview == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: BusyButton(
                  label: 'Place order · ${formatVnd(preview.total)}',
                  onPressed: preview.canPlaceOrder && !_loading ? _placeOrder : null,
                ),
              ),
            ),
    );
  }
}
