import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';
import 'cart_item.dart';

/// A cart item joined with its live product.
class CartLine extends Equatable {
  const CartLine({required this.item, this.product});

  final CartItem item;

  /// Null when the product was deleted or can no longer be read.
  final Product? product;

  int get quantity => item.quantity;

  bool get isAvailable => product?.canBePurchased ?? false;

  /// The product is on sale, but there are fewer units than in the cart.
  bool get exceedsStock => isAvailable && quantity > product!.stock;

  bool get canBeOrdered => isAvailable && !exceedsStock;

  double get unitPrice => product?.price ?? 0;

  double get total => unitPrice * quantity;

  /// Highest quantity the customer may choose for this line.
  int get maxQuantity {
    final stock = product?.stock ?? 0;
    return stock < CartItem.maxQuantity ? stock : CartItem.maxQuantity;
  }

  @override
  List<Object?> get props => [item, product];
}

/// Totals for the cart page. Prices shown here are a preview; the final
/// prices are recalculated on the server when the order is placed.
class CartSummary extends Equatable {
  const CartSummary(this.lines);

  /// Joins [items] with [products]. Lines are sorted by product name, with
  /// products that no longer exist at the end.
  factory CartSummary.build(List<CartItem> items, List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    final lines = [
      for (final item in items)
        CartLine(item: item, product: byId[item.productId]),
    ];
    lines.sort((a, b) {
      final pa = a.product;
      final pb = b.product;
      if (pa == null || pb == null) {
        if (pa == pb) return a.item.productId.compareTo(b.item.productId);
        return pa == null ? 1 : -1;
      }
      return pa.name.toLowerCase().compareTo(pb.name.toLowerCase());
    });
    return CartSummary(lines);
  }

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  /// Units that can actually be ordered.
  int get orderableCount => lines
      .where((l) => l.canBeOrdered)
      .fold(0, (sum, l) => sum + l.quantity);

  /// Subtotal of the lines that can be ordered.
  double get subtotal => lines
      .where((l) => l.canBeOrdered)
      .fold(0.0, (sum, l) => sum + l.total);

  /// True when some lines must be removed or reduced before ordering.
  bool get hasIssues => lines.any((l) => !l.canBeOrdered);

  @override
  List<Object?> get props => [lines];
}
