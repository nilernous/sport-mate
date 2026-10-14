import 'common.dart';
import 'shopping.dart';

enum OrderStatus { pending, confirmed, shipping, completed, cancelled }

enum PaymentStatus { pending, paid, failed, refunded }

extension OrderStatusX on OrderStatus {
  String get apiName => name[0].toUpperCase() + name.substring(1);
  String get label => apiName;
}

extension PaymentStatusX on PaymentStatus {
  String get apiName => name[0].toUpperCase() + name.substring(1);
  String get label => apiName;
}

OrderStatus parseOrderStatus(Object? v) => enumByName(OrderStatus.values, v, OrderStatus.pending);

PaymentStatus parsePaymentStatus(Object? v) => enumByName(PaymentStatus.values, v, PaymentStatus.pending);

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.size,
    required this.color,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String productName;
  final String sku;
  final String size;
  final String color;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromJson(Json json) => OrderItem(
        id: toInt(json['id']),
        productId: toInt(json['productId']),
        productName: '${json['productName']}',
        sku: '${json['sku']}',
        size: '${json['size']}',
        color: '${json['color']}',
        imageUrl: json['imageUrl'] as String?,
        unitPrice: toDouble(json['unitPrice']),
        quantity: toInt(json['quantity']),
        lineTotal: toDouble(json['lineTotal']),
      );
}

class BankTransferInstructions {
  const BankTransferInstructions({required this.bankName, required this.accountNumber, required this.accountName, required this.amount, required this.transferContent});

  final String bankName;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String transferContent;

  factory BankTransferInstructions.fromJson(Json json) => BankTransferInstructions(
        bankName: '${json['bankName']}',
        accountNumber: '${json['accountNumber']}',
        accountName: '${json['accountName']}',
        amount: toDouble(json['amount']),
        transferContent: '${json['transferContent']}',
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.transferReference,
    this.confirmedBy,
    this.confirmedAt,
    this.note,
    this.bankTransferInstructions,
  });

  final int id;
  final int orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? transferReference;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String? note;
  final BankTransferInstructions? bankTransferInstructions;

  factory Payment.fromJson(Json json) => Payment(
        id: toInt(json['id']),
        orderId: toInt(json['orderId']),
        method: parsePaymentMethod(json['method']),
        status: parsePaymentStatus(json['status']),
        amount: toDouble(json['amount']),
        transferReference: json['transferReference'] as String?,
        confirmedBy: json['confirmedBy'] as String?,
        confirmedAt: toDateOrNull(json['confirmedAt']),
        note: json['note'] as String?,
        bankTransferInstructions: json['bankTransferInstructions'] == null
            ? null
            : BankTransferInstructions.fromJson(json['bankTransferInstructions'] as Json),
      );
}

class StatusChange {
  const StatusChange({this.fromStatus, required this.toStatus, this.changedBy, this.note, required this.changedAt});

  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final String? changedBy;
  final String? note;
  final DateTime changedAt;

  factory StatusChange.fromJson(Json json) => StatusChange(
        fromStatus: json['fromStatus'] == null ? null : parseOrderStatus(json['fromStatus']),
        toStatus: parseOrderStatus(json['toStatus']),
        changedBy: json['changedBy'] as String?,
        note: json['note'] as String?,
        changedAt: toDate(json['changedAt']),
      );
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.shippingMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingFee,
    required this.totalAmount,
    this.couponCode,
    required this.recipientName,
    required this.phoneNumber,
    required this.deliveryAddress,
    this.note,
    required this.items,
    this.payment,
    required this.statusHistory,
    required this.canCancel,
    required this.allowedNextStatuses,
    required this.createdAt,
  });

  final int id;
  final String orderCode;
  final int customerId;
  final String customerName;
  final OrderStatus status;
  final ShippingMethod shippingMethod;
  final double subtotal;
  final double discountAmount;
  final double shippingFee;
  final double totalAmount;
  final String? couponCode;
  final String recipientName;
  final String phoneNumber;
  final String deliveryAddress;
  final String? note;
  final List<OrderItem> items;
  final Payment? payment;
  final List<StatusChange> statusHistory;
  final bool canCancel;
  final List<OrderStatus> allowedNextStatuses;
  final DateTime createdAt;

  factory OrderDetail.fromJson(Json json) {
    final address = json['deliveryAddress'] as Json? ?? const {};
    return OrderDetail(
      id: toInt(json['id']),
      orderCode: '${json['orderCode']}',
      customerId: toInt(json['customerId']),
      customerName: '${json['customerName']}',
      status: parseOrderStatus(json['status']),
      shippingMethod: parseShipping(json['shippingMethod']),
      subtotal: toDouble(json['subtotal']),
      discountAmount: toDouble(json['discountAmount']),
      shippingFee: toDouble(json['shippingFee']),
      totalAmount: toDouble(json['totalAmount']),
      couponCode: json['couponCode'] as String?,
      recipientName: '${address['recipientName'] ?? ''}',
      phoneNumber: '${address['phoneNumber'] ?? ''}',
      deliveryAddress: [address['addressLine'], address['ward'], address['district'], address['city']]
          .where((s) => s != null && '$s'.isNotEmpty)
          .join(', '),
      note: json['note'] as String?,
      items: toList(json['items'], OrderItem.fromJson),
      payment: json['payment'] == null ? null : Payment.fromJson(json['payment'] as Json),
      statusHistory: toList(json['statusHistory'], StatusChange.fromJson),
      canCancel: json['canCancel'] == true,
      allowedNextStatuses: (json['allowedNextStatuses'] as List? ?? []).map(parseOrderStatus).toList(),
      createdAt: toDate(json['createdAt']),
    );
  }
}
