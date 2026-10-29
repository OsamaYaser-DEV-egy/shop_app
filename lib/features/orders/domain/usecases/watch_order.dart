import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchOrder {
  const WatchOrder(this._repository);

  final OrderRepository _repository;

  Stream<Order?> call(String id) => _repository.watchOrder(id);
}
