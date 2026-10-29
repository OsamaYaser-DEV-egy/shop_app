import 'package:equatable/equatable.dart';

/// The editable fields of a product, before it has an id.
class ProductDraft extends Equatable {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isAvailable,
    this.isFeatured = false,
  });

  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool isAvailable;
  final bool isFeatured;

  /// A user-safe message describing the first problem, or null if valid.
  String? get validationError {
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 120) {
      return 'Product name must be 2 to 120 characters.';
    }
    if (description.length > 2000) {
      return 'Description must be 2000 characters or fewer.';
    }
    if (!price.isFinite || price <= 0 || price > 1000000) {
      return 'Price must be greater than 0.';
    }
    if (stock < 0 || stock > 100000) {
      return 'Stock must be between 0 and 100000.';
    }
    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty || cleanCategory.length > 40) {
      return 'Category must be 1 to 40 characters.';
    }
    final url = imageUrl.trim();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      final ok = uri != null &&
          uri.hasAuthority &&
          (uri.scheme == 'http' || uri.scheme == 'https');
      if (!ok) return 'Image URL must be a valid http(s) link.';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        name,
        description,
        price,
        imageUrl,
        category,
        stock,
        isAvailable,
        isFeatured,
      ];
}
