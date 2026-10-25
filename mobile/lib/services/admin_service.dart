import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/admin.dart';
import '../models/catalog.dart';
import '../models/common.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/user.dart';

/// Staff & Admin operations on the shared /admin/* endpoints. Admin-only calls
/// (users, coupons, reports) are rejected with 403 for Staff by the API.
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

  // ---------- Products, variants, images ----------

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

  Future<ProductImage> addImageUrl(int productId, String url, {String? altText, bool isPrimary = false}) async =>
      ProductImage.fromJson(await _api.postForm<Json>(
        ApiEndpoints.adminProductImages(productId),
        FormData.fromMap({'url': url, if (altText != null && altText.isNotEmpty) 'altText': altText, 'isPrimary': isPrimary}),
      ));

  Future<ProductImage> uploadImage(int productId, List<int> bytes, String fileName, String contentType, {bool isPrimary = false}) async =>
      ProductImage.fromJson(await _api.postForm<Json>(
        ApiEndpoints.adminProductImages(productId),
        FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(contentType)),
          'isPrimary': isPrimary,
        }),
      ));

  Future<ProductImage> updateImage(int id, {String? altText, required int displayOrder, required bool isPrimary}) async =>
      ProductImage.fromJson(await _api.put<Json>(ApiEndpoints.adminImage(id),
          data: {'altText': altText, 'displayOrder': displayOrder, 'isPrimary': isPrimary}));

  Future<void> deleteImage(int id) => _api.delete<void>(ApiEndpoints.adminImage(id));

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

  Future<Payment> confirmTransfer(int paymentId, double amount, String reference, {String? note}) async => Payment.fromJson(
      await _api.patch<Json>(ApiEndpoints.adminPaymentConfirm(paymentId), data: {'amount': amount, 'transferReference': reference, 'note': note}));

  Future<Payment> updatePaymentStatus(int paymentId, PaymentStatus status, {String? note}) async => Payment.fromJson(
      await _api.patch<Json>(ApiEndpoints.adminPaymentStatus(paymentId), data: {'status': status.apiName, 'note': note}));

  // ---------- Reviews ----------

  Future<Paged<Review>> reviews({ReviewStatus? status, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminReviews, query: {'status': status?.apiName, 'page': page, 'pageSize': 20}),
        Review.fromJson,
      );

  Future<Review> moderateReview(int id, ReviewStatus status) async =>
      Review.fromJson(await _api.patch<Json>(ApiEndpoints.adminReviewStatus(id), data: {'status': status.apiName}));

  // ---------- Users (Admin) ----------

  Future<Paged<AdminUser>> users({String? keyword, UserRole? role, bool? isActive, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminUsers, query: {
          'keyword': keyword,
          'role': role?.apiName,
          'isActive': isActive,
          'page': page,
          'pageSize': 20,
        }),
        AdminUser.fromJson,
      );

  Future<AdminUser> user(int id) async => AdminUser.fromJson(await _api.get<Json>(ApiEndpoints.adminUser(id)));

  Future<AdminUser> createUser(Json data) async => AdminUser.fromJson(await _api.post<Json>(ApiEndpoints.adminUsers, data: data));

  Future<AdminUser> updateUser(int id, Json data) async => AdminUser.fromJson(await _api.put<Json>(ApiEndpoints.adminUser(id), data: data));

  Future<AdminUser> setUserActive(int id, bool isActive) async =>
      AdminUser.fromJson(await _api.patch<Json>(ApiEndpoints.adminUserStatus(id), data: {'isActive': isActive}));

  Future<AdminUser> setUserRole(int id, UserRole role) async =>
      AdminUser.fromJson(await _api.patch<Json>(ApiEndpoints.adminUserRole(id), data: {'role': role.apiName}));

  // ---------- Coupons (Admin) ----------

  Future<Paged<Coupon>> coupons({String? keyword, int page = 1}) async => Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.adminCoupons, query: {'keyword': keyword, 'page': page, 'pageSize': 50}),
        Coupon.fromJson,
      );

  Future<Coupon> coupon(int id) async => Coupon.fromJson(await _api.get<Json>(ApiEndpoints.adminCoupon(id)));

  Future<Coupon> saveCoupon(int? id, Json data) async => Coupon.fromJson(id == null
      ? await _api.post<Json>(ApiEndpoints.adminCoupons, data: data)
      : await _api.put<Json>(ApiEndpoints.adminCoupon(id), data: data));

  Future<DeleteResult> deleteCoupon(int id) async => DeleteResult.fromJson(await _api.delete<Json>(ApiEndpoints.adminCoupon(id)));
}

final adminServiceProvider = Provider((ref) => AdminService(ref.watch(apiClientProvider)));
