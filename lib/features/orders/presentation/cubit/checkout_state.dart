import 'package:equatable/equatable.dart';

enum CheckoutStatus { idle, placing, success, failure }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.message,
  });

  final CheckoutStatus status;

  /// Set once the order is placed.
  final String? orderId;
  final String? message;

  bool get isPlacing => status == CheckoutStatus.placing;

  @override
  List<Object?> get props => [status, orderId, message];
}
