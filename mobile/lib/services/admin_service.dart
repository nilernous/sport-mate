import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/admin.dart';
import '../models/catalog.dart';
import '../models/common.dart';
import '../models/order.dart';

/// Staff & Admin catalog operations on the shared /admin/* endpoints.
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  List<T> _list<T>(List<dynamic> data, T Function(Json) fromJson) => data.map((e) => fromJson(e as Json)).toList();

  // ---------- Categories & brands ----------

  Future<List<Category>> categories({String? keyword}) async =>
      _list(await _api.get<List<dynamic>>(ApiEndpoints.adminCategories, query: {'keyword': keyword}), Category.fromJson);

  Future<Category> saveCategory(int? id, Json data) async => Category.fromJson(id == null
      ? await _api.post<Json>(ApiEndpoints.adminCategories, data: data)
      : await _api.put<Json>(ApiEndpoints.adminCategory(id), data: data));

  Future<DeleteResult> deleteCategory(int id) async => DeleteResult.fromJson(await _api.delete<Json>(ApiEndpoints.adminCategory(id)));

  Future<List<Brand>> brands({String? keyword}) async =>
      _list(await _api.get<List<dynamic>>(ApiEndpoints.adminBrands, query: {'keyword': keyword}), Brand.fromJson);

  Future<Brand> saveBrand(int? id, Json data) async => Brand.fromJson(id == null
      ? await _api.post<Json>(ApiEndpoints.adminBrands, data: data)
      : await _api.put<Json>(ApiEndpoints.adminBrand(id), data: data));

  Future<DeleteResult> deleteBrand(int id) async => DeleteResult.fromJson(await _api.delete<Json>(ApiEndpoints.adminBrand(id)));

  // ---------- Products & variants ----------

  Future<Paged<ProductSummary>> products({String? keyword, bool? isActive, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminProducts, query: {'keyword': keyword, 'isActive': isActive, 'page': page, 'pageSize': 20}),
        ProductSummary.fromJson,
      );

  Future<ProductDetail> product(int id) async => ProductDetail.fromJson(await _api.get<Json>(ApiEndpoints.adminProduct(id)));

  Future<ProductDetail> saveProduct(int? id, Json data) async => ProductDetail.fromJson(id == null
      ? await _api.post<Json>(ApiEndpoints.adminProducts, data: data)
      : await _api.put<Json>(ApiEndpoints.adminProduct(id), data: data));

  Future<ProductDetail> setProductActive(int id, bool isActive) async =>
      ProductDetail.fromJson(await _api.patch<Json>(ApiEndpoints.adminProductStatus(id), data: {'isActive': isActive}));

  Future<DeleteResult> deleteProduct(int id) async => DeleteResult.fromJson(await _api.delete<Json>(ApiEndpoints.adminProduct(id)));

  Future<Variant> createVariant(int productId, Json data) async =>
      Variant.fromJson(await _api.post<Json>(ApiEndpoints.adminProductVariants(productId), data: data));

  Future<Variant> updateVariant(int id, Json data) async => Variant.fromJson(await _api.put<Json>(ApiEndpoints.adminVariant(id), data: data));

  Future<DeleteResult> deleteVariant(int id) async => DeleteResult.fromJson(await _api.delete<Json>(ApiEndpoints.adminVariant(id)));

  // ---------- Inventory ----------

  Future<Paged<InventoryItem>> inventory({String? keyword, int? maxStock, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminInventory, query: {'keyword': keyword, 'maxStock': maxStock, 'page': page, 'pageSize': 30}),
        InventoryItem.fromJson,
      );

  Future<InventoryItem> adjustStock(int variantId, int quantityChange, String reason) async => InventoryItem.fromJson(
      await _api.patch<Json>(ApiEndpoints.adminVariantStock(variantId), data: {'quantityChange': quantityChange, 'reason': reason}));

  Future<Paged<StockMovement>> movements({int? variantId, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminInventoryMovements, query: {'variantId': variantId, 'page': page, 'pageSize': 30}),
        StockMovement.fromJson,
      );

  // ---------- Orders & payments ----------

  Future<Paged<OrderSummary>> orders({String? keyword, OrderStatus? status, PaymentStatus? paymentStatus, int page = 1}) async =>
      Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminOrders, query: {
          'keyword': keyword,
          'status': status?.apiName,
          'paymentStatus': paymentStatus?.apiName,
          'page': page,
          'pageSize': 20,
        }),
        OrderSummary.fromJson,
      );

  Future<OrderDetail> order(int id) async => OrderDetail.fromJson(await _api.get<Json>(ApiEndpoints.adminOrder(id)));

  Future<OrderDetail> updateOrderStatus(int id, OrderStatus status, {String? note}) async =>
      OrderDetail.fromJson(await _api.patch<Json>(ApiEndpoints.adminOrderStatus(id), data: {'status': status.apiName, 'note': note}));
}

final adminServiceProvider = Provider((ref) => AdminService(ref.watch(apiClientProvider)));
