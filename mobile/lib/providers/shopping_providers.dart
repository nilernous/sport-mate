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

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) => ref.watch(addressServiceProvider).list());
