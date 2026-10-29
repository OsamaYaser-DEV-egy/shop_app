import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// App bar button that opens the notification list and shows unread ones.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotificationsCubit, NotificationsState, int>(
      selector: (state) => state.unreadCount,
      builder: (context, unread) => IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.pushNamed(RouteNames.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          backgroundColor: AppColors.error,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: const Icon(Icons.notifications_none),
        ),
      ),
    );
  }
}
