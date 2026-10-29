import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';

/// Favorites live in `users/{uid}/favorites`. The document id is the product
/// id; the document holds `productId` and `addedAt`.
class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.favorites);

  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _collection(uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> add(String uid, String productId) {
    return _collection(uid)
        .doc(productId)
        .set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> remove(String uid, String productId) =>
      _collection(uid).doc(productId).delete();
}
