import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../orders/domain/entities/order_status.dart';
import '../../domain/entities/app_notification.dart';

/// Serialization for `notifications/{id}`:
/// `{ userId, orderId, status, title, body, isRead, createdAt }`.
abstract final class NotificationModel {
  /// Returns null for documents that cannot be shown.
  static AppNotification? tryFromMap(String id, Map<String, dynamic> data) {
    final title = data['title'];
    if (title is! String || title.isEmpty) return null;
    final body = data['body'];
    final orderId = data['orderId'];
    final createdAt = data['createdAt'];
    return AppNotification(
      id: id,
      title: title,
      body: body is String ? body : '',
      isRead: data['isRead'] == true,
      orderId: orderId is String && orderId.isNotEmpty ? orderId : null,
      orderStatus: OrderStatus.fromName(data['status']),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// The notification written together with a store status change, or null
  /// when [status] does not notify the customer. The Security Rules check
  /// that it matches the order.
  static Map<String, dynamic>? forOrderStatus({
    required String userId,
    required String orderId,
    required OrderStatus status,
  }) {
    final message = orderStatusMessage(status, orderId);
    if (message == null) return null;
    return {
      'userId': userId,
      'orderId': orderId,
      'status': status.name,
      'title': message.title,
      'body': message.body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
