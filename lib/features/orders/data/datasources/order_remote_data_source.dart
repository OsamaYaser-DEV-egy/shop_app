// cloud_firestore has its own (index) Order type.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_request.dart';
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
