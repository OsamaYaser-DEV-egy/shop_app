import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/cart/domain/entities/cart_item.dart';
import 'package:shop_app/features/cart/domain/usecases/clear_cart.dart';
import 'package:shop_app/features/cart/domain/usecases/remove_from_cart.dart';
import 'package:shop_app/features/cart/domain/usecases/set_cart_quantity.dart';
import 'package:shop_app/features/cart/domain/usecases/watch_cart.dart';
import 'package:shop_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:shop_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';

class _MockWatchCart extends Mock implements WatchCart {}

class _MockSetCartQuantity extends Mock implements SetCartQuantity {}

class _MockRemoveFromCart extends Mock implements RemoveFromCart {}

class _MockClearCart extends Mock implements ClearCart {}

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
  late StreamController<List<CartItem>> controller;
  late _MockWatchCart watchCart;
  late _MockSetCartQuantity setCartQuantity;
  late _MockRemoveFromCart removeFromCart;
  late _MockClearCart clearCart;

  CartCubit buildCubit() => CartCubit(
        watchCart: watchCart,
        setCartQuantity: setCartQuantity,
        removeFromCart: removeFromCart,
        clearCart: clearCart,
      );

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUpAll(() => registerFallbackValue(_product));

  setUp(() {
    controller = StreamController<List<CartItem>>.broadcast();
    watchCart = _MockWatchCart();
    setCartQuantity = _MockSetCartQuantity();
    removeFromCart = _MockRemoveFromCart();
    clearCart = _MockClearCart();
    when(() => watchCart('u1')).thenAnswer((_) => controller.stream);
    when(() => setCartQuantity(
          uid: any(named: 'uid'),
          product: any(named: 'product'),
          quantity: any(named: 'quantity'),
        )).thenAnswer((_) async {});
    when(() => removeFromCart(
          uid: any(named: 'uid'),
          productId: any(named: 'productId'),
        )).thenAnswer((_) async {});
    when(() => clearCart(any())).thenAnswer((_) async {});
  });

  tearDown(() => controller.close());

  test('starts signed out, then loads the bound user cart', () async {
    final cubit = buildCubit();
    expect(cubit.state.status, CartStatus.signedOut);

    cubit.bindUser('u1');
    expect(cubit.state.status, CartStatus.loading);
    controller.add(const [
      CartItem(productId: 'p1', quantity: 2),
      CartItem(productId: 'p2', quantity: 3),
    ]);
    await pump();
    expect(cubit.state.status, CartStatus.success);
    expect(cubit.state.itemCount, 5);
    expect(cubit.state.quantityOf('p1'), 2);
    expect(cubit.state.quantityOf('missing'), 0);
    await cubit.close();
  });

  test('binding the same user twice keeps one subscription', () async {
    final cubit = buildCubit();
    cubit.bindUser('u1');
    cubit.bindUser('u1');
    verify(() => watchCart('u1')).called(1);
    await cubit.close();
  });

  test('add increments the current quantity', () async {
    final cubit = buildCubit()..bindUser('u1');
    controller.add(const [CartItem(productId: 'p1', quantity: 2)]);
    await pump();

    expect(await cubit.add(_product), isNull);
    verify(() => setCartQuantity(uid: 'u1', product: _product, quantity: 3))
        .called(1);
    await cubit.close();
  });

  test('a quantity below 1 removes the product', () async {
    final cubit = buildCubit()..bindUser('u1');
    await cubit.setQuantity(_product, 0);
    verify(() => removeFromCart(uid: 'u1', productId: 'p1')).called(1);
    verifyNever(() => setCartQuantity(
          uid: any(named: 'uid'),
          product: any(named: 'product'),
          quantity: any(named: 'quantity'),
        ));
    await cubit.close();
  });

  test('returns the failure from the use case', () async {
    when(() => setCartQuantity(
          uid: any(named: 'uid'),
          product: any(named: 'product'),
          quantity: any(named: 'quantity'),
        )).thenThrow(const Failure('Only 5 left in stock.'));
    final cubit = buildCubit()..bindUser('u1');
    final failure = await cubit.setQuantity(_product, 6);
    expect(failure?.message, 'Only 5 left in stock.');
    await cubit.close();
  });

  test('actions fail when nobody is signed in', () async {
    final cubit = buildCubit();
    final failure = await cubit.add(_product);
    expect(failure?.code, 'unauthenticated');
    await cubit.close();
  });

  test('stream errors are reported and retry resubscribes', () async {
    final cubit = buildCubit()..bindUser('u1');
    controller.addError(const Failure('Boom'));
    await pump();
    expect(cubit.state.status, CartStatus.failure);
    expect(cubit.state.message, 'Boom');

    cubit.retry();
    controller.add(const []);
    await pump();
    expect(cubit.state.status, CartStatus.success);
    await cubit.close();
  });

  test('unbinding clears the cart', () async {
    final cubit = buildCubit()..bindUser('u1');
    controller.add(const [CartItem(productId: 'p1', quantity: 1)]);
    await pump();

    cubit.bindUser(null);
    expect(cubit.state, const CartState());
    controller.add(const [CartItem(productId: 'p1', quantity: 4)]);
    await pump();
    expect(cubit.state.itemCount, 0);
    await cubit.close();
  });
}
