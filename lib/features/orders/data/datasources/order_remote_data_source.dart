// cloud_firestore has its own (index) Order type.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../notifications/data/models/notification_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_request.dart';
import '../../domain/entities/order_status.dart';
import '../models/order_model.dart';

/// Orders are written by the app in a transaction (no Cloud Functions on the
/// Spark plan). The Security Rules make the transaction trustworthy: prices
/// and the total must match the products, and each product's stock may only
/// drop by the quantity ordered (see `firestore.rules`).
class OrderRemoteDataSource {
  const OrderRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestorePaths.orders);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);

  DocumentReference<Map<String, dynamic>> _cartDoc(String uid, String id) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.cart)
          .doc(id);

  Future<String> placeOrder(OrderRequest request) async {
    final orderRef = _orders.doc();
    await _firestore.runTransaction<void>((tx) async {
      // All reads must happen before any write.
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in request.items) {
        snapshots.add(await tx.get(_products.doc(item.productId)));
      }

      final items = <String, Map<String, dynamic>>{};
      final newStock = <String, int>{};
      var total = 0.0;
      for (var i = 0; i < request.items.length; i++) {
        final item = request.items[i];
        final data = snapshots[i].data();
        final product =
            data == null ? null : ProductModel.tryFromMap(item.productId, data);
        if (data == null || product == null) {
          throw const Failure(
            'A product in your cart is no longer available.',
            code: 'out-of-stock',
          );
        }
        if (!product.canBePurchased || product.stock < item.quantity) {
          throw Failure(
            product.canBePurchased
                ? 'Only ${product.stock} of ${product.name} left in stock.'
                : '${product.name} is out of stock.',
            code: 'out-of-stock',
          );
        }
        items[item.productId] = OrderModel.itemMap(data, item.quantity);
        newStock[item.productId] = product.stock - item.quantity;
        total += (data['price'] as num) * item.quantity;
      }

      final totalPrice = OrderModel.roundMoney(total);
      if ((totalPrice - request.expectedTotal).abs() >= 0.005) {
        throw const Failure(
          'Some prices have changed. Please review your order and try again.',
          code: 'price-changed',
        );
      }

      newStock.forEach((productId, stock) {
        tx.update(_products.doc(productId), {
          'stock': stock,
          // Lets the rules link this stock change to the new order.
          'lastOrderId': orderRef.id,
        });
      });
      tx.set(
        orderRef,
        OrderModel.createMap(
          request: request,
          items: items,
          totalPrice: totalPrice,
        ),
      );
      for (final item in request.items) {
        tx.delete(_cartDoc(request.userId, item.productId));
      }
    });
    return orderRef.id;
  }

  /// Sorting is done locally, so no composite index is needed.
  Stream<List<Order>> watchMyOrders(String uid) {
    return _orders.where('userId', isEqualTo: uid).snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.tryFromMap(doc.id, doc.data()))
          .whereType<Order>()
          .toList();
      orders.sort(newestFirst);
      return orders;
    });
  }

  /// The newest [limit] orders. A single-field order needs no composite
  /// index.
  Stream<List<Order>> watchAllOrders({int limit = 200}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.tryFromMap(doc.id, doc.data()))
              .whereType<Order>()
              .toList(),
        );
  }

  Future<void> updateStatus(
    String orderId,
    OrderStatus from,
    OrderStatus to,
  ) async {
    final ref = _orders.doc(orderId);
    await _firestore.runTransaction<void>((tx) async {
      final snapshot = await tx.get(ref);
      final current = OrderStatus.fromName(snapshot.data()?['status']);
      if (current != from) throw _changedElsewhere;
      tx.update(ref, OrderModel.statusMap(to));
      _notifyCustomer(tx, orderId, snapshot.data()?['userId'], to);
    });
  }

  /// Writes the customer's in-app notification in the same transaction as
  /// the status change, so one never happens without the other. The
  /// customer's app shows it as a local notification while it is running.
  void _notifyCustomer(
    Transaction tx,
    String orderId,
    Object? userId,
    OrderStatus status,
  ) {
    if (userId is! String) return;
    final notification = NotificationModel.forOrderStatus(
      userId: userId,
      orderId: orderId,
      status: status,
    );
    if (notification == null) return;
    tx.set(_firestore.collection(FirestorePaths.notifications).doc(), notification);
  }

  /// Marks the order cancelled and returns every item to stock, in one
  /// transaction. Products that were deleted since are skipped. The rules
  /// allow each product's stock to rise by exactly the cancelled quantity.
  Future<void> cancelOrder(String orderId, {required bool byStore}) async {
    final ref = _orders.doc(orderId);
    await _firestore.runTransaction<void>((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      final order = data == null ? null : OrderModel.tryFromMap(orderId, data);
      if (order == null) {
        throw const Failure('This order no longer exists.', code: 'not-found');
      }
      final allowed = byStore
          ? order.status.canBeCancelledByStore
          : order.status.canBeCancelledByCustomer;
      if (!allowed) throw _changedElsewhere;

      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in order.items) {
        products.add(await tx.get(_products.doc(item.productId)));
      }

      tx.update(ref, OrderModel.statusMap(OrderStatus.cancelled));
      // Customers cancel their own orders, so only the store's notifies.
      if (byStore) {
        _notifyCustomer(tx, orderId, order.userId, OrderStatus.cancelled);
      }
      for (var i = 0; i < order.items.length; i++) {
        final stock = products[i].data()?['stock'];
        if (!products[i].exists || stock is! num) continue;
        tx.update(products[i].reference, {
          'stock': stock.toInt() + order.items[i].quantity,
          // Lets the rules link this stock change to the cancelled order.
          'lastRestockOrderId': orderId,
        });
      }
    });
  }

  static const Failure _changedElsewhere = Failure(
    'This order was just updated. Please check its status and try again.',
    code: 'status-changed',
  );

  Stream<Order?> watchOrder(String id) {
    return _orders.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OrderModel.tryFromMap(snapshot.id, data);
    });
  }

  /// Newest first; orders whose server time is still pending come first.
  static int newestFirst(Order a, Order b) {
    final ta = a.createdAt;
    final tb = b.createdAt;
    if (ta == null || tb == null) {
      if (ta == tb) return 0;
      return ta == null ? -1 : 1;
    }
    return tb.compareTo(ta);
  }
}
