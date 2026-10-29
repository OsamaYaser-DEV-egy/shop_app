import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../cubit/product_list_cubit.dart';
import '../cubit/product_list_state.dart';
import '../widgets/category_chips.dart';
import '../widgets/featured_products_row.dart';
import '../widgets/product_grid.dart';

/// Customer home: search, category chips, featured products and the catalog.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductListCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ProductListCubit>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductListCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.pushNamed(RouteNames.favorites),
          ),
          const CartIconButton(),
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.pushNamed(RouteNames.myOrders),
          ),
          const NotificationBell(),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.pushNamed(RouteNames.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ProductListCubit, ProductListState>(
          builder: (context, state) {
            switch (state.status) {
              case ProductListStatus.loading:
                return const LoadingView();
              case ProductListStatus.failure:
                return ErrorView(
                  message: state.message ?? 'Could not load products.',
                  onRetry: cubit.retry,
                );
              case ProductListStatus.success:
                return _buildCatalog(context, state, cubit);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCatalog(
    BuildContext context,
    ProductListState state,
    ProductListCubit cubit,
  ) {
    final visible = state.visible;
    final featured = state.featured;
    final showFeatured = !state.isFiltering && featured.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    Widget sectionTitle(String text) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(text, style: textTheme.titleMedium),
          ),
        );

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search products',
              onChanged: cubit.setQuery,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryChips(
            categories: state.categories,
            selected: state.category,
            onSelected: cubit.selectCategory,
          ),
        ),
        if (showFeatured) ...[
          sectionTitle('Featured'),
          SliverToBoxAdapter(child: FeaturedProductsRow(products: featured)),
        ],
        sectionTitle(state.isFiltering ? 'Results' : 'All products'),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: state.products.isEmpty
                ? const EmptyView(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    subtitle: 'Check back soon.',
                  )
                : EmptyView(
                    icon: Icons.search_off,
                    title: 'No matching products',
                    subtitle: 'Try a different search or category.',
                    action: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ),
          )
        else
          SliverProductGrid(products: visible),
      ],
    );
  }
}
