import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../orders/domain/entities/order_request.dart';
import '../../../products/presentation/cubit/product_list_cubit.dart';
import '../../../products/presentation/cubit/product_list_state.dart';
import '../../domain/entities/cart_summary.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_line_tile.dart';

/// The customer's cart, joined with live product data.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The catalog provides live names, prices and stock for the cart lines.
    return BlocProvider(
      create: (_) => sl<ProductListCubit>(),
      child: const _CartView(),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  static void _report(Failure? failure) {
    if (failure != null) AppMessenger.showError(failure.message);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear cart?',
      message: 'All items will be removed from your cart.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      _report(await context.read<CartCubit>().clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        return BlocBuilder<ProductListCubit, ProductListState>(
          builder: (context, catalog) {
            final ready = cart.status == CartStatus.success &&
                catalog.status == ProductListStatus.success;
            final summary = ready && cart.items.isNotEmpty
                ? CartSummary.build(cart.items, catalog.products)
                : null;
            return Scaffold(
              appBar: AppBar(
                title: const Text('My cart'),
                actions: [
                  if (summary != null)
                    TextButton(
                      onPressed: () => _confirmClear(context),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              body: SafeArea(
                child: summary == null
                    ? _buildStatus(context, cart, catalog)
                    : _buildLines(context, summary),
              ),
              bottomNavigationBar:
                  summary == null ? null : _SummaryBar(summary: summary),
            );
          },
        );
      },
    );
  }

  Widget _buildStatus(
    BuildContext context,
    CartState cart,
    ProductListState catalog,
  ) {
    if (cart.status == CartStatus.failure) {
      return ErrorView(
        message: cart.message ?? 'Could not load your cart.',
        onRetry: context.read<CartCubit>().retry,
      );
    }
    if (catalog.status == ProductListStatus.failure) {
      return ErrorView(
        message: catalog.message ?? 'Could not load products.',
        onRetry: context.read<ProductListCubit>().retry,
      );
    }
    if (cart.status != CartStatus.success ||
        catalog.status != ProductListStatus.success) {
      return const LoadingView();
    }
    return EmptyView(
      icon: Icons.shopping_bag_outlined,
      title: 'Your cart is empty',
      subtitle: 'Browse the catalog and add something you like.',
      action: OutlinedButton(
        onPressed: () => context.goNamed(RouteNames.home),
        child: const Text('Browse products'),
      ),
    );
  }

  Widget _buildLines(BuildContext context, CartSummary summary) {
    final cubit = context.read<CartCubit>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: summary.lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final line = summary.lines[index];
        final product = line.product;
        return CartLineTile(
          key: ValueKey(line.item.productId),
          line: line,
          onQuantityChanged: product == null
              ? (_) {}
              : (quantity) async =>
                  _report(await cubit.setQuantity(product, quantity)),
          onRemove: () async =>
              _report(await cubit.remove(line.item.productId)),
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = summary.orderableCount;
    final tooManyProducts =
        summary.lines.length > OrderRequest.maxDistinctProducts;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (summary.hasIssues) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some items cannot be ordered and are not included '
                        'in the subtotal.',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subtotal ($count ${count == 1 ? 'item' : 'items'})',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    Formatters.price(summary.subtotal),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              if (tooManyProducts) ...[
                const SizedBox(height: 8),
                Text(
                  'You can order up to ${OrderRequest.maxDistinctProducts} '
                  'different products at a time. Remove some to continue.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: summary.hasIssues || tooManyProducts
                    ? null
                    : () => context.pushNamed(RouteNames.checkout),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
