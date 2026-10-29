import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.product,
    this.hideWhenAvailable = false,
  });

  final Product product;

  /// On cards, only warn about low or no stock.
  final bool hideWhenAvailable;

  @override
  Widget build(BuildContext context) {
    final level = product.stockLevel;
    if (level == StockLevel.available && hideWhenAvailable) {
      return const SizedBox.shrink();
    }

    final (String label, Color color) = switch (level) {
      StockLevel.outOfStock => ('Out of stock', AppColors.error),
      StockLevel.low => ('Only ${product.stock} left', AppColors.warning),
      StockLevel.available => ('In stock', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
