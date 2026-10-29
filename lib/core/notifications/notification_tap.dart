import 'dart:convert';

/// What a tapped local notification refers to. Stored as its payload.
class NotificationTap {
  const NotificationTap({required this.notificationId, this.orderId});

  final String notificationId;
  final String? orderId;

  String encode() => jsonEncode({
        'notificationId': notificationId,
        if (orderId != null) 'orderId': orderId,
      });

  static NotificationTap? tryDecode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload);
      final id = data is Map ? data['notificationId'] : null;
      if (id is! String || id.isEmpty) return null;
      final orderId = data['orderId'];
      return NotificationTap(
        notificationId: id,
        orderId: orderId is String ? orderId : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Holds a tap until a customer is signed in, e.g. when the tap launched the
/// app and the session is still loading.
class NotificationTapQueue {
  NotificationTapQueue(this._open);

  final void Function(NotificationTap tap) _open;
  NotificationTap? _pending;
  bool _ready = false;

  void add(NotificationTap tap) {
    _pending = tap;
    _flush();
  }

  /// [ready] is true while a customer is signed in.
  void setReady(bool ready) {
    _ready = ready;
    _flush();
  }

  void _flush() {
    final tap = _pending;
    if (!_ready || tap == null) return;
    _pending = null;
    _open(tap);
  }
}
