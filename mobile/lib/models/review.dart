import 'common.dart';

enum ReviewStatus { approved, hidden, rejected }

extension ReviewStatusX on ReviewStatus {
  String get apiName => name[0].toUpperCase() + name.substring(1);
  String get label => apiName;
}

ReviewStatus parseReviewStatus(Object? v) => enumByName(ReviewStatus.values, v, ReviewStatus.approved);

class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int productId;
  final String productName;
  final int userId;
  final String userName;
  final int rating;
  final String? comment;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Review.fromJson(Json json) => Review(
        id: toInt(json['id']),
        productId: toInt(json['productId']),
        productName: '${json['productName']}',
        userId: toInt(json['userId']),
        userName: '${json['userName']}',
        rating: toInt(json['rating']),
        comment: json['comment'] as String?,
        status: parseReviewStatus(json['status']),
        createdAt: toDate(json['createdAt']),
        updatedAt: toDate(json['updatedAt']),
      );
}

class ReviewSummary {
  const ReviewSummary({required this.averageRating, required this.reviewCount, required this.ratingCounts});

  final double averageRating;
  final int reviewCount;
  final Map<int, int> ratingCounts;

  factory ReviewSummary.fromJson(Json json) {
    final counts = <int, int>{};
    (json['ratingCounts'] as Map? ?? {}).forEach((k, v) => counts[int.parse('$k')] = toInt(v));
    return ReviewSummary(averageRating: toDouble(json['averageRating']), reviewCount: toInt(json['reviewCount']), ratingCounts: counts);
  }
}

class ProductReviews {
  const ProductReviews(this.summary, this.reviews);

  final ReviewSummary summary;
  final Paged<Review> reviews;

  factory ProductReviews.fromJson(Json json) => ProductReviews(
        ReviewSummary.fromJson(json['summary'] as Json),
        Paged.fromJson(json['reviews'] as Json, Review.fromJson),
      );
}

class MyReviewStatus {
  const MyReviewStatus({required this.canReview, this.reason, this.review});

  final bool canReview;
  final String? reason;
  final Review? review;

  factory MyReviewStatus.fromJson(Json json) => MyReviewStatus(
        canReview: json['canReview'] == true,
        reason: json['reason'] as String?,
        review: json['review'] == null ? null : Review.fromJson(json['review'] as Json),
      );
}
