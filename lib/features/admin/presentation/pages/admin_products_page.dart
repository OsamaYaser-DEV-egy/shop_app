import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/cubit/product_list_cubit.dart';
import '../../../products/presentation/cubit/product_list_state.dart';
import '../../../products/presentation/cubit/product_management_cubit.dart';
import '../../../products/presentation/cubit/product_management_state.dart';
import '../widgets/admin_product_tile.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProductListCubit>()),
        BlocProvider(create: (_) => sl<ProductManagementCubit>()),
      ],
      child: const _AdminProductsView(),
    );
  }
}

class _AdminProductsView extends StatefulWidget {
  const _AdminProductsView();

  @override
  State<_AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<_AdminProductsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete product?',
      message:
          '"${product.name}" will be removed from the catalog. Past orders keep their saved copy.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<ProductManagementCubit>().delete(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = context.read<ProductListCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.adminProductNew),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: SafeArea(
        child: BlocListener<ProductManagementCubit, ProductManagementState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            if (state.status == ProductManagementStatus.success) {
              context.showSuccess(state.message ?? 'Done.');
            } else if (state.status == ProductManagementStatus.failure) {
              context.showError(state.message ?? 'Something went wrong.');
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search products',
                  onChanged: list.setQuery,
                ),
              ),
              BlocBuilder<ProductManagementCubit, ProductManagementState>(
                buildWhen: (p, c) => p.isBusy != c.isBusy,
                builder: (context, state) =>
                    state.isBusy ? const LinearProgressIndicator() : const SizedBox(height: 4),
              ),
              Expanded(
                child: BlocBuilder<ProductListCubit, ProductListState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case ProductListStatus.loading:
                        return const LoadingView();
                      case ProductListStatus.failure:
                        return ErrorView(
                          message: state.message ?? 'Could not load products.',
                          onRetry: list.retry,
                        );
                      case ProductListStatus.success:
                        return _buildList(state);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ProductListState state) {
    final visible = state.visible;
    if (state.products.isEmpty) {
      return const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        subtitle: 'Tap "Add product" to create the first one.',
      );
    }
    if (visible.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off,
        title: 'No matching products',
        subtitle: 'Try a different search.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final product = visible[index];
        return AdminProductTile(
          product: product,
          onEdit: () => context.pushNamed(
            RouteNames.adminProductEdit,
            pathParameters: {'id': product.id},
          ),
          onDelete: () => _confirmDelete(product),
        );
      },
    );
  }
}
