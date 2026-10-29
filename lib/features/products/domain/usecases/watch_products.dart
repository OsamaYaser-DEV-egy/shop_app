import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchProducts {
  const WatchProducts(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> call() => _repository.watchProducts();
}
