import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._remote);

  final CartRemoteDataSource _remote;

  @override
  Stream<List<CartItem>> watchCart(String uid) =>
      _remote.watchCart(uid).mapErrors();

  @override
  Future<void> setQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    try {
      await _remote.setQuantity(uid, productId, quantity);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> remove({required String uid, required String productId}) async {
    try {
      await _remote.remove(uid, productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> clear(String uid) async {
    try {
      await _remote.clear(uid);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
