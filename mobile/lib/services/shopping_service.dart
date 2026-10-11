import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/common.dart';
import '../models/order.dart';
import '../models/shopping.dart';
import '../models/user.dart';

class CartService {
  CartService(this._api);

  final ApiClient _api;

  Future<Cart> get() async => Cart.fromJson(await _api.get<Json>(ApiEndpoints.cart));

  Future<Cart> add(int variantId, int quantity) async =>
      Cart.fromJson(await _api.post<Json>(ApiEndpoints.cartItems, data: {'variantId': variantId, 'quantity': quantity}));

  Future<Cart> update(int itemId, int quantity) async =>
      Cart.fromJson(await _api.patch<Json>(ApiEndpoints.cartItem(itemId), data: {'quantity': quantity}));

  Future<Cart> remove(int itemId) async => Cart.fromJson(await _api.delete<Json>(ApiEndpoints.cartItem(itemId)));

  Future<void> clear() => _api.delete<void>(ApiEndpoints.cart);
}

class AddressService {
  AddressService(this._api);

  final ApiClient _api;

  Future<List<Address>> list() async =>
      (await _api.get<List<dynamic>>(ApiEndpoints.myAddresses)).map((e) => Address.fromJson(e as Json)).toList();

  Future<Address> create(Json data) async => Address.fromJson(await _api.post<Json>(ApiEndpoints.myAddresses, data: data));
}

class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  Future<CheckoutPreview> preview({int? addressId, required ShippingMethod shippingMethod}) async =>
      CheckoutPreview.fromJson(await _api.post<Json>(ApiEndpoints.checkoutPreview, data: {
        'addressId': addressId,
        'shippingMethod': shippingMethod.apiName,
      }));

  /// [idempotencyKey] makes a retried submission return the same order instead of a duplicate.
  Future<OrderDetail> place({
    required int addressId,
    required ShippingMethod shippingMethod,
    required PaymentMethod paymentMethod,
    String? note,
    required String idempotencyKey,
  }) async =>
      OrderDetail.fromJson(await _api.post<Json>(
        ApiEndpoints.orders,
        headers: {'Idempotency-Key': idempotencyKey},
        data: {
          'addressId': addressId,
          'shippingMethod': shippingMethod.apiName,
          'paymentMethod': paymentMethod.apiName,
          'note': note,
        },
      ));
}

final cartServiceProvider = Provider((ref) => CartService(ref.watch(apiClientProvider)));
final addressServiceProvider = Provider((ref) => AddressService(ref.watch(apiClientProvider)));
final orderServiceProvider = Provider((ref) => OrderService(ref.watch(apiClientProvider)));
