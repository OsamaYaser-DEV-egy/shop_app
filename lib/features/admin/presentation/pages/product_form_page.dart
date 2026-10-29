import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../products/presentation/cubit/product_details_cubit.dart';
import '../../../products/presentation/cubit/product_details_state.dart';
import '../../../products/presentation/cubit/product_management_cubit.dart';
import '../../../products/presentation/cubit/product_management_state.dart';
import '../widgets/product_form.dart';

/// Create (productId == null) or edit a product.
class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context) {
    final id = productId;
    return BlocProvider(
      create: (_) => sl<ProductManagementCubit>(),
      child: Scaffold(
        appBar: AppBar(title: Text(id == null ? 'New product' : 'Edit product')),
        body: SafeArea(
          child: BlocListener<ProductManagementCubit, ProductManagementState>(
            listenWhen: (p, c) => p.status != c.status,
            listener: (context, state) {
              if (state.status == ProductManagementStatus.success) {
                context.showSuccess(state.message ?? 'Saved.');
                context.pop();
              } else if (state.status == ProductManagementStatus.failure) {
                context.showError(state.message ?? 'Could not save.');
              }
            },
            child: id == null ? const ProductForm() : _EditLoader(productId: id),
          ),
        ),
      ),
    );
  }
}

/// Loads the product to edit before showing the form.
class _EditLoader extends StatelessWidget {
  const _EditLoader({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailsCubit>(param1: productId),
      child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case ProductDetailsStatus.loading:
              return const LoadingView();
            case ProductDetailsStatus.notFound:
              return const EmptyView(
                icon: Icons.search_off,
                title: 'Product not found',
                subtitle: 'It may have been deleted.',
              );
            case ProductDetailsStatus.failure:
              return ErrorView(
                message: state.message ?? 'Could not load this product.',
                onRetry: context.read<ProductDetailsCubit>().retry,
              );
            case ProductDetailsStatus.success:
              return ProductForm(productId: productId, initial: state.product);
          }
        },
      ),
    );
  }
}
