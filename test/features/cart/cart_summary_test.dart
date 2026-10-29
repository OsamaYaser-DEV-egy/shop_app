import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/features/cart/domain/entities/cart_item.dart';
import 'package:shop_app/features/cart/domain/entities/cart_summary.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';

Product _product(
  String id,
  String name, {
  double price = 10,
  int stock = 10,
  bool isAvailable = true,
}) =>
    Product(
      id: id,
      name: name,
      description: '',
      price: price,
      imageUrl: '',
      category: 'Audio',
      stock: stock,
      isAvailable: isAvailable,
    );

CartItem _item(String id, int quantity) =>
    CartItem(productId: id, quantity: quantity);

void main() {
  group('CartSummary.build', () {
    test('joins items with products and totals them', () {
      final summary = CartSummary.build(
        [_item('a', 2), _item('b', 1)],
        [_product('a', 'Cable', price: 5), _product('b', 'Amp', price: 40)],
      );
      expect(summary.lines.map((l) => l.product?.name), ['Amp', 'Cable']);
      expect(summary.subtotal, 50);
      expect(summary.orderableCount, 3);
      expect(summary.hasIssues, isFalse);
    });

    test('puts deleted products last and leaves them out of the totals', () {
      final summary = CartSummary.build(
        [_item('gone', 3), _item('a', 1)],
        [_product('a', 'Cable', price: 5)],
      );
      expect(summary.lines.last.product, isNull);
      expect(summary.lines.last.canBeOrdered, isFalse);
      expect(summary.subtotal, 5);
      expect(summary.orderableCount, 1);
      expect(summary.hasIssues, isTrue);
    });

    test('flags unavailable and over-stock lines', () {
      final summary = CartSummary.build(
        [_item('off', 1), _item('low', 4), _item('ok', 2)],
        [
          _product('off', 'A', isAvailable: false),
          _product('low', 'B', stock: 2),
          _product('ok', 'C', price: 3),
        ],
      );
      final byId = {for (final l in summary.lines) l.item.productId: l};
      expect(byId['off']!.isAvailable, isFalse);
      expect(byId['low']!.exceedsStock, isTrue);
      expect(byId['low']!.maxQuantity, 2);
      expect(byId['ok']!.canBeOrdered, isTrue);
      expect(summary.subtotal, 6);
      expect(summary.hasIssues, isTrue);
    });

    test('caps the selectable quantity at the cart limit', () {
      final summary = CartSummary.build(
        [_item('a', 1)],
        [_product('a', 'Cable', stock: 500)],
      );
      expect(summary.lines.single.maxQuantity, CartItem.maxQuantity);
    });

    test('an empty cart has no lines and a zero subtotal', () {
      final summary = CartSummary.build(const [], [_product('a', 'Cable')]);
      expect(summary.isEmpty, isTrue);
      expect(summary.subtotal, 0);
    });
  });
}
