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

  Future<Address> update(int id, Json data) async => Address.fromJson(await _api.put<Json>(ApiEndpoints.myAddress(id), data: data));

  Future<void> delete(int id) => _api.delete<void>(ApiEndpoints.myAddress(id));
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

  Future<Paged<OrderSummary>> list({OrderStatus? status, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.orders, query: {'status': status?.apiName, 'page': page, 'pageSize': 20}),
        OrderSummary.fromJson,
      );

  Future<OrderDetail> get(int id) async => OrderDetail.fromJson(await _api.get<Json>(ApiEndpoints.order(id)));

  Future<OrderDetail> cancel(int id, {String? reason}) async =>
      OrderDetail.fromJson(await _api.post<Json>(ApiEndpoints.cancelOrder(id), data: {'reason': reason}));

  Future<Payment> payment(int orderId) async => Payment.fromJson(await _api.get<Json>(ApiEndpoints.orderPayment(orderId)));

  Future<Payment> choosePaymentMethod(int orderId, PaymentMethod method) async =>
      Payment.fromJson(await _api.post<Json>(ApiEndpoints.orderPayment(orderId), data: {'method': method.apiName}));
}

class WishlistService {
  WishlistService(this._api);

  final ApiClient _api;

  Future<List<WishlistItem>> list() async =>
      (await _api.get<List<dynamic>>(ApiEndpoints.myWishlist)).map((e) => WishlistItem.fromJson(e as Json)).toList();

  Future<List<WishlistItem>> add(int productId) async => (await _api.post<List<dynamic>>(ApiEndpoints.myWishlistItems, data: {'productId': productId}))
      .map((e) => WishlistItem.fromJson(e as Json))
      .toList();

  Future<void> remove(int productId) => _api.delete<void>(ApiEndpoints.myWishlistItem(productId));
}

final cartServiceProvider = Provider((ref) => CartService(ref.watch(apiClientProvider)));
final addressServiceProvider = Provider((ref) => AddressService(ref.watch(apiClientProvider)));
final orderServiceProvider = Provider((ref) => OrderService(ref.watch(apiClientProvider)));
final wishlistServiceProvider = Provider((ref) => WishlistService(ref.watch(apiClientProvider)));
