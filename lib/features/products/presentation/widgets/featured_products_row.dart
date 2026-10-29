import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'product_card.dart';

class FeaturedProductsRow extends StatelessWidget {
  const FeaturedProductsRow({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(
          width: 164,
          child: ProductCard(product: products[index]),
        ),
      ),
    );
  }
}
