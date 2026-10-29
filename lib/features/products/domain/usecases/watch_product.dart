import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchProduct {
  const WatchProduct(this._repository);

  final ProductRepository _repository;

  Stream<Product?> call(String id) => _repository.watchProduct(id);
}
