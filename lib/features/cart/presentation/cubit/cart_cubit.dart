import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/clear_cart.dart';
import '../../domain/usecases/remove_from_cart.dart';
import '../../domain/usecases/set_cart_quantity.dart';
import '../../domain/usecases/watch_cart.dart';
import 'cart_state.dart';

/// The signed-in customer's cart. Lives as long as the app and follows the
/// session through [bindUser].
///
/// Actions return a [Failure] (or null on success) instead of changing the
/// state: Firestore applies writes locally first, so the cart stream already
/// shows the change, and the caller decides how to report errors.
class CartCubit extends Cubit<CartState> {
  CartCubit({
    required WatchCart watchCart,
    required SetCartQuantity setCartQuantity,
    required RemoveFromCart removeFromCart,
    required ClearCart clearCart,
  })  : _watchCart = watchCart,
        _setCartQuantity = setCartQuantity,
        _removeFromCart = removeFromCart,
        _clearCart = clearCart,
        super(const CartState());

  final WatchCart _watchCart;
  final SetCartQuantity _setCartQuantity;
  final RemoveFromCart _removeFromCart;
  final ClearCart _clearCart;

  StreamSubscription<List<CartItem>>? _subscription;
  String? _uid;

  /// Starts watching the cart of [uid], or clears it when [uid] is null.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    if (uid == null) {
      emit(const CartState());
      return;
    }
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    emit(const CartState(status: CartStatus.loading));
    _subscription = _watchCart(uid).listen(
      (items) => emit(CartState(status: CartStatus.success, items: items)),
      onError: (Object error) {
        // Errors that arrive while signing out are expected and ignored.
        if (_uid == null) return;
        emit(CartState(
          status: CartStatus.failure,
          items: state.items,
          message: error is Failure
              ? error.message
              : 'Could not load your cart. Please try again.',
        ));
      },
    );
  }

  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _subscription?.cancel();
    _subscribe(uid);
  }

  /// Adds one unit of [product].
  Future<Failure?> add(Product product) =>
      setQuantity(product, state.quantityOf(product.id) + 1);

  /// A quantity below 1 removes the product.
  Future<Failure?> setQuantity(Product product, int quantity) {
    if (quantity < 1) return remove(product.id);
    return _run(
      (uid) => _setCartQuantity(uid: uid, product: product, quantity: quantity),
    );
  }

  Future<Failure?> remove(String productId) =>
      _run((uid) => _removeFromCart(uid: uid, productId: productId));

  Future<Failure?> clear() => _run(_clearCart.call);

  Future<Failure?> _run(Future<void> Function(String uid) action) async {
    final uid = _uid;
    if (uid == null) {
      return const Failure('Please sign in to continue.', code: 'unauthenticated');
    }
    try {
      await action(uid);
      return null;
    } on Failure catch (f) {
      return f;
    } catch (_) {
      return const Failure('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
