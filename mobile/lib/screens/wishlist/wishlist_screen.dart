import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../providers/shopping_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Own wishlist (UC-073, UC-075).
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: AsyncValueView(
        value: wishlist,
        onRetry: () => ref.invalidate(wishlistProvider),
        data: (items) => items.isEmpty
            ? EmptyView(
                message: 'Save products you love by tapping the heart.',
                icon: Icons.favorite_border,
                action: FilledButton(onPressed: () => context.go('/shop'), child: const Text('Browse products')),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(wishlistProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        onTap: item.isActive ? () => context.push('/products/${item.productId}') : null,
                        leading: AppImage(item.imageUrl, width: 64, height: 64),
                        title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(!item.isActive
                            ? 'No longer available'
                            : item.inStock
                                ? formatVnd(item.price)
                                : '${formatVnd(item.price)} · Sold out'),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => runGuarded(context, () => ref.read(wishlistProvider.notifier).remove(item.productId), success: 'Removed from wishlist'),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
