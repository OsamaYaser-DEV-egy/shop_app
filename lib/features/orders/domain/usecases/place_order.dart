import '../../../../core/errors/failures.dart';
import '../entities/order_request.dart';
import '../repositories/order_repository.dart';

class PlaceOrder {
  const PlaceOrder(this._repository);

  final OrderRepository _repository;

  /// Returns the id of the new order.
  Future<String> call(OrderRequest request) async {
    final error = request.validationError;
    if (error != null) throw Failure(error, code: 'invalid-order');
    return _repository.placeOrder(request);
  }
}
