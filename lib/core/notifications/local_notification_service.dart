import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/domain/entities/app_notification.dart';
import 'notification_tap.dart';

/// Shows order notifications on the device while the app is running and
/// reports taps. There is no push server (Spark plan), so nothing arrives
/// while the app is closed; those notifications wait in the in-app list.
class LocalNotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapQueue? _taps;
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'orders',
    'Order updates',
    description: 'Status changes of your orders',
    importance: Importance.high,
  );

  /// Call once at startup. [onOpen] runs for every tap, but only while a
  /// customer is signed in (see [bindUser]).
  Future<void> init({required void Function(NotificationTap tap) onOpen}) async {
    final taps = NotificationTapQueue(onOpen);
    _taps = taps;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _onPayload(response.payload),
      );
      await _android?.createNotificationChannel(_channel);
      _initialized = true;

      // The app was started by tapping one of our notifications.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _onPayload(launch?.notificationResponse?.payload);
      }
    } catch (_) {
      // Notifications are a convenience; they must never block startup.
    }
  }

  /// Follows the session: asks for permission when a customer signs in and
  /// clears shown notifications when they sign out.
  Future<void> bindUser(String? uid) async {
    _taps?.setReady(uid != null);
    if (!_initialized) return;
    try {
      if (uid == null) {
        await _plugin.cancelAll();
      } else {
        // Android 13+ asks once; later calls return the saved answer.
        await _android?.requestNotificationsPermission();
      }
    } catch (_) {}
  }

  Future<void> show(AppNotification notification) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: notification.id.hashCode & 0x7fffffff,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: NotificationTap(
          notificationId: notification.id,
          orderId: notification.orderId,
        ).encode(),
      );
    } catch (_) {}
  }

  void _onPayload(String? payload) {
    final tap = NotificationTap.tryDecode(payload);
    if (tap != null) _taps?.add(tap);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
}
