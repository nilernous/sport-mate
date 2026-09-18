import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/catalog.dart';
import '../models/common.dart';

/// Public catalog: browsing, search, filters and product details.
class ProductService {
  ProductService(this._api);

  final ApiClient _api;

  Future<Paged<ProductSummary>> search(ProductFilter filter, {int page = 1, int pageSize = AppConfig.defaultPageSize}) async =>
      Paged.fromJson(
        await _api.get<Json>(ApiEndpoints.products, query: {...filter.toQuery(), 'page': page, 'pageSize': pageSize}),
        ProductSummary.fromJson,
      );

  Future<ProductDetail> get(int id) async => ProductDetail.fromJson(await _api.get<Json>(ApiEndpoints.product(id)));

  Future<FilterOptions> filterOptions() async => FilterOptions.fromJson(await _api.get<Json>(ApiEndpoints.productFilters));

  Future<List<Category>> categories() async =>
      (await _api.get<List<dynamic>>(ApiEndpoints.categories)).map((e) => Category.fromJson(e as Json)).toList();

  Future<List<Brand>> brands() async =>
      (await _api.get<List<dynamic>>(ApiEndpoints.brands)).map((e) => Brand.fromJson(e as Json)).toList();
}

final productServiceProvider = Provider((ref) => ProductService(ref.watch(apiClientProvider)));
