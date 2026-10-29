import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_draft.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.products);

  /// Sorting is done locally (case-insensitive), so no composite index is
  /// needed for the catalog.
  Stream<List<Product>> watchProducts() {
    return _collection.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.tryFromMap(doc.id, doc.data()))
          .whereType<Product>()
          .toList();
      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return products;
    });
  }

  Stream<Product?> watchProduct(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ProductModel.tryFromMap(snapshot.id, data);
    });
  }

  Future<void> create(ProductDraft draft) {
    return _collection.add(ProductModel.createMap(draft));
  }

  Future<void> update(String id, ProductDraft draft) {
    return _collection.doc(id).update(ProductModel.updateMap(draft));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();
}
