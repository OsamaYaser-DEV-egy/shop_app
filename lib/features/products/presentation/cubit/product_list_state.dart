import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

enum ProductListStatus { loading, success, failure }

class ProductListState extends Equatable {
  const ProductListState({
    this.status = ProductListStatus.loading,
    this.products = const [],
    this.query = '',
    this.category,
    this.message,
  });

  final ProductListStatus status;
  final List<Product> products;
  final String query;

  /// Selected category, or null for "All".
  final String? category;
  final String? message;

  /// Distinct categories, sorted case-insensitively.
  List<String> get categories {
    final set = products.map((p) => p.category).toSet().toList();
    set.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  /// Products matching the search text (by name) and selected category.
  List<Product> get visible {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      final matchesCategory = category == null || p.category == category;
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Featured products that can actually be bought.
  List<Product> get featured =>
      products.where((p) => p.isFeatured && p.canBePurchased).toList();

  bool get isFiltering => query.trim().isNotEmpty || category != null;

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    String? query,
    String? category,
    bool clearCategory = false,
    String? message,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, products, query, category, message];
}
