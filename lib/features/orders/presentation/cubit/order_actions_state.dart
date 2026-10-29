import 'package:equatable/equatable.dart';

enum OrderActionsStatus { idle, working, success, failure }

class OrderActionsState extends Equatable {
  const OrderActionsState({
    this.status = OrderActionsStatus.idle,
    this.message,
  });

  final OrderActionsStatus status;
  final String? message;

  bool get isWorking => status == OrderActionsStatus.working;

  @override
  List<Object?> get props => [status, message];
}
