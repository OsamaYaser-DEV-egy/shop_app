import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/watch_products.dart';
import 'product_list_state.dart';

/// Live product list with local search and category filtering.
class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({required WatchProducts watchProducts})
      : _watchProducts = watchProducts,
        super(const ProductListState()) {
    _subscribe();
  }

  final WatchProducts _watchProducts;
  StreamSubscription<List<Product>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: ProductListStatus.loading));
    _subscription = _watchProducts().listen(
      (products) => emit(
        state.copyWith(status: ProductListStatus.success, products: products),
      ),
      onError: (Object error) => emit(
        state.copyWith(
          status: ProductListStatus.failure,
          message: error is Failure
              ? error.message
              : 'Could not load products. Please try again.',
        ),
      ),
    );
  }

  void retry() => _subscribe();

  void setQuery(String query) => emit(state.copyWith(query: query));

  /// Pass null to show all categories.
  void selectCategory(String? category) {
    emit(
      category == null
          ? state.copyWith(clearCategory: true)
          : state.copyWith(category: category),
    );
  }

  void clearFilters() => emit(state.copyWith(query: '', clearCategory: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
