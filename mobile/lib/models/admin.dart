import 'common.dart';
import 'order.dart';

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

class DailyRevenue {
  const DailyRevenue(this.date, this.orders, this.revenue);

  final DateTime date;
  final int orders;
  final double revenue;

  factory DailyRevenue.fromJson(Json json) => DailyRevenue(toDate(json['date']), toInt(json['orders']), toDouble(json['revenue']));
}

class DashboardSummary {
  const DashboardSummary({
    required this.from,
    required this.to,
    required this.totalOrders,
    required this.paidOrders,
    required this.revenue,
    required this.averageOrderValue,
    required this.newCustomers,
    required this.cancelledOrders,
    required this.lowStockVariants,
    required this.ordersByStatus,
    required this.dailyRevenue,
    required this.revenueDefinition,
  });

  final DateTime from;
  final DateTime to;
  final int totalOrders;
  final int paidOrders;
  final double revenue;
  final double averageOrderValue;
  final int newCustomers;
  final int cancelledOrders;
  final int lowStockVariants;
  final Map<OrderStatus, int> ordersByStatus;
  final List<DailyRevenue> dailyRevenue;
  final String revenueDefinition;

  factory DashboardSummary.fromJson(Json json) => DashboardSummary(
        from: toDate(json['from']),
        to: toDate(json['to']),
        totalOrders: toInt(json['totalOrders']),
        paidOrders: toInt(json['paidOrders']),
        revenue: toDouble(json['revenue']),
        averageOrderValue: toDouble(json['averageOrderValue']),
        newCustomers: toInt(json['newCustomers']),
        cancelledOrders: toInt(json['cancelledOrders']),
        lowStockVariants: toInt(json['lowStockVariants']),
        ordersByStatus: {
          for (final e in (json['ordersByStatus'] as List? ?? []))
            parseOrderStatus((e as Json)['status']): toInt(e['count']),
        },
        dailyRevenue: toList(json['dailyRevenue'], DailyRevenue.fromJson),
        revenueDefinition: '${json['revenueDefinition']}',
      );
}

class OrderReportRow {
  const OrderReportRow(this.group, this.orderCount, this.totalAmount, this.paidAmount);

  final String group;
  final int orderCount;
  final double totalAmount;
  final double paidAmount;

  factory OrderReportRow.fromJson(Json json) =>
      OrderReportRow('${json['group']}', toInt(json['orderCount']), toDouble(json['totalAmount']), toDouble(json['paidAmount']));
}

class OrderReport {
  const OrderReport(this.groupBy, this.rows, this.totalOrders, this.totalAmount);

  final String groupBy;
  final List<OrderReportRow> rows;
  final int totalOrders;
  final double totalAmount;

  factory OrderReport.fromJson(Json json) =>
      OrderReport('${json['groupBy']}', toList(json['rows'], OrderReportRow.fromJson), toInt(json['totalOrders']), toDouble(json['totalAmount']));
}

class TopProduct {
  const TopProduct({required this.rank, required this.productId, required this.productName, this.imageUrl, required this.quantitySold, required this.revenue});

  final int rank;
  final int productId;
  final String productName;
  final String? imageUrl;
  final int quantitySold;
  final double revenue;

  factory TopProduct.fromJson(Json json) => TopProduct(
        rank: toInt(json['rank']),
        productId: toInt(json['productId']),
        productName: '${json['productName']}',
        imageUrl: json['imageUrl'] as String?,
        quantitySold: toInt(json['quantitySold']),
        revenue: toDouble(json['revenue']),
      );
}
