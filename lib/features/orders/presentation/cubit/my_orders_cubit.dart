import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/watch_my_orders.dart';
import 'my_orders_state.dart';

/// Live list of the customer's orders (statuses update while open).
class MyOrdersCubit extends Cubit<MyOrdersState> {
  MyOrdersCubit({required WatchMyOrders watchMyOrders, required String uid})
      : _watchMyOrders = watchMyOrders,
        _uid = uid,
        super(const MyOrdersState()) {
    _subscribe();
  }

  final WatchMyOrders _watchMyOrders;
  final String _uid;
  StreamSubscription<List<Order>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(const MyOrdersState());
    _subscription = _watchMyOrders(_uid).listen(
      (orders) => emit(
        MyOrdersState(status: MyOrdersStatus.success, orders: orders),
      ),
      onError: (Object error) => emit(
        MyOrdersState(
          status: MyOrdersStatus.failure,
          message: error is Failure
              ? error.message
              : 'Could not load your orders. Please try again.',
        ),
      ),
    );
  }

  void retry() => _subscribe();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
