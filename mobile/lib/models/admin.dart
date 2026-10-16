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
