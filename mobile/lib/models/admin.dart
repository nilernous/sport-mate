import 'common.dart';

class InventoryItem {
  const InventoryItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.size,
    required this.color,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
  });

  final int variantId;
  final int productId;
  final String productName;
  final String sku;
  final String size;
  final String color;
  final double price;
  final int stockQuantity;
  final bool isActive;

  factory InventoryItem.fromJson(Json json) => InventoryItem(
        variantId: toInt(json['variantId']),
        productId: toInt(json['productId']),
        productName: '${json['productName']}',
        sku: '${json['sku']}',
        size: '${json['size']}',
        color: '${json['color']}',
        price: toDouble(json['price']),
        stockQuantity: toInt(json['stockQuantity']),
        isActive: json['isActive'] == true,
      );
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.sku,
    required this.productName,
    required this.quantityChange,
    required this.quantityAfter,
    required this.type,
    this.reason,
    this.orderId,
    this.actorName,
    required this.createdAt,
  });

  final int id;
  final String sku;
  final String productName;
  final int quantityChange;
  final int quantityAfter;
  final String type;
  final String? reason;
  final int? orderId;
  final String? actorName;
  final DateTime createdAt;

  factory StockMovement.fromJson(Json json) => StockMovement(
        id: toInt(json['id']),
        sku: '${json['sku']}',
        productName: '${json['productName']}',
        quantityChange: toInt(json['quantityChange']),
        quantityAfter: toInt(json['quantityAfter']),
        type: '${json['type']}',
        reason: json['reason'] as String?,
        orderId: json['orderId'] == null ? null : toInt(json['orderId']),
        actorName: json['actorName'] as String?,
        createdAt: toDate(json['createdAt']),
      );
}

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderAmount,
    this.applicableCategoryId,
    this.applicableCategoryName,
    required this.startsAt,
    required this.endsAt,
    this.usageLimit,
    this.perUserLimit,
    required this.usedCount,
    required this.isActive,
  });

  final int id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? applicableCategoryId;
  final String? applicableCategoryName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? usageLimit;
  final int? perUserLimit;
  final int usedCount;
  final bool isActive;

  bool get isPercentage => discountType == 'Percentage';

  bool get isExpired => DateTime.now().isAfter(endsAt);

  factory Coupon.fromJson(Json json) => Coupon(
        id: toInt(json['id']),
        code: '${json['code']}',
        description: json['description'] as String?,
        discountType: '${json['discountType']}',
        discountValue: toDouble(json['discountValue']),
        maxDiscountAmount: json['maxDiscountAmount'] == null ? null : toDouble(json['maxDiscountAmount']),
        minOrderAmount: toDouble(json['minOrderAmount']),
        applicableCategoryId: json['applicableCategoryId'] == null ? null : toInt(json['applicableCategoryId']),
        applicableCategoryName: json['applicableCategoryName'] as String?,
        startsAt: toDate(json['startsAt']),
        endsAt: toDate(json['endsAt']),
        usageLimit: json['usageLimit'] == null ? null : toInt(json['usageLimit']),
        perUserLimit: json['perUserLimit'] == null ? null : toInt(json['perUserLimit']),
        usedCount: toInt(json['usedCount']),
        isActive: json['isActive'] == true,
      );
}
