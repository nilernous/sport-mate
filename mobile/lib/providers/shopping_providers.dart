import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shopping.dart';
import '../models/user.dart';
import '../services/shopping_service.dart';
import 'auth_provider.dart';

/// Cart shared by the cart badge, cart screen and checkout. Only customers have a cart.
class CartNotifier extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() async {
    final isCustomer = ref.watch(authProvider.select((a) => a.isCustomer));
    if (!isCustomer) return Cart.empty;
    return ref.read(cartServiceProvider).get();
  }

  CartService get _service => ref.read(cartServiceProvider);

  Future<void> refresh() async {
    state = AsyncData(await _service.get());
  }

  Future<void> add(int variantId, int quantity) async {
    state = AsyncData(await _service.add(variantId, quantity));
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    state = AsyncData(await _service.update(itemId, quantity));
  }

  Future<void> remove(int itemId) async {
    state = AsyncData(await _service.remove(itemId));
  }

  Future<void> clear() async {
    await _service.clear();
    state = const AsyncData(Cart.empty);
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).value?.totalQuantity ?? 0);

/// Wishlist entries; product screens use it to show the heart state.
class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() async {
    final isCustomer = ref.watch(authProvider.select((a) => a.isCustomer));
    if (!isCustomer) return const [];
    return ref.read(wishlistServiceProvider).list();
  }

  Future<void> toggle(int productId) async {
    final service = ref.read(wishlistServiceProvider);
    final current = state.value ?? const [];
    if (current.any((w) => w.productId == productId)) {
      await service.remove(productId);
      state = AsyncData(current.where((w) => w.productId != productId).toList());
    } else {
      state = AsyncData(await service.add(productId));
    }
  }

  Future<void> remove(int productId) async {
    await ref.read(wishlistServiceProvider).remove(productId);
    state = AsyncData((state.value ?? const []).where((w) => w.productId != productId).toList());
  }
}

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

final isWishlistedProvider = Provider.family<bool, int>(
  (ref, productId) => ref.watch(wishlistProvider).value?.any((w) => w.productId == productId) ?? false,
);

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) => ref.watch(addressServiceProvider).list());
