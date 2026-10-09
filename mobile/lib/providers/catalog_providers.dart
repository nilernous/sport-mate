import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../services/product_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.watch(productServiceProvider).categories());

final filterOptionsProvider = FutureProvider<FilterOptions>((ref) => ref.watch(productServiceProvider).filterOptions());

final newArrivalsProvider = FutureProvider.autoDispose<List<ProductSummary>>((ref) async =>
    (await ref.watch(productServiceProvider).search(const ProductFilter(sort: ProductSort.newest), pageSize: 10)).items);

final topRatedProvider = FutureProvider.autoDispose<List<ProductSummary>>((ref) async =>
    (await ref.watch(productServiceProvider).search(const ProductFilter(sort: ProductSort.rating), pageSize: 10)).items);

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail, int>((ref, id) => ref.watch(productServiceProvider).get(id));
