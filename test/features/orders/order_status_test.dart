import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/orders/domain/entities/order.dart';
import 'package:shop_app/features/orders/domain/entities/order_item.dart';
import 'package:shop_app/features/orders/domain/entities/order_status.dart';
import 'package:shop_app/features/orders/domain/repositories/order_repository.dart';
import 'package:shop_app/features/orders/domain/usecases/cancel_order.dart';
import 'package:shop_app/features/orders/domain/usecases/update_order_status.dart';
import 'package:shop_app/features/orders/domain/usecases/watch_all_orders.dart';
import 'package:shop_app/features/orders/presentation/cubit/admin_orders_cubit.dart';
import 'package:shop_app/features/orders/presentation/cubit/admin_orders_state.dart';
import 'package:shop_app/features/orders/presentation/cubit/order_actions_cubit.dart';
import 'package:shop_app/features/orders/presentation/cubit/order_actions_state.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockWatchAllOrders extends Mock implements WatchAllOrders {}

Order _order(String id, OrderStatus status) => Order(
      id: id,
      userId: 'u1',
      customerName: 'Sam',
      customerEmail: 'sam@example.com',
      items: const [
        OrderItem(productId: 'p1', name: 'Amp', price: 20, quantity: 1),
      ],
      totalPrice: 20,
      shippingAddress: '12 Main Street',
      phone: '0100000000',
      status: status,
    );

void main() {
  setUpAll(() => registerFallbackValue(OrderStatus.pending));

  group('OrderStatus business rules', () {
    test('the store moves forward one step at a time', () {
      expect(OrderStatus.pending.next, OrderStatus.confirmed);
      expect(OrderStatus.confirmed.next, OrderStatus.preparing);
      expect(OrderStatus.preparing.next, OrderStatus.shipped);
      expect(OrderStatus.shipped.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
    });

    test('the store cancels until shipping, customers only while pending', () {
      final byStore =
          OrderStatus.values.where((s) => s.canBeCancelledByStore).toList();
      final byCustomer =
          OrderStatus.values.where((s) => s.canBeCancelledByCustomer).toList();
      expect(byStore, [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.preparing,
      ]);
      expect(byCustomer, [OrderStatus.pending]);
    });
  });

  group('use cases', () {
    late _MockOrderRepository repository;

    setUp(() {
      repository = _MockOrderRepository();
      when(() => repository.updateStatus(
            orderId: any(named: 'orderId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async {});
      when(() => repository.cancelOrder(
            orderId: any(named: 'orderId'),
            byStore: any(named: 'byStore'),
          )).thenAnswer((_) async {});
    });

    test('UpdateOrderStatus moves to the next status', () async {
      await UpdateOrderStatus(repository)(_order('o1', OrderStatus.confirmed));
      verify(() => repository.updateStatus(
            orderId: 'o1',
            from: OrderStatus.confirmed,
            to: OrderStatus.preparing,
          )).called(1);
    });

    test('UpdateOrderStatus refuses final orders', () async {
      await expectLater(
        UpdateOrderStatus(repository)(_order('o1', OrderStatus.delivered)),
        throwsA(isA<Failure>()),
      );
    });

    test('CancelOrder applies the right business rule', () async {
      final confirmed = _order('o1', OrderStatus.confirmed);
      await CancelOrder(repository)(confirmed, byStore: true);
      verify(() => repository.cancelOrder(orderId: 'o1', byStore: true))
          .called(1);

      await expectLater(
        CancelOrder(repository)(confirmed, byStore: false),
        throwsA(isA<Failure>()),
      );
      await expectLater(
        CancelOrder(repository)(_order('o2', OrderStatus.shipped), byStore: true),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('OrderActionsCubit', () {
    test('reports success and failure', () async {
      final repository = _MockOrderRepository();
      when(() => repository.updateStatus(
            orderId: any(named: 'orderId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async {});
      final cubit = OrderActionsCubit(
        updateOrderStatus: UpdateOrderStatus(repository),
        cancelOrder: CancelOrder(repository),
      );

      await cubit.advance(_order('o1', OrderStatus.pending));
      expect(cubit.state.status, OrderActionsStatus.success);
      expect(cubit.state.message, 'Order marked as confirmed.');

      await cubit.cancel(_order('o1', OrderStatus.shipped), byStore: false);
      expect(cubit.state.status, OrderActionsStatus.failure);
      await cubit.close();
    });
  });

  group('AdminOrdersCubit', () {
    test('counts and filters orders by status', () async {
      final controller = StreamController<List<Order>>.broadcast();
      final watchAll = _MockWatchAllOrders();
      when(() => watchAll()).thenAnswer((_) => controller.stream);
      final cubit = AdminOrdersCubit(watchAllOrders: watchAll);
      expect(cubit.state.status, AdminOrdersStatus.loading);

      controller.add([
        _order('a', OrderStatus.pending),
        _order('b', OrderStatus.pending),
        _order('c', OrderStatus.shipped),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state.countOf(OrderStatus.pending), 2);

      cubit.setFilter(OrderStatus.shipped);
      expect(cubit.state.visible.map((o) => o.id), ['c']);
      cubit.setFilter(null);
      expect(cubit.state.visible.length, 3);

      await cubit.close();
      await controller.close();
    });
  });
}
