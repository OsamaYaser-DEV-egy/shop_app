import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'product_card.dart';

/// Responsive grid: the number of columns adapts to the screen width.
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: products.length,
        itemBuilder: (_, index) => ProductCard(product: products[index]),
      ),
    );
  }
}
