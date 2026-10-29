import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_draft.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Stream<List<Product>> watchProducts() => _remote.watchProducts().mapErrors();

  @override
  Stream<Product?> watchProduct(String id) =>
      _remote.watchProduct(id).mapErrors();

  @override
  Future<void> createProduct(ProductDraft draft) async {
    try {
      await _remote.create(draft);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> updateProduct(String id, ProductDraft draft) async {
    try {
      await _remote.update(id, draft);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _remote.delete(id);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
