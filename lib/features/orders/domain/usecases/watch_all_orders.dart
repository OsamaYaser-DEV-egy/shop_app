import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchAllOrders {
  const WatchAllOrders(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call() => _repository.watchAllOrders();
}
