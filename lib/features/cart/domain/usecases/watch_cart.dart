import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class WatchCart {
  const WatchCart(this._repository);

  final CartRepository _repository;

  Stream<List<CartItem>> call(String uid) => _repository.watchCart(uid);
}
