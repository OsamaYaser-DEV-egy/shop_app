import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

/// The cart lives in `users/{uid}/cart`, one document per product id.
class CartRemoteDataSource {
  const CartRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.cart);

  Stream<List<CartItem>> watchCart(String uid) {
    return _collection(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CartItemModel.tryFromMap(doc.id, doc.data()))
              .whereType<CartItem>()
              .toList(),
        );
  }

  Future<void> setQuantity(String uid, String productId, int quantity) {
    return _collection(uid)
        .doc(productId)
        .set(CartItemModel.toMap(productId, quantity), SetOptions(merge: true));
  }

  Future<void> remove(String uid, String productId) =>
      _collection(uid).doc(productId).delete();

  Future<void> clear(String uid) async {
    final snapshot = await _collection(uid).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
