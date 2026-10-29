import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// Bottom bar on the product page: adds one unit per tap and links to the
/// cart once the product is in it.
class AddToCartBar extends StatelessWidget {
  const AddToCartBar({super.key, required this.product});

  final Product product;

  Future<void> _add(BuildContext context) async {
    final failure = await context.read<CartCubit>().add(product);
    if (failure != null) {
      AppMessenger.showError(failure.message);
    } else {
      AppMessenger.showSuccess('Added to cart.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.quantityOf(product.id),
      builder: (context, inCart) {
        final atLimit =
            inCart >= product.stock || inCart >= CartItem.maxQuantity;
        final String label;
        if (!product.canBePurchased) {
          label = 'Out of stock';
        } else if (atLimit) {
          label = 'All available units are in your cart';
        } else {
          label = 'Add to cart';
        }
        final canAdd = product.canBePurchased && !atLimit;

        return Material(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (inCart > 0)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$inCart in your cart',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pushNamed(RouteNames.cart),
                          child: const Text('View cart'),
                        ),
                      ],
                    ),
                  FilledButton.icon(
                    onPressed: canAdd ? () => _add(context) : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
