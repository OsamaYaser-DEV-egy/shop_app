import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../domain/entities/cart_summary.dart';
import 'quantity_stepper.dart';

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartLine line;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  /// Why the line cannot be ordered, or null when it can.
  String? get _issue {
    final product = line.product;
    if (product == null) return 'This product is no longer available.';
    if (!line.isAvailable) return 'Out of stock. Remove it to continue.';
    if (line.exceedsStock) {
      return 'Only ${product.stock} left. Lower the quantity.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final textTheme = Theme.of(context).textTheme;
    final issue = _issue;
    final quantity = line.quantity;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: product == null
            ? null
            : () => context.pushNamed(
                  RouteNames.productDetails,
                  pathParameters: {'id': product.id},
                ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ProductImage(url: product?.imageUrl ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Unavailable product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.price(product.price)} each',
                        style: textTheme.bodySmall,
                      ),
                    ],
                    if (issue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        issue,
                        style: textTheme.bodySmall?.copyWith(
                          color: line.exceedsStock
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                      ),
                    ],
                    if (line.isAvailable) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          QuantityStepper(
                            quantity: quantity,
                            onDecrement: quantity <= 1
                                ? null
                                : () => onQuantityChanged(
                                      math.min(quantity - 1, line.maxQuantity),
                                    ),
                            onIncrement: quantity >= line.maxQuantity
                                ? null
                                : () => onQuantityChanged(quantity + 1),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.price(line.total),
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
