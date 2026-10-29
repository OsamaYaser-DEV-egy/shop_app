import 'package:equatable/equatable.dart';

enum StockLevel { outOfStock, low, available }

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isAvailable,
    this.isFeatured = false,
  });

  /// Stock at or below this number is shown as "low".
  static const int lowStockThreshold = 5;

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool isAvailable;
  final bool isFeatured;

  bool get canBePurchased => isAvailable && stock > 0;

  StockLevel get stockLevel {
    if (!canBePurchased) return StockLevel.outOfStock;
    if (stock <= lowStockThreshold) return StockLevel.low;
    return StockLevel.available;
  }

  @override
  List<Object?> get props => [
        id,
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
