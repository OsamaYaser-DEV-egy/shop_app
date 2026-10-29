import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../products/presentation/cubit/product_list_cubit.dart';
import '../../../products/presentation/cubit/product_list_state.dart';
import '../../../products/presentation/widgets/product_grid.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

/// Products the customer has saved. Saved products that were deleted are
/// simply not shown.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductListCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          actions: const [CartIconButton()],
        ),
        body: SafeArea(
          child: BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favorites) =>
                BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, catalog) =>
                  _buildBody(context, favorites, catalog),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FavoritesState favorites,
    ProductListState catalog,
  ) {
    if (favorites.status == FavoritesStatus.failure) {
      return ErrorView(
        message: favorites.message ?? 'Could not load your favorites.',
        onRetry: context.read<FavoritesCubit>().retry,
      );
    }
    if (catalog.status == ProductListStatus.failure) {
      return ErrorView(
        message: catalog.message ?? 'Could not load products.',
        onRetry: context.read<ProductListCubit>().retry,
      );
    }
    if (favorites.status != FavoritesStatus.success ||
        catalog.status != ProductListStatus.success) {
      return const LoadingView();
    }

    final products =
        catalog.products.where((p) => favorites.isFavorite(p.id)).toList();
    if (products.isEmpty) {
      return const EmptyView(
        icon: Icons.favorite_border,
        title: 'No favorites yet',
        subtitle: 'Tap the heart on a product to save it here.',
      );
    }
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverProductGrid(products: products),
      ],
    );
  }
}
