import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

/// Admin: moves an order to its next status.
class UpdateOrderStatus {
  const UpdateOrderStatus(this._repository);

  final OrderRepository _repository;

  Future<void> call(Order order) async {
    final next = order.status.next;
    if (next == null) {
      throw Failure(
        'A ${order.status.label.toLowerCase()} order cannot be changed.',
        code: 'invalid-status',
      );
    }
    await _repository.updateStatus(
      orderId: order.id,
      from: order.status,
      to: next,
    );
  }
}
