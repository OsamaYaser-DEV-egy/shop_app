import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/set_favorite.dart';
import '../../domain/usecases/watch_favorites.dart';
import 'favorites_state.dart';

/// The signed-in customer's saved products. Lives as long as the app and
/// follows the session through [bindUser].
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required WatchFavorites watchFavorites,
    required SetFavorite setFavorite,
  })  : _watchFavorites = watchFavorites,
        _setFavorite = setFavorite,
        super(const FavoritesState());

  final WatchFavorites _watchFavorites;
  final SetFavorite _setFavorite;

  StreamSubscription<Set<String>>? _subscription;
  String? _uid;

  /// Starts watching the favorites of [uid], or clears them when null.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    if (uid == null) {
      emit(const FavoritesState());
      return;
    }
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    emit(const FavoritesState(status: FavoritesStatus.loading));
    _subscription = _watchFavorites(uid).listen(
      (ids) => emit(FavoritesState(status: FavoritesStatus.success, ids: ids)),
      onError: (Object error) {
        // Errors that arrive while signing out are expected and ignored.
        if (_uid == null) return;
        emit(FavoritesState(
          status: FavoritesStatus.failure,
          ids: state.ids,
          message: error is Failure
              ? error.message
              : 'Could not load your favorites. Please try again.',
        ));
      },
    );
  }

  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _subscription?.cancel();
    _subscribe(uid);
  }

  /// Saves the product if it is not saved yet, otherwise unsaves it.
  /// Returns a [Failure] or null on success.
  Future<Failure?> toggle(String productId) async {
    final uid = _uid;
    if (uid == null) {
      return const Failure('Please sign in to continue.', code: 'unauthenticated');
    }
    try {
      await _setFavorite(
        uid: uid,
        productId: productId,
        favorite: !state.isFavorite(productId),
      );
      return null;
    } on Failure catch (f) {
      return f;
    } catch (_) {
      return const Failure('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
