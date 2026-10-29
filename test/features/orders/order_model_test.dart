import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shop_app/features/orders/data/models/order_model.dart';
import 'package:shop_app/features/orders/domain/entities/order.dart';
import 'package:shop_app/features/orders/domain/entities/order_status.dart';

Map<String, dynamic> _doc({Object? status = 'confirmed', Object? createdAt}) => {
      'userId': 'u1',
      'customerName': 'Sam',
      'customerEmail': 'sam@example.com',
      'items': {
        'p2': {'name': 'zebra mug', 'price': 4, 'quantity': 2},
        'p1': {'name': 'Amp', 'price': 19.5, 'quantity': 1},
      },
      'totalPrice': 27.5,
      'shippingAddress': '12 Main Street',
      'phone': '0100000000',
      'paymentMethod': 'cash_on_delivery',
      'status': status,
      'createdAt': createdAt,
    };

void main() {
  group('OrderModel.tryFromMap', () {
    test('parses a complete order and sorts items by name', () {
      final order = OrderModel.tryFromMap(
        'abcdefghijk',
        _doc(createdAt: Timestamp.fromDate(DateTime(2026, 1, 2))),
      )!;
      expect(order.items.map((i) => i.productId), ['p1', 'p2']);
      expect(order.items.last.price, 4.0);
      expect(order.itemCount, 3);
      expect(order.totalPrice, 27.5);
      expect(order.status, OrderStatus.confirmed);
      expect(order.createdAt, DateTime(2026, 1, 2));
      expect(order.reference, '#ABCDEFGH');
    });

    test('pending server time and unknown status are tolerated', () {
      final order = OrderModel.tryFromMap('o1', _doc(status: 'weird'))!;
      expect(order.createdAt, isNull);
      expect(order.status, OrderStatus.pending);
      expect(order.reference, '#O1');
    });

    test('skips orders without a user, total or valid items', () {
      expect(OrderModel.tryFromMap('o', {..._doc(), 'userId': ''}), isNull);
      expect(OrderModel.tryFromMap('o', {..._doc(), 'totalPrice': 'x'}), isNull);
      expect(
        OrderModel.tryFromMap('o', {
          ..._doc(),
          'items': {
            'p1': {'name': 'Amp'},
          },
        }),
        isNull,
      );
    });
  });

  test('itemMap copies only the fields the rules allow', () {
    final map = OrderModel.itemMap(
      {'name': ' Amp ', 'price': 20, 'imageUrl': 'https://x/a.png', 'stock': 3},
      2,
    );
    expect(map, {'name': ' Amp ', 'price': 20, 'quantity': 2});
  });

  test('roundMoney rounds to cents', () {
    expect(OrderModel.roundMoney(0.1 + 0.2), 0.3);
    expect(OrderModel.roundMoney(19.999), 20.0);
  });

  test('orders sort newest first, pending timestamps on top', () {
    Order order(String id, DateTime? at) => OrderModel.tryFromMap(
          id,
          _doc(createdAt: at == null ? null : Timestamp.fromDate(at)),
        )!;
    final orders = [
      order('old', DateTime(2026, 1, 1)),
      order('new', DateTime(2026, 3, 1)),
      order('pending', null),
    ]..sort(OrderRemoteDataSource.newestFirst);
    expect(orders.map((o) => o.id), ['pending', 'new', 'old']);
  });
}
