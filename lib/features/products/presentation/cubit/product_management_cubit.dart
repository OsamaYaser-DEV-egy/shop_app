import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_draft.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/update_product.dart';
import 'product_management_state.dart';

/// Admin actions on products: create, update and delete.
/// Firestore rules are what actually restrict these to admins.
class ProductManagementCubit extends Cubit<ProductManagementState> {
  ProductManagementCubit({
    required CreateProduct createProduct,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
  })  : _createProduct = createProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        super(const ProductManagementState());

  final CreateProduct _createProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;

  /// Creates a product when [id] is null, otherwise updates it.
  Future<void> save({String? id, required ProductDraft draft}) {
    return _run(
      busy: ProductManagementStatus.saving,
      successMessage: id == null ? 'Product created.' : 'Product updated.',
      action: () => id == null
          ? _createProduct(draft)
          : _updateProduct(id, draft),
    );
  }

  Future<void> delete(String id) {
    return _run(
      busy: ProductManagementStatus.deleting,
      successMessage: 'Product deleted.',
      action: () => _deleteProduct(id),
    );
  }

  Future<void> _run({
    required ProductManagementStatus busy,
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (state.isBusy) return; // prevents duplicate submissions
    emit(ProductManagementState(status: busy));
    try {
      await action();
      if (isClosed) return;
      emit(ProductManagementState(
        status: ProductManagementStatus.success,
        message: successMessage,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ProductManagementState(
        status: ProductManagementStatus.failure,
        message: f.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const ProductManagementState(
        status: ProductManagementStatus.failure,
        message: 'Something went wrong. Please try again.',
      ));
    }
  }
}
