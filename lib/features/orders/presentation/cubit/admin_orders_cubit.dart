import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/usecases/watch_all_orders.dart';
import 'admin_orders_state.dart';

/// Live list of all orders for the admin, with a local status filter.
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit({required WatchAllOrders watchAllOrders})
      : _watchAllOrders = watchAllOrders,
        super(const AdminOrdersState()) {
    _subscribe();
  }

  final WatchAllOrders _watchAllOrders;
  StreamSubscription<List<Order>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: AdminOrdersStatus.loading));
    _subscription = _watchAllOrders().listen(
      (orders) => emit(
        state.copyWith(status: AdminOrdersStatus.success, orders: orders),
      ),
      onError: (Object error) => emit(
        state.copyWith(
          status: AdminOrdersStatus.failure,
          message: error is Failure
              ? error.message
              : 'Could not load orders. Please try again.',
        ),
      ),
    );
  }

  void retry() => _subscribe();

  /// Pass null to show all orders.
  void setFilter(OrderStatus? status) {
    emit(
      status == null
          ? state.copyWith(clearFilter: true)
          : state.copyWith(filter: status),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
