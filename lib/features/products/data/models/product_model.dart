import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_draft.dart';

/// Serialization for `products/{productId}`.
abstract final class ProductModel {
  /// Returns null for documents that cannot be shown safely (no name, or a
  /// missing/negative price), so one bad document never breaks the catalog.
  /// A missing `isAvailable` is treated as unavailable.
  static Product? tryFromMap(String id, Map<String, dynamic> data) {
    final name = _string(data['name']).trim();
    final price = _number(data['price']);
    if (name.isEmpty || price == null || price < 0 || !price.isFinite) {
      return null;
    }
    final category = _string(data['category']).trim();
    final stock = _number(data['stock'])?.toInt() ?? 0;
    return Product(
      id: id,
      name: name,
      description: _string(data['description']),
      price: price.toDouble(),
      imageUrl: _string(data['imageUrl']).trim(),
      category: category.isEmpty ? 'Other' : category,
      stock: math.max(0, stock),
      isAvailable: data['isAvailable'] == true,
      isFeatured: data['isFeatured'] == true,
    );
  }

  static Map<String, dynamic> createMap(ProductDraft draft) {
    return {
      ..._fields(draft),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> updateMap(ProductDraft draft) {
    return {
      ..._fields(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> _fields(ProductDraft draft) {
    return {
      'name': draft.name.trim(),
      'description': draft.description.trim(),
      'price': draft.price,
      'imageUrl': draft.imageUrl.trim(),
      'category': draft.category.trim(),
      'stock': draft.stock,
      'isAvailable': draft.isAvailable,
      'isFeatured': draft.isFeatured,
    };
  }

  static String _string(Object? value) => value is String ? value : '';

  static num? _number(Object? value) => value is num ? value : null;
}
