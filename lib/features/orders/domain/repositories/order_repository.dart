import '../entities/order.dart';
import '../entities/order_request.dart';
import '../entities/order_status.dart';

abstract interface class OrderRepository {
  /// In one transaction: checks stock and prices, reserves the stock,
  /// creates the order and empties the ordered cart items. Returns the new
  /// order id. Throws a `Failure` (e.g. `out-of-stock`, `price-changed`).
  Future<String> placeOrder(OrderRequest request);

  /// Live orders of [uid], newest first. Malformed documents are skipped.
  Stream<List<Order>> watchMyOrders(String uid);

  /// Live list of all orders, newest first. Admin only (Security Rules).
  Stream<List<Order>> watchAllOrders();

  /// Live order, or null if it does not exist.
  Stream<Order?> watchOrder(String id);

  /// Admin only. Moves the order from [from] to [to], failing if someone
  /// else changed it in the meantime.
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus from,
    required OrderStatus to,
  });

  /// Cancels the order and returns its units to stock, in one transaction.
  /// [byStore] selects which business rule applies.
  Future<void> cancelOrder({required String orderId, required bool byStore});
}
