import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/features/orders/domain/entities/order.dart';
import 'package:shop_app/features/orders/domain/entities/order_item.dart';
import 'package:shop_app/features/orders/domain/entities/order_status.dart';
import 'package:shop_app/features/orders/presentation/widgets/order_details_view.dart';

const _order = Order(
  id: 'abcdefghijk',
  userId: 'u1',
  customerName: 'Sam Customer',
  customerEmail: 'sam@example.com',
  items: [
    OrderItem(productId: 'p1', name: 'Amp', price: 20, quantity: 2),
    OrderItem(productId: 'p2', name: 'Cable', price: 7.5, quantity: 1),
  ],
  totalPrice: 47.5,
  shippingAddress: '12 Main Street, Cairo',
  phone: '0100000000',
  status: OrderStatus.shipped,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('shows status, items at purchase time, total and delivery',
      (tester) async {
    await _pump(tester, const OrderDetailsView(order: _order));
    expect(find.text('Order #ABCDEFGH'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('2 × \$20.00'), findsOneWidget);
    expect(find.text('\$47.50'), findsOneWidget);
    expect(find.text('12 Main Street, Cairo'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
  });

  testWidgets('customer details are only shown in the admin view',
      (tester) async {
    await _pump(tester, const OrderDetailsView(order: _order));
    expect(find.text('Sam Customer'), findsNothing);

    await _pump(
      tester,
      const OrderDetailsView(order: _order, showCustomer: true),
    );
    expect(find.text('Sam Customer'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
  });

  testWidgets('renders the given actions', (tester) async {
    await _pump(
      tester,
      OrderDetailsView(
        order: _order,
        actions: [TextButton(onPressed: () {}, child: const Text('Act'))],
      ),
    );
    await tester.scrollUntilVisible(find.text('Act'), 200);
    expect(find.text('Act'), findsOneWidget);
  });
}
