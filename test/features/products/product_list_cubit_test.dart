import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/products/domain/entities/product.dart';
import 'package:shop_app/features/products/domain/usecases/watch_products.dart';
import 'package:shop_app/features/products/presentation/cubit/product_list_cubit.dart';
import 'package:shop_app/features/products/presentation/cubit/product_list_state.dart';

class _MockWatchProducts extends Mock implements WatchProducts {}

Product _product(
  String id,
  String name,
  String category, {
  int stock = 10,
  bool isAvailable = true,
  bool isFeatured = false,
}) =>
    Product(
      id: id,
      name: name,
      description: '',
      price: 10,
      imageUrl: '',
      category: category,
      stock: stock,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
    );

void main() {
  late StreamController<List<Product>> controller;
  late _MockWatchProducts watchProducts;

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    controller = StreamController<List<Product>>.broadcast();
    watchProducts = _MockWatchProducts();
    when(() => watchProducts()).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  final products = [
    _product('1', 'Blue Headphones', 'Audio', isFeatured: true),
    _product('2', 'Red Speaker', 'Audio'),
    _product('3', 'USB Cable', 'Accessories', isFeatured: true, stock: 0),
    _product('4', 'Desk Lamp', 'Home', isFeatured: true, isAvailable: false),
  ];

  test('starts loading, then shows products', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    expect(cubit.state.status, ProductListStatus.loading);
    controller.add(products);
    await pump();
    expect(cubit.state.status, ProductListStatus.success);
    expect(cubit.state.products, products);
    await cubit.close();
  });

  test('reports a failure and can retry', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.addError(const Failure('Boom'));
    await pump();
    expect(cubit.state.status, ProductListStatus.failure);
    expect(cubit.state.message, 'Boom');

    cubit.retry();
    expect(cubit.state.status, ProductListStatus.loading);
    controller.add(products);
    await pump();
    expect(cubit.state.status, ProductListStatus.success);
    await cubit.close();
  });

  test('derives sorted distinct categories', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    expect(cubit.state.categories, ['Accessories', 'Audio', 'Home']);
    await cubit.close();
  });

  test('search is case-insensitive and matches the name', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    cubit.setQuery('  HEAD ');
    expect(cubit.state.visible.map((p) => p.id), ['1']);
    cubit.setQuery('zzz');
    expect(cubit.state.visible, isEmpty);
    await cubit.close();
  });

  test('category filter narrows the list and combines with search', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    cubit.selectCategory('Audio');
    expect(cubit.state.visible.map((p) => p.id), ['1', '2']);
    cubit.setQuery('speaker');
    expect(cubit.state.visible.map((p) => p.id), ['2']);
    cubit.selectCategory(null);
    expect(cubit.state.category, isNull);
    expect(cubit.state.visible.map((p) => p.id), ['2']);
    await cubit.close();
  });

  test('clearFilters resets search and category', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    cubit.selectCategory('Home');
    cubit.setQuery('lamp');
    expect(cubit.state.isFiltering, isTrue);
    cubit.clearFilters();
    expect(cubit.state.isFiltering, isFalse);
    expect(cubit.state.visible.length, products.length);
    await cubit.close();
  });

  test('featured only includes purchasable featured products', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    expect(cubit.state.featured.map((p) => p.id), ['1']);
    await cubit.close();
  });

  test('live updates replace the list', () async {
    final cubit = ProductListCubit(watchProducts: watchProducts);
    controller.add(products);
    await pump();
    controller.add([products.first]);
    await pump();
    expect(cubit.state.products.length, 1);
    await cubit.close();
  });
}
