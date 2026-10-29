import '../entities/product.dart';
import '../entities/product_draft.dart';

abstract interface class ProductRepository {
  /// Live list of all products, sorted by name. Malformed documents are
  /// skipped. Emits a `Failure` error if the list cannot be read.
  Stream<List<Product>> watchProducts();

  /// Live product, or null if it does not exist (or was deleted).
  Stream<Product?> watchProduct(String id);

  /// Admin only (enforced by Firestore rules).
  Future<void> createProduct(ProductDraft draft);

  /// Admin only (enforced by Firestore rules).
  Future<void> updateProduct(String id, ProductDraft draft);

  /// Admin only (enforced by Firestore rules).
  Future<void> deleteProduct(String id);
}
