import 'common.dart';
import 'user.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.size,
    required this.color,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.availableStock,
    required this.isAvailable,
  });

  final int id;
  final int variantId;
  final int productId;
  final String productName;
  final String sku;
  final String size;
  final String color;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int availableStock;
  final bool isAvailable;

  factory CartItem.fromJson(Json json) => CartItem(
        id: toInt(json['id']),
        variantId: toInt(json['variantId']),
        productId: toInt(json['productId']),
        productName: '${json['productName']}',
        sku: '${json['sku']}',
        size: '${json['size']}',
        color: '${json['color']}',
        imageUrl: json['imageUrl'] as String?,
        unitPrice: toDouble(json['unitPrice']),
        quantity: toInt(json['quantity']),
        lineTotal: toDouble(json['lineTotal']),
        availableStock: toInt(json['availableStock']),
        isAvailable: json['isAvailable'] == true,
      );
}

class Cart {
  const Cart({required this.items, required this.totalQuantity, required this.estimatedSubtotal});

  static const empty = Cart(items: [], totalQuantity: 0, estimatedSubtotal: 0);

  final List<CartItem> items;
  final int totalQuantity;
  final double estimatedSubtotal;

  bool get hasUnavailable => items.any((i) => !i.isAvailable);

  factory Cart.fromJson(Json json) => Cart(
        items: toList(json['items'], CartItem.fromJson),
        totalQuantity: toInt(json['totalQuantity']),
        estimatedSubtotal: toDouble(json['estimatedSubtotal']),
      );
}

enum ShippingMethod { standard, express }

enum PaymentMethod { cod, bankTransfer }

extension ShippingMethodX on ShippingMethod {
  String get apiName => this == ShippingMethod.standard ? 'Standard' : 'Express';
}

extension PaymentMethodX on PaymentMethod {
  String get apiName => this == PaymentMethod.cod ? 'COD' : 'BankTransfer';
  String get label => this == PaymentMethod.cod ? 'Cash on delivery' : 'Bank transfer';
}

ShippingMethod parseShipping(Object? v) => enumByName(ShippingMethod.values, v, ShippingMethod.standard);

PaymentMethod parsePaymentMethod(Object? v) => enumByName(PaymentMethod.values, v, PaymentMethod.cod);

class ShippingOption {
  const ShippingOption(this.method, this.fee, this.description);

  final ShippingMethod method;
  final double fee;
  final String description;

  factory ShippingOption.fromJson(Json json) =>
      ShippingOption(parseShipping(json['method']), toDouble(json['fee']), '${json['description']}');
}

/// Totals calculated by the server; the app never computes them itself (BR-033).
class CheckoutPreview {
  const CheckoutPreview({
    required this.items,
    this.address,
    required this.shippingMethod,
    required this.shippingOptions,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.canPlaceOrder,
    required this.problems,
  });

  final List<CartItem> items;
  final Address? address;
  final ShippingMethod shippingMethod;
  final List<ShippingOption> shippingOptions;
  final double subtotal;
  final double shippingFee;
  final double total;
  final bool canPlaceOrder;
  final List<String> problems;

  factory CheckoutPreview.fromJson(Json json) => CheckoutPreview(
        items: toList(json['items'], CartItem.fromJson),
        address: json['address'] == null ? null : Address.fromJson(json['address'] as Json),
        shippingMethod: parseShipping(json['shippingMethod']),
        shippingOptions: toList(json['shippingOptions'], ShippingOption.fromJson),
        subtotal: toDouble(json['subtotal']),
        shippingFee: toDouble(json['shippingFee']),
        total: toDouble(json['total']),
        canPlaceOrder: json['canPlaceOrder'] == true,
        problems: (json['problems'] as List? ?? []).map((e) => '$e').toList(),
      );
}

class WishlistItem {
  const WishlistItem({required this.productId, required this.name, required this.price, this.imageUrl, required this.inStock, required this.isActive});

  final int productId;
  final String name;
  final double price;
  final String? imageUrl;
  final bool inStock;
  final bool isActive;

  factory WishlistItem.fromJson(Json json) => WishlistItem(
        productId: toInt(json['productId']),
        name: '${json['name']}',
        price: toDouble(json['price']),
        imageUrl: json['imageUrl'] as String?,
        inStock: json['inStock'] == true,
        isActive: json['isActive'] == true,
      );
}
