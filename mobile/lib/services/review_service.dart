import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/common.dart';
import '../models/review.dart';

class ReviewService {
  ReviewService(this._api);

  final ApiClient _api;

  Future<ProductReviews> forProduct(int productId, {int page = 1, int pageSize = 20}) async =>
      ProductReviews.fromJson(await _api.get<Json>(ApiEndpoints.productReviews(productId), query: {'page': page, 'pageSize': pageSize}));

  Future<MyReviewStatus> mine(int productId) async => MyReviewStatus.fromJson(await _api.get<Json>(ApiEndpoints.myProductReview(productId)));

  Future<Review> create(int productId, int rating, String? comment) async =>
      Review.fromJson(await _api.post<Json>(ApiEndpoints.productReviews(productId), data: {'rating': rating, 'comment': comment}));

  Future<Review> update(int reviewId, int rating, String? comment) async =>
      Review.fromJson(await _api.put<Json>(ApiEndpoints.review(reviewId), data: {'rating': rating, 'comment': comment}));

  Future<void> delete(int reviewId) => _api.delete<void>(ApiEndpoints.review(reviewId));
}

final reviewServiceProvider = Provider((ref) => ReviewService(ref.watch(apiClientProvider)));
