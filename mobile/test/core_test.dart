import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_mate/core/errors/app_exception.dart';
import 'package:sport_mate/core/utils/formatters.dart';
import 'package:sport_mate/core/utils/validators.dart';
import 'package:sport_mate/models/catalog.dart';
import 'package:sport_mate/models/order.dart';
import 'package:sport_mate/models/shopping.dart';

DioException _response(int status, Object data) {
  final options = RequestOptions(path: '/x');
  return DioException(requestOptions: options, response: Response(requestOptions: options, statusCode: status, data: data));
}

void main() {
  group('AppException', () {
    test('uses Problem Details detail as the message', () {
      final e = AppException.fromDio(_response(409, {'title': 'Conflict', 'status': 409, 'detail': 'Only 2 left in stock.'}));
      expect(e.message, 'Only 2 left in stock.');
      expect(e.statusCode, 409);
    });

    test('maps validation errors to camelCase fields', () {
      final e = AppException.fromDio(_response(400, {
        'title': 'One or more validation errors occurred.',
        'errors': {'Password': ['Password is too weak.']},
      }));
      expect(e.fieldError('password'), 'Password is too weak.');
      expect(e.message, 'Password is too weak.');
    });

    test('network failures get a friendly message', () {
      final e = AppException.fromDio(DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError));
      expect(e.isNetwork, isTrue);
      expect(e.message, contains('Cannot reach the server'));
    });
  });

  test('formatVnd uses Vietnamese grouping', () {
    expect(formatVnd(3519000), '3.519.000 ₫');
  });

  test('resolveImageUrl prefixes server-relative uploads only', () {
    expect(resolveImageUrl('https://cdn.example.com/a.jpg'), 'https://cdn.example.com/a.jpg');
    expect(resolveImageUrl('/uploads/products/a.jpg'), endsWith('/uploads/products/a.jpg'));
    expect(resolveImageUrl('/uploads/products/a.jpg'), startsWith('http'));
    expect(resolveImageUrl(null), isNull);
  });

  test('validators', () {
    expect(Validators.password('abc12345'), isNull);
    expect(Validators.password('abcdefgh'), isNotNull);
    expect(Validators.email('a@b.vn'), isNull);
    expect(Validators.email('nope'), isNotNull);
    expect(parseMoney('1.250.000'), 1250000);
  });

  test('ProductFilter builds the allow-listed sort query and clears filters', () {
    const filter = ProductFilter(keyword: 'nike', categoryId: 2, size: '42', sort: ProductSort.priceLow);
    final query = filter.toQuery();
    expect(query['sortBy'], 'price');
    expect(query['sortOrder'], 'asc');
    expect(query['categoryId'], 2);
    expect(filter.activeFilterCount, 2);
    expect(filter.clearFilters().activeFilterCount, 0);
    expect(filter.clearFilters().keyword, 'nike');
  });

  test('enums parse API names', () {
    expect(parseOrderStatus('Shipping'), OrderStatus.shipping);
    expect(parsePaymentMethod('BankTransfer'), PaymentMethod.bankTransfer);
    expect(parsePaymentMethod('COD'), PaymentMethod.cod);
    expect(PaymentMethod.bankTransfer.apiName, 'BankTransfer');
  });

  test('OrderDetail parses nested payment and address', () {
    final order = OrderDetail.fromJson({
      'id': 1,
      'orderCode': 'SM1',
      'customerId': 3,
      'customerName': 'A',
      'status': 'Pending',
      'shippingMethod': 'Express',
      'subtotal': 100,
      'discountAmount': 10,
      'shippingFee': 50,
      'totalAmount': 140,
      'deliveryAddress': {'recipientName': 'A', 'phoneNumber': '1', 'addressLine': 'L', 'ward': 'W', 'district': 'D', 'city': 'C'},
      'items': [],
      'payment': {'id': 9, 'orderId': 1, 'method': 'BankTransfer', 'status': 'Pending', 'amount': 140},
      'statusHistory': [],
      'canCancel': true,
      'allowedNextStatuses': ['Confirmed', 'Cancelled'],
      'createdAt': '2026-10-11T03:00:00Z',
    });
    expect(order.deliveryAddress, 'L, W, D, C');
    expect(order.payment!.method, PaymentMethod.bankTransfer);
    expect(order.allowedNextStatuses, [OrderStatus.confirmed, OrderStatus.cancelled]);
    expect(order.shippingMethod, ShippingMethod.express);
  });
}
