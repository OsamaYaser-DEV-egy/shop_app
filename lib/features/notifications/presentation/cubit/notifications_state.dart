import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

enum NotificationsStatus {
  /// No customer is signed in.
  signedOut,
  loading,
  success,
  failure,
}

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.signedOut,
    this.notifications = const [],
    this.message,
  });

  final NotificationsStatus status;

  /// Newest first.
  final List<AppNotification> notifications;
  final String? message;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [status, notifications, message];
}
