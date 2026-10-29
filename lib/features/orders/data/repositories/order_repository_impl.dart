import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_request.dart';
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
  Stream<Order?> watchOrder(String id) => _remote.watchOrder(id).mapErrors();
}
