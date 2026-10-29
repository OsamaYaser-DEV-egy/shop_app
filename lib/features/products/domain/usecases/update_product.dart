import '../../../../core/errors/failures.dart';
import '../entities/product_draft.dart';
import '../repositories/product_repository.dart';

class UpdateProduct {
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id, ProductDraft draft) async {
    if (id.isEmpty) throw const Failure('Missing product id.');
    final error = draft.validationError;
    if (error != null) throw Failure(error, code: 'invalid-product');
    await _repository.updateProduct(id, draft);
  }
}
