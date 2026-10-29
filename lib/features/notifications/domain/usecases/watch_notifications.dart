import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repository);

  final NotificationRepository _repository;

  Stream<List<AppNotification>> call(String uid) =>
      _repository.watchNotifications(uid);
}
