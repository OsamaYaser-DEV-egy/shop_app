import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_request.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<String> placeOrder(OrderRequest request) async {
    try {
      return await _remote.placeOrder(request);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Stream<List<Order>> watchMyOrders(String uid) =>
      _remote.watchMyOrders(uid).mapErrors();

  @override
  Stream<List<Order>> watchAllOrders() => _remote.watchAllOrders().mapErrors();

  @override
  Stream<Order?> watchOrder(String id) => _remote.watchOrder(id).mapErrors();

  @override
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus from,
    required OrderStatus to,
  }) async {
    try {
      await _remote.updateStatus(orderId, from, to);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> cancelOrder({
    required String orderId,
    required bool byStore,
  }) async {
    try {
      await _remote.cancelOrder(orderId, byStore: byStore);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
