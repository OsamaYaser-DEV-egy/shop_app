import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  /// Live notifications of [uid], newest first. Emits a `Failure` error if
  /// they cannot be read.
  Stream<List<AppNotification>> watchNotifications(String uid);

  /// Marks the given notifications as read (the only change customers may
  /// make).
  Future<void> markRead(List<String> ids);
}
