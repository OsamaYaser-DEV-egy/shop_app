import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/features/products/data/models/product_model.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';

void main() {
  group('ProductModel.tryFromMap', () {
    test('parses a complete document', () {
      final product = ProductModel.tryFromMap('p1', {
        'name': 'Headphones',
        'description': 'Wireless',
        'price': 99.5,
        'imageUrl': 'https://example.com/a.png',
        'category': 'Audio',
        'stock': 12,
        'isAvailable': true,
        'isFeatured': true,
      });
      expect(product, isNotNull);
      expect(product!.id, 'p1');
      expect(product.price, 99.5);
      expect(product.stock, 12);
      expect(product.isFeatured, isTrue);
      expect(product.stockLevel, StockLevel.available);
    });

    test('accepts integer prices written by the console', () {
      final product = ProductModel.tryFromMap('p1', {
        'name': 'Cable',
        'price': 10,
        'stock': 3,
        'isAvailable': true,
      });
      expect(product!.price, 10.0);
      expect(product.stockLevel, StockLevel.low);
    });

    test('skips documents without a name or a valid price', () {
      expect(ProductModel.tryFromMap('a', {'price': 5}), isNull);
      expect(ProductModel.tryFromMap('b', {'name': 'X'}), isNull);
      expect(ProductModel.tryFromMap('c', {'name': 'X', 'price': 'free'}), isNull);
      expect(ProductModel.tryFromMap('d', {'name': 'X', 'price': -1}), isNull);
    });

    test('fills safe defaults for missing optional fields', () {
      final product = ProductModel.tryFromMap('p1', {
        'name': 'Plain',
        'price': 1,
      })!;
      expect(product.description, '');
      expect(product.imageUrl, '');
      expect(product.category, 'Other');
      expect(product.stock, 0);
      expect(product.isAvailable, isFalse);
      expect(product.isFeatured, isFalse);
      expect(product.canBePurchased, isFalse);
    });

    test('never reports negative stock', () {
      final product = ProductModel.tryFromMap('p1', {
        'name': 'X',
        'price': 1,
        'stock': -4,
        'isAvailable': true,
      })!;
      expect(product.stock, 0);
      expect(product.stockLevel, StockLevel.outOfStock);
    });

    test('unavailable products are out of stock even with units left', () {
      final product = ProductModel.tryFromMap('p1', {
        'name': 'X',
        'price': 1,
        'stock': 50,
        'isAvailable': false,
      })!;
      expect(product.canBePurchased, isFalse);
      expect(product.stockLevel, StockLevel.outOfStock);
    });
  });
}
