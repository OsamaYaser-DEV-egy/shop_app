abstract interface class FavoritesRepository {
  /// Live ids of the products [uid] has saved. Emits a `Failure` error if the
  /// list cannot be read.
  Stream<Set<String>> watchFavoriteIds(String uid);

  Future<void> add({required String uid, required String productId});

  Future<void> remove({required String uid, required String productId});
}
