import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/notifications/notification_tap.dart';
import 'package:shop_app/features/notifications/data/models/notification_model.dart';
import 'package:shop_app/features/notifications/domain/entities/app_notification.dart';
import 'package:shop_app/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:shop_app/features/notifications/domain/usecases/watch_notifications.dart';
import 'package:shop_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shop_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:shop_app/features/orders/domain/entities/order_status.dart';

class _MockWatchNotifications extends Mock implements WatchNotifications {}

class _MockMarkNotificationsRead extends Mock implements MarkNotificationsRead {}

final _boundAt = DateTime(2026, 5, 1, 12);

AppNotification _note(String id, {DateTime? at, bool isRead = false}) =>
    AppNotification(
      id: id,
      title: 'Order confirmed',
      body: 'Your order has been confirmed.',
      isRead: isRead,
      orderId: 'order$id',
      createdAt: at,
    );

void main() {
  group('orderStatusMessage and NotificationModel', () {
    test('only confirmed, shipped, delivered and cancelled notify', () {
      final notifying = OrderStatus.values
          .where((s) => orderStatusMessage(s, 'abc') != null)
          .toList();
      expect(notifying, OrderStatus.values.where((s) => s.notifiesCustomer));
      expect(notifying, [
        OrderStatus.confirmed,
        OrderStatus.shipped,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]);
      expect(
        orderStatusMessage(OrderStatus.shipped, 'abcdefghij')!.body,
        'Order #ABCDEFGH has shipped.',
      );
    });

    test('forOrderStatus writes exactly the fields the rules allow', () {
      final map = NotificationModel.forOrderStatus(
        userId: 'u1',
        orderId: 'o1',
        status: OrderStatus.delivered,
      )!;
      expect(map.keys.toSet(), {
        'userId',
        'orderId',
        'status',
        'title',
        'body',
        'isRead',
        'createdAt',
      });
      expect(map['status'], 'delivered');
      expect(map['isRead'], false);
      expect(
        NotificationModel.forOrderStatus(
          userId: 'u1',
          orderId: 'o1',
          status: OrderStatus.preparing,
        ),
        isNull,
      );
    });

    test('tryFromMap parses documents and skips ones without a title', () {
      final n = NotificationModel.tryFromMap('n1', {
        'title': 'Order shipped',
        'body': 'On its way',
        'orderId': 'o1',
        'status': 'shipped',
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      })!;
      expect(n.orderStatus, OrderStatus.shipped);
      expect(n.isRead, isTrue);
      expect(n.createdAt, DateTime(2026, 1, 1));
      expect(NotificationModel.tryFromMap('n2', {'body': 'x'}), isNull);
    });
  });

  group('NotificationsCubit', () {
    late StreamController<List<AppNotification>> controller;
    late _MockWatchNotifications watch;
    late _MockMarkNotificationsRead markRead;
    late List<String> shown;

    NotificationsCubit buildCubit() => NotificationsCubit(
          watchNotifications: watch,
          markNotificationsRead: markRead,
          onNewNotification: (n) => shown.add(n.id),
          clock: () => _boundAt,
        );

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 5));

    setUp(() {
      controller = StreamController<List<AppNotification>>.broadcast();
      watch = _MockWatchNotifications();
      markRead = _MockMarkNotificationsRead();
      shown = [];
      when(() => watch('u1')).thenAnswer((_) => controller.stream);
      when(() => markRead(any())).thenAnswer((_) async {});
    });

    tearDown(() => controller.close());

    test('shows only notifications that arrive while the app runs', () async {
      final cubit = buildCubit()..bindUser('u1');
      final old = _note('old', at: _boundAt.subtract(const Duration(days: 1)));
      controller.add([old]);
      await pump();
      expect(shown, isEmpty);
      expect(cubit.state.unreadCount, 1);

      final fresh = _note('new', at: _boundAt.add(const Duration(minutes: 5)));
      final readAlready =
          _note('read', at: _boundAt.add(const Duration(minutes: 6)), isRead: true);
      controller.add([readAlready, fresh, old]);
      await pump();
      expect(shown, ['new']);

      // The same notification is never shown twice.
      controller.add([fresh, old]);
      await pump();
      expect(shown, ['new']);
      await cubit.close();
    });

    test('marks one or all unread notifications as read', () async {
      final cubit = buildCubit()..bindUser('u1');
      controller.add([
        _note('a', at: _boundAt),
        _note('b', at: _boundAt, isRead: true),
        _note('c', at: _boundAt),
      ]);
      await pump();

      await cubit.markRead('b');
      verifyNever(() => markRead(any()));
      await cubit.markRead('a');
      verify(() => markRead(['a'])).called(1);
      await cubit.markAllRead();
      verify(() => markRead(['a', 'c'])).called(1);
      await cubit.close();
    });

    test('unbinding clears notifications', () async {
      final cubit = buildCubit()..bindUser('u1');
      controller.add([_note('a', at: _boundAt)]);
      await pump();
      cubit.bindUser(null);
      expect(cubit.state, const NotificationsState());
      await cubit.close();
    });
  });

  group('NotificationTap', () {
    test('encodes and decodes the payload', () {
      const tap = NotificationTap(notificationId: 'n1', orderId: 'o1');
      final decoded = NotificationTap.tryDecode(tap.encode())!;
      expect(decoded.notificationId, 'n1');
      expect(decoded.orderId, 'o1');
      expect(NotificationTap.tryDecode('not json'), isNull);
      expect(NotificationTap.tryDecode(null), isNull);
    });

    test('a tap waits until a customer is signed in', () {
      final opened = <String>[];
      final queue = NotificationTapQueue((t) => opened.add(t.notificationId));
      queue.add(const NotificationTap(notificationId: 'n1'));
      expect(opened, isEmpty);
      queue.setReady(true);
      expect(opened, ['n1']);
      queue.setReady(true);
      expect(opened, ['n1']);
    });
  });
}
