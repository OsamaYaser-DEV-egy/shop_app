import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/watch_product.dart';
import 'product_details_state.dart';

/// Live view of one product (price and stock update while the page is open).
class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit({
    required WatchProduct watchProduct,
    required String productId,
  })  : _watchProduct = watchProduct,
        _productId = productId,
        super(const ProductDetailsState()) {
    _subscribe();
  }

  final WatchProduct _watchProduct;
  final String _productId;
  StreamSubscription<Product?>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(const ProductDetailsState());
    _subscription = _watchProduct(_productId).listen(
      (product) => emit(
        product == null
            ? const ProductDetailsState(status: ProductDetailsStatus.notFound)
            : ProductDetailsState(
                status: ProductDetailsStatus.success,
                product: product,
              ),
      ),
      onError: (Object error) => emit(
        ProductDetailsState(
          status: ProductDetailsStatus.failure,
          message: error is Failure
              ? error.message
              : 'Could not load this product. Please try again.',
        ),
      ),
    );
  }

  void retry() => _subscribe();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
