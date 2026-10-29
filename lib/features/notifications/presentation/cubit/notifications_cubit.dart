import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/mark_notifications_read.dart';
import '../../domain/usecases/watch_notifications.dart';
import 'notifications_state.dart';

/// The signed-in customer's notifications. Lives as long as the app and
/// follows the session through [bindUser].
///
/// Notifications that arrive while the app runs are passed to
/// [onNewNotification], which shows them as local notifications. Ones that
/// already existed when the user was bound (including ones the local cache
/// reports first) only appear in the list.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required WatchNotifications watchNotifications,
    required MarkNotificationsRead markNotificationsRead,
    this.onNewNotification,
    DateTime Function() clock = DateTime.now,
  })  : _watchNotifications = watchNotifications,
        _markNotificationsRead = markNotificationsRead,
        _clock = clock,
        super(const NotificationsState());

  /// Allows for small clock differences between the device and the server.
  static const Duration clockTolerance = Duration(minutes: 2);

  final WatchNotifications _watchNotifications;
  final MarkNotificationsRead _markNotificationsRead;
  final DateTime Function() _clock;
  final void Function(AppNotification notification)? onNewNotification;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _uid;
  DateTime? _boundAt;
  final Set<String> _seenIds = {};

  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _seenIds.clear();
    if (uid == null) {
      emit(const NotificationsState());
      return;
    }
    _boundAt = _clock();
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    emit(const NotificationsState(status: NotificationsStatus.loading));
    _subscription = _watchNotifications(uid).listen(
      _onNotifications,
      onError: (Object error) {
        // Errors that arrive while signing out are expected and ignored.
        if (_uid == null) return;
        emit(NotificationsState(
          status: NotificationsStatus.failure,
          notifications: state.notifications,
          message: error is Failure
              ? error.message
              : 'Could not load your notifications. Please try again.',
        ));
      },
    );
  }

  void _onNotifications(List<AppNotification> notifications) {
    final since = _boundAt!.subtract(clockTolerance);
    for (final n in notifications) {
      if (!_seenIds.add(n.id) || n.isRead) continue;
      final createdAt = n.createdAt;
      if (createdAt != null && createdAt.isAfter(since)) {
        onNewNotification?.call(n);
      }
    }
    emit(NotificationsState(
      status: NotificationsStatus.success,
      notifications: notifications,
    ));
  }

  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _subscription?.cancel();
    _subscribe(uid);
  }

  Future<void> markRead(String id) => _markRead([id]);

  Future<void> markAllRead() => _markRead([
        for (final n in state.notifications)
          if (!n.isRead) n.id,
      ]);

  Future<void> _markRead(List<String> ids) async {
    // Ids not loaded yet (e.g. a tap that launched the app) are sent too.
    final unread = ids
        .where((id) => !state.notifications.any((n) => n.id == id && n.isRead))
        .toList();
    if (unread.isEmpty || _uid == null) return;
    try {
      await _markNotificationsRead(unread);
    } catch (_) {
      // Not worth interrupting the user: the badge simply stays.
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
