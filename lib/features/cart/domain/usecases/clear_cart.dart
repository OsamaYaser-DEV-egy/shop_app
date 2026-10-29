import '../repositories/cart_repository.dart';

class ClearCart {
  const ClearCart(this._repository);

  final CartRepository _repository;

  Future<void> call(String uid) => _repository.clear(uid);
}
