import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_request.dart';
import '../../domain/usecases/place_order.dart';
import 'checkout_state.dart';

/// Places one order (Cash on Delivery). Page-scoped.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({required PlaceOrder placeOrder})
      : _placeOrder = placeOrder,
        super(const CheckoutState());

  final PlaceOrder _placeOrder;

  Future<void> place(OrderRequest request) async {
    // Prevents duplicate orders from double taps, and a second order after
    // the first succeeded.
    if (state.isPlacing || state.status == CheckoutStatus.success) return;
    emit(const CheckoutState(status: CheckoutStatus.placing));
    try {
      final orderId = await _placeOrder(request);
      if (isClosed) return;
      emit(CheckoutState(status: CheckoutStatus.success, orderId: orderId));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(CheckoutState(status: CheckoutStatus.failure, message: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(const CheckoutState(
        status: CheckoutStatus.failure,
        message: 'Could not place your order. Please try again.',
      ));
    }
  }
}
