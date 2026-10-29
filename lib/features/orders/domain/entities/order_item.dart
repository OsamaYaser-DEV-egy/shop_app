import 'package:equatable/equatable.dart';

/// A product as it was when the order was placed. Name and price are copied
/// so past orders do not change when the product is edited later.
class OrderItem extends Equatable {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;

  double get total => price * quantity;

  @override
  List<Object?> get props => [productId, name, price, quantity];
}
