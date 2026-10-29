import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

enum ProductDetailsStatus { loading, success, notFound, failure }

class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.status = ProductDetailsStatus.loading,
    this.product,
    this.message,
  });

  final ProductDetailsStatus status;
  final Product? product;
  final String? message;

  @override
  List<Object?> get props => [status, product, message];
}
