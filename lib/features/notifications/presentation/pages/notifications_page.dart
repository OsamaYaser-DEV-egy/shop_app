import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/presentation/widgets/order_status_chip.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// In-app notification center: every order update, read or not.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: cubit.markAllRead,
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state, cubit)),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    NotificationsCubit cubit,
  ) {
    switch (state.status) {
      case NotificationsStatus.signedOut:
      case NotificationsStatus.loading:
        return const LoadingView();
      case NotificationsStatus.failure:
        return ErrorView(
          message: state.message ?? 'Could not load your notifications.',
          onRetry: cubit.retry,
        );
      case NotificationsStatus.success:
        if (state.notifications.isEmpty) {
          return const EmptyView(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            subtitle: 'Updates about your orders will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: state.notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            return _NotificationTile(
              notification: notification,
              onTap: () {
                cubit.markRead(notification.id);
                final orderId = notification.orderId;
                if (orderId != null) {
                  context.pushNamed(
                    RouteNames.orderDetails,
                    pathParameters: {'id': orderId},
                  );
                }
              },
            );
          },
        );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static IconData _iconFor(OrderStatus? status) => switch (status) {
        OrderStatus.confirmed => Icons.thumb_up_alt_outlined,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.home_outlined,
        OrderStatus.cancelled => Icons.cancel_outlined,
        _ => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = notification.orderStatus;
    final color = status == null
        ? AppColors.secondary
        : OrderStatusChip.colorOf(status);
    final createdAt = notification.createdAt;
    final unread = !notification.isRead;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(_iconFor(status), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(notification.body, style: textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      createdAt == null
                          ? 'Just now'
                          : Formatters.dateTime(createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
