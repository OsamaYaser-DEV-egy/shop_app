import 'package:equatable/equatable.dart';

enum ProductManagementStatus { idle, saving, deleting, success, failure }

class ProductManagementState extends Equatable {
  const ProductManagementState({
    this.status = ProductManagementStatus.idle,
    this.message,
  });

  final ProductManagementStatus status;
  final String? message;

  bool get isBusy =>
      status == ProductManagementStatus.saving ||
      status == ProductManagementStatus.deleting;

  @override
  List<Object?> get props => [status, message];
}
