import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchMyOrders {
  const WatchMyOrders(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call(String uid) => _repository.watchMyOrders(uid);
}
