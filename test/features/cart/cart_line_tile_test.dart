import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/features/cart/domain/entities/cart_item.dart';
import 'package:shop_app/features/cart/domain/entities/cart_summary.dart';
import 'package:shop_app/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';

Product _product({int stock = 10, bool isAvailable = true}) => Product(
      id: 'p1',
      name: 'Headphones',
      description: '',
      price: 20,
      imageUrl: '',
      category: 'Audio',
      stock: stock,
      isAvailable: isAvailable,
    );

void main() {
  late List<int> quantities;
  late int removed;

  Future<void> pumpLine(WidgetTester tester, CartLine line) {
    quantities = [];
    removed = 0;
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CartLineTile(
          line: line,
          onQuantityChanged: quantities.add,
          onRemove: () => removed++,
        ),
      ),
    ));
  }

  testWidgets('an available item shows price, total and a working stepper',
      (tester) async {
    await pumpLine(
      tester,
      CartLine(
        item: const CartItem(productId: 'p1', quantity: 2),
        product: _product(),
      ),
    );
    expect(find.text('Headphones'), findsOneWidget);
    expect(find.text('\$20.00 each'), findsOneWidget);
    expect(find.text('\$40.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.tap(find.byTooltip('Remove'));
    expect(quantities, [3, 1]);
    expect(removed, 1);
  });

  testWidgets('more than the stock shows a warning and blocks increasing',
      (tester) async {
    await pumpLine(
      tester,
      CartLine(
        item: const CartItem(productId: 'p1', quantity: 5),
        product: _product(stock: 2),
      ),
    );
    expect(find.text('Only 2 left. Lower the quantity.'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    expect(quantities, isEmpty);
    // Decreasing jumps straight to what is in stock.
    await tester.tap(find.byTooltip('Decrease quantity'));
    expect(quantities, [2]);
  });

  testWidgets('a deleted product can only be removed', (tester) async {
    await pumpLine(
      tester,
      const CartLine(item: CartItem(productId: 'gone', quantity: 1)),
    );
    expect(find.text('Unavailable product'), findsOneWidget);
    expect(find.text('This product is no longer available.'), findsOneWidget);
    expect(find.byTooltip('Increase quantity'), findsNothing);
    await tester.tap(find.byTooltip('Remove'));
    expect(removed, 1);
  });

  testWidgets('an out-of-stock product asks to be removed', (tester) async {
    await pumpLine(
      tester,
      CartLine(
        item: const CartItem(productId: 'p1', quantity: 1),
        product: _product(isAvailable: false),
      ),
    );
    expect(find.text('Out of stock. Remove it to continue.'), findsOneWidget);
    expect(find.byTooltip('Increase quantity'), findsNothing);
  });
}
