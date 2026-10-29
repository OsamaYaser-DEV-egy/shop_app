import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:shop_app/features/favorites/domain/usecases/set_favorite.dart';
import 'package:shop_app/features/favorites/domain/usecases/watch_favorites.dart';
import 'package:shop_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:shop_app/features/favorites/presentation/cubit/favorites_state.dart';

class _MockWatchFavorites extends Mock implements WatchFavorites {}

class _MockSetFavorite extends Mock implements SetFavorite {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late StreamController<Set<String>> controller;
  late _MockWatchFavorites watchFavorites;
  late _MockSetFavorite setFavorite;

  FavoritesCubit buildCubit() =>
      FavoritesCubit(watchFavorites: watchFavorites, setFavorite: setFavorite);

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    controller = StreamController<Set<String>>.broadcast();
    watchFavorites = _MockWatchFavorites();
    setFavorite = _MockSetFavorite();
    when(() => watchFavorites('u1')).thenAnswer((_) => controller.stream);
    when(() => setFavorite(
          uid: any(named: 'uid'),
          productId: any(named: 'productId'),
          favorite: any(named: 'favorite'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => controller.close());

  test('loads the saved ids of the bound user', () async {
    final cubit = buildCubit()..bindUser('u1');
    expect(cubit.state.status, FavoritesStatus.loading);
    controller.add({'p1', 'p2'});
    await pump();
    expect(cubit.state.status, FavoritesStatus.success);
    expect(cubit.state.isFavorite('p1'), isTrue);
    expect(cubit.state.isFavorite('p3'), isFalse);
    await cubit.close();
  });

  test('toggle saves an unsaved product and unsaves a saved one', () async {
    final cubit = buildCubit()..bindUser('u1');
    controller.add({'p1'});
    await pump();

    expect(await cubit.toggle('p2'), isNull);
    verify(() => setFavorite(uid: 'u1', productId: 'p2', favorite: true))
        .called(1);

    expect(await cubit.toggle('p1'), isNull);
    verify(() => setFavorite(uid: 'u1', productId: 'p1', favorite: false))
        .called(1);
    await cubit.close();
  });

  test('toggle fails when nobody is signed in', () async {
    final cubit = buildCubit();
    expect((await cubit.toggle('p1'))?.code, 'unauthenticated');
    await cubit.close();
  });

  test('stream errors are reported and unbinding clears the ids', () async {
    final cubit = buildCubit()..bindUser('u1');
    controller.add({'p1'});
    await pump();
    controller.addError(const Failure('Boom'));
    await pump();
    expect(cubit.state.status, FavoritesStatus.failure);
    expect(cubit.state.ids, {'p1'});

    cubit.bindUser(null);
    expect(cubit.state, const FavoritesState());
    await cubit.close();
  });

  group('SetFavorite', () {
    late _MockFavoritesRepository repository;

    setUp(() {
      repository = _MockFavoritesRepository();
      when(() => repository.add(
            uid: any(named: 'uid'),
            productId: any(named: 'productId'),
          )).thenAnswer((_) async {});
      when(() => repository.remove(
            uid: any(named: 'uid'),
            productId: any(named: 'productId'),
          )).thenAnswer((_) async {});
    });

    test('adds or removes depending on the flag', () async {
      final useCase = SetFavorite(repository);
      await useCase(uid: 'u1', productId: 'p1', favorite: true);
      await useCase(uid: 'u1', productId: 'p1', favorite: false);
      verify(() => repository.add(uid: 'u1', productId: 'p1')).called(1);
      verify(() => repository.remove(uid: 'u1', productId: 'p1')).called(1);
    });

    test('rejects an empty id', () async {
      await expectLater(
        SetFavorite(repository)(uid: 'u1', productId: '', favorite: true),
        throwsA(isA<Failure>()),
      );
    });
  });
}
