import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../cart/presentation/widgets/add_to_cart_bar.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/product.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';
import '../widgets/product_image.dart';
import '../widgets/stock_badge.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailsCubit>(param1: productId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product details'),
          actions: [
            // Only offered once the product exists, so a removed product
            // cannot be saved.
            BlocSelector<ProductDetailsCubit, ProductDetailsState, bool>(
              selector: (state) => state.product != null,
              builder: (_, hasProduct) => hasProduct
                  ? FavoriteButton(productId: productId)
                  : const SizedBox.shrink(),
            ),
            const CartIconButton(),
          ],
        ),
        bottomNavigationBar:
            BlocSelector<ProductDetailsCubit, ProductDetailsState, Product?>(
          selector: (state) => state.product,
          builder: (_, product) => product == null
              ? const SizedBox.shrink()
              : AddToCartBar(product: product),
        ),
        body: SafeArea(
          child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
            builder: (context, state) {
              switch (state.status) {
                case ProductDetailsStatus.loading:
                  return const LoadingView();
                case ProductDetailsStatus.notFound:
                  return const EmptyView(
                    icon: Icons.search_off,
                    title: 'Product not available',
                    subtitle: 'This product may have been removed.',
                  );
                case ProductDetailsStatus.failure:
                  return ErrorView(
                    message: state.message ?? 'Could not load this product.',
                    onRetry: context.read<ProductDetailsCubit>().retry,
                  );
                case ProductDetailsStatus.success:
                  return _ProductDetailsBody(product: state.product!);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = product.description.trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.15,
              child: ProductImage(url: product.imageUrl),
            ),
          ),
          const SizedBox(height: 20),
          Text(product.name, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            Formatters.price(product.price),
            style: textTheme.headlineMedium?.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text(product.category)),
              StockBadge(product: product),
            ],
          ),
          if (product.canBePurchased) ...[
            const SizedBox(height: 12),
            Text(
              '${product.stock} units available',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text('Description', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            description.isEmpty ? 'No description provided.' : description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
