import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/cart/domain/entities/cart_item.dart';
import 'package:shop_app/features/orders/domain/entities/order_request.dart';
import 'package:shop_app/features/orders/domain/repositories/order_repository.dart';
import 'package:shop_app/features/orders/domain/usecases/place_order.dart';
import 'package:shop_app/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:shop_app/features/orders/presentation/cubit/checkout_state.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockPlaceOrder extends Mock implements PlaceOrder {}

OrderRequest _request({
  List<CartItem> items = const [CartItem(productId: 'p1', quantity: 2)],
  String phone = '+20 100 000 0000',
  String address = '12 Main Street, Cairo',
}) =>
    OrderRequest(
      userId: 'u1',
      customerName: 'Sam',
      customerEmail: 'sam@example.com',
      shippingAddress: address,
      phone: phone,
      items: items,
      expectedTotal: 40,
    );

void main() {
  setUpAll(() => registerFallbackValue(_request()));

  group('OrderRequest.validationError', () {
    test('accepts a valid request', () {
      expect(_request().validationError, isNull);
    });

    test('rejects an empty cart and too many products', () {
      expect(_request(items: const []).validationError, isNotNull);
      final many = [
        for (var i = 0; i <= OrderRequest.maxDistinctProducts; i++)
          CartItem(productId: 'p$i', quantity: 1),
      ];
      expect(_request(items: many).validationError, contains('up to'));
    });

    test('requires a phone number and a delivery address', () {
      expect(_request(phone: '').validationError, isNotNull);
      expect(_request(phone: 'abc').validationError, isNotNull);
      expect(_request(address: '').validationError, isNotNull);
      expect(_request(address: 'short').validationError, isNotNull);
    });
  });

  group('PlaceOrder', () {
    late _MockOrderRepository repository;

    setUp(() => repository = _MockOrderRepository());

    test('places a valid order and returns its id', () async {
      when(() => repository.placeOrder(any())).thenAnswer((_) async => 'o1');
      expect(await PlaceOrder(repository)(_request()), 'o1');
    });

    test('rejects an invalid request without calling the repository', () async {
      await expectLater(
        PlaceOrder(repository)(_request(phone: '')),
        throwsA(isA<Failure>().having((f) => f.code, 'code', 'invalid-order')),
      );
      verifyNever(() => repository.placeOrder(any()));
    });
  });

  group('CheckoutCubit', () {
    late _MockPlaceOrder placeOrder;

    setUp(() => placeOrder = _MockPlaceOrder());

    test('success stores the order id', () async {
      when(() => placeOrder(any())).thenAnswer((_) async => 'o1');
      final cubit = CheckoutCubit(placeOrder: placeOrder);
      await cubit.place(_request());
      expect(cubit.state.status, CheckoutStatus.success);
      expect(cubit.state.orderId, 'o1');
      await cubit.close();
    });

    test('failure shows the message and allows another try', () async {
      when(() => placeOrder(any()))
          .thenThrow(const Failure('Only 1 of Amp left in stock.'));
      final cubit = CheckoutCubit(placeOrder: placeOrder);
      await cubit.place(_request());
      expect(cubit.state.status, CheckoutStatus.failure);
      expect(cubit.state.message, 'Only 1 of Amp left in stock.');

      when(() => placeOrder(any())).thenAnswer((_) async => 'o2');
      await cubit.place(_request());
      expect(cubit.state.orderId, 'o2');
      await cubit.close();
    });

    test('ignores taps while placing and after success', () async {
      when(() => placeOrder(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'o1';
      });
      final cubit = CheckoutCubit(placeOrder: placeOrder);
      final first = cubit.place(_request());
      await cubit.place(_request());
      await first;
      await cubit.place(_request());
      verify(() => placeOrder(any())).called(1);
      await cubit.close();
    });
  });
}
