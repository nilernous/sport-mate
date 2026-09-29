import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/shopping.dart';
import '../../providers/shopping_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Own cart (UC-046, UC-048 – UC-050). Prices here are indicative; checkout recalculates them.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final items = cart.value?.items ?? const <CartItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (await confirmDialog(context, title: 'Clear cart', message: 'Remove all items from your cart?', confirmLabel: 'Clear', destructive: true) &&
                    context.mounted) {
                  runGuarded(context, () => ref.read(cartProvider.notifier).clear());
                }
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: AsyncValueView(
        value: cart,
        onRetry: () => ref.invalidate(cartProvider),
        data: (c) => c.items.isEmpty
            ? EmptyView(
                message: 'Your cart is empty.',
                icon: Icons.shopping_bag_outlined,
                action: FilledButton(onPressed: () => context.go('/shop'), child: const Text('Start shopping')),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(cartProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: c.items.length + (c.hasUnavailable ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (c.hasUnavailable && i == 0) {
                      return Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Some items are unavailable or low in stock. Update or remove them to check out.'),
                        ),
                      );
                    }
                    return _CartItemTile(c.items[i - (c.hasUnavailable ? 1 : 0)]);
                  },
                ),
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Estimated subtotal', style: Theme.of(context).textTheme.labelMedium),
                      Text(formatVnd(cart.value!.estimatedSubtotal), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  FilledButton(
                    onPressed: cart.value!.hasUnavailable ? null : () => context.push('/checkout'),
                    child: const Text('Checkout'),
                  ),
                ]),
              ),
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile(this.item);

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(cartProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => context.push('/products/${item.productId}'),
            child: AppImage(item.imageUrl, width: 84, height: 84),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              Text('${item.color} / ${item.size}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(formatVnd(item.unitPrice), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (!item.isAvailable)
                Text(item.availableStock > 0 ? 'Only ${item.availableStock} left' : 'No longer available',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                QuantityStepper(
                  value: item.quantity,
                  max: item.availableStock > 0 ? item.availableStock.clamp(1, 99) : item.quantity,
                  onChanged: (q) => runGuarded(context, () => notifier.updateQuantity(item.id, q)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => runGuarded(context, () => notifier.remove(item.id)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
