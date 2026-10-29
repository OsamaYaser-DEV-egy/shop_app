import '../../../../core/errors/failures.dart';
import '../repositories/product_repository.dart';

class DeleteProduct {
  const DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id) async {
    if (id.isEmpty) throw const Failure('Missing product id.');
    await _repository.deleteProduct(id);
  }
}
