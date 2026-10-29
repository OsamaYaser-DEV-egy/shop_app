import '../repositories/notification_repository.dart';

class MarkNotificationsRead {
  const MarkNotificationsRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call(List<String> ids) async {
    if (ids.isEmpty) return;
    await _repository.markRead(ids);
  }
}
