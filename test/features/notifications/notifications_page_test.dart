import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/features/notifications/domain/entities/app_notification.dart';
import 'package:shop_app/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:shop_app/features/notifications/domain/usecases/watch_notifications.dart';
import 'package:shop_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shop_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:shop_app/features/orders/domain/entities/order_status.dart';

class _MockWatchNotifications extends Mock implements WatchNotifications {}

class _MockMarkNotificationsRead extends Mock implements MarkNotificationsRead {}

void main() {
  late StreamController<List<AppNotification>> controller;
  late _MockMarkNotificationsRead markRead;

  /// Built inside each test so the stream runs in the test's fake time.
  Future<NotificationsCubit> pumpPage(WidgetTester tester) async {
    controller = StreamController<List<AppNotification>>.broadcast();
    final watch = _MockWatchNotifications();
    markRead = _MockMarkNotificationsRead();
    when(() => watch('u1')).thenAnswer((_) => controller.stream);
    when(() => markRead(any())).thenAnswer((_) async {});
    final cubit = NotificationsCubit(
      watchNotifications: watch,
      markNotificationsRead: markRead,
    )..bindUser('u1');
    addTearDown(() async {
      await cubit.close();
      await controller.close();
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    return cubit;
  }

  testWidgets('shows loading, then an empty state', (tester) async {
    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.add(const []);
    await tester.pump();
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('lists notifications and marks all unread as read',
      (tester) async {
    await pumpPage(tester);
    controller.add([
      AppNotification(
        id: 'n1',
        title: 'Order shipped',
        body: 'Order #AB has shipped.',
        isRead: false,
        orderStatus: OrderStatus.shipped,
        createdAt: DateTime(2026, 5, 1, 9, 30),
      ),
      const AppNotification(
        id: 'n2',
        title: 'Order confirmed',
        body: 'Your order #AB has been confirmed.',
        isRead: true,
      ),
    ]);
    await tester.pump();

    expect(find.text('Order shipped'), findsOneWidget);
    expect(find.text('Order confirmed'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    verify(() => markRead(['n1'])).called(1);
  });

  testWidgets('shows an error with retry', (tester) async {
    await pumpPage(tester);
    controller.addError(Exception('offline'));
    await tester.pump();
    expect(
      find.text('Could not load your notifications. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
