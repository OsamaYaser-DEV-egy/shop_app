import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/cart/data/models/cart_item_model.dart';
import 'package:shop_app/features/cart/domain/entities/cart_item.dart';
import 'package:shop_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:shop_app/features/cart/domain/usecases/remove_from_cart.dart';
import 'package:shop_app/features/cart/domain/usecases/set_cart_quantity.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';

class _MockCartRepository extends Mock implements CartRepository {}

const _product = Product(
  id: 'p1',
  name: 'Headphones',
  description: '',
  price: 20,
  imageUrl: '',
  category: 'Audio',
  stock: 5,
  isAvailable: true,
);

void main() {
  late _MockCartRepository repository;

  setUp(() {
    repository = _MockCartRepository();
    when(() => repository.setQuantity(
          uid: any(named: 'uid'),
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
        )).thenAnswer((_) async {});
    when(() => repository.remove(
          uid: any(named: 'uid'),
          productId: any(named: 'productId'),
        )).thenAnswer((_) async {});
  });

  group('SetCartQuantity', () {
    test('saves a quantity within stock', () async {
      await SetCartQuantity(repository)(uid: 'u1', product: _product, quantity: 5);
      verify(() => repository.setQuantity(uid: 'u1', productId: 'p1', quantity: 5))
          .called(1);
    });

    test('rejects more than the stock', () async {
      await expectLater(
        SetCartQuantity(repository)(uid: 'u1', product: _product, quantity: 6),
        throwsA(isA<Failure>().having((f) => f.code, 'code', 'out-of-stock')),
      );
      verifyNever(() => repository.setQuantity(
            uid: any(named: 'uid'),
            productId: any(named: 'productId'),
            quantity: any(named: 'quantity'),
          ));
    });

    test('rejects products that cannot be bought', () async {
      const unavailable = Product(
        id: 'p2',
        name: 'Lamp',
        description: '',
        price: 20,
        imageUrl: '',
        category: 'Home',
        stock: 5,
        isAvailable: false,
      );
      await expectLater(
        SetCartQuantity(repository)(uid: 'u1', product: unavailable, quantity: 1),
        throwsA(isA<Failure>()),
      );
    });

    test('rejects zero and quantities above the cart limit', () async {
      const plenty = Product(
        id: 'p3',
        name: 'Cable',
        description: '',
        price: 2,
        imageUrl: '',
        category: 'Accessories',
        stock: 1000,
        isAvailable: true,
      );
      for (final quantity in [0, CartItem.maxQuantity + 1]) {
        await expectLater(
          SetCartQuantity(repository)(uid: 'u1', product: plenty, quantity: quantity),
          throwsA(
            isA<Failure>().having((f) => f.code, 'code', 'invalid-quantity'),
          ),
        );
      }
    });
  });

  group('RemoveFromCart', () {
    test('removes by product id', () async {
      await RemoveFromCart(repository)(uid: 'u1', productId: 'p1');
      verify(() => repository.remove(uid: 'u1', productId: 'p1')).called(1);
    });

    test('rejects an empty id', () async {
      await expectLater(
        RemoveFromCart(repository)(uid: 'u1', productId: ''),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('CartItemModel.tryFromMap', () {
    test('parses the quantity', () {
      expect(
        CartItemModel.tryFromMap('p1', {'quantity': 3}),
        const CartItem(productId: 'p1', quantity: 3),
      );
    });

    test('skips documents without a positive quantity', () {
      expect(CartItemModel.tryFromMap('p1', {}), isNull);
      expect(CartItemModel.tryFromMap('p1', {'quantity': 0}), isNull);
      expect(CartItemModel.tryFromMap('p1', {'quantity': 'two'}), isNull);
    });

    test('caps oversized quantities at the cart limit', () {
      expect(
        CartItemModel.tryFromMap('p1', {'quantity': 500})?.quantity,
        CartItem.maxQuantity,
      );
    });
  });
}
