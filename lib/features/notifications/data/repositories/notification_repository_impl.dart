import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) =>
      _remote.watchNotifications(uid).mapErrors();

  @override
  Future<void> markRead(List<String> ids) async {
    try {
      await _remote.markRead(ids);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
