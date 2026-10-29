import '../entities/order.dart';
import '../entities/order_request.dart';

abstract interface class OrderRepository {
  /// In one transaction: checks stock and prices, reserves the stock,
  /// creates the order and empties the ordered cart items. Returns the new
  /// order id. Throws a `Failure` (e.g. `out-of-stock`, `price-changed`).
  Future<String> placeOrder(OrderRequest request);

  /// Live orders of [uid], newest first. Malformed documents are skipped.
  Stream<List<Order>> watchMyOrders(String uid);

  /// Live order, or null if it does not exist.
  Stream<Order?> watchOrder(String id);
}
