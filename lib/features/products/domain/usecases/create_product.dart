import '../../../../core/errors/failures.dart';
import '../entities/product_draft.dart';
import '../repositories/product_repository.dart';

class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(ProductDraft draft) async {
    final error = draft.validationError;
    if (error != null) throw Failure(error, code: 'invalid-product');
    await _repository.createProduct(draft);
  }
}
