import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/presentation/cubit/order_actions_cubit.dart';
import '../../../orders/presentation/cubit/order_actions_state.dart';
import '../../../orders/presentation/cubit/order_details_cubit.dart';
import '../../../orders/presentation/cubit/order_details_state.dart';
import '../../../orders/presentation/widgets/order_actions_listener.dart';
import '../../../orders/presentation/widgets/order_details_view.dart';

/// Admin view of one order: customer, items, delivery details, and the
/// next status change or cancellation allowed by the business rules.
class AdminOrderDetailsPage extends StatelessWidget {
  const AdminOrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<OrderDetailsCubit>(param1: orderId)),
        BlocProvider(create: (_) => sl<OrderActionsCubit>()),
      ],
      child: OrderActionsListener(
        child: Scaffold(
          appBar: AppBar(title: const Text('Order')),
          body: SafeArea(
            child: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
              builder: (context, state) {
                switch (state.status) {
                  case OrderDetailsStatus.loading:
                    return const LoadingView();
                  case OrderDetailsStatus.notFound:
                    return const EmptyView(
                      icon: Icons.search_off,
                      title: 'Order not found',
                    );
                  case OrderDetailsStatus.failure:
                    return ErrorView(
                      message: state.message ?? 'Could not load this order.',
                      onRetry: context.read<OrderDetailsCubit>().retry,
                    );
                  case OrderDetailsStatus.success:
                    final order = state.order!;
                    return OrderDetailsView(
                      order: order,
                      showCustomer: true,
                      actions: [
                        if (order.status.next != null)
                          _AdvanceButton(order: order),
                        if (order.status.canBeCancelledByStore)
                          _CancelButton(order: order),
                      ],
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvanceButton extends StatelessWidget {
  const _AdvanceButton({required this.order});

  final Order order;

  static IconData _iconFor(OrderStatus status) => switch (status) {
        OrderStatus.confirmed => Icons.thumb_up_alt_outlined,
        OrderStatus.preparing => Icons.inventory_2_outlined,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.home_outlined,
        _ => Icons.arrow_forward,
      };

  Future<void> _confirm(BuildContext context, OrderStatus next) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark as ${next.label.toLowerCase()}?',
      message: 'Order ${order.reference} will move from '
          '${order.status.label.toLowerCase()} to ${next.label.toLowerCase()}. '
          'This cannot be undone.',
      confirmLabel: 'Mark as ${next.label.toLowerCase()}',
    );
    if (confirmed && context.mounted) {
      await context.read<OrderActionsCubit>().advance(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = order.status.next!;
    return BlocBuilder<OrderActionsCubit, OrderActionsState>(
      builder: (context, actions) => LoadingButton(
        label: 'Mark as ${next.label.toLowerCase()}',
        icon: _iconFor(next),
        isLoading: actions.isWorking,
        onPressed: () => _confirm(context, next),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.order});

  final Order order;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel this order?',
      message: 'Order ${order.reference} will be cancelled and its items '
          'returned to stock. This cannot be undone.',
      confirmLabel: 'Cancel order',
      cancelLabel: 'Keep order',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<OrderActionsCubit>().cancel(order, byStore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderActionsCubit, OrderActionsState>(
      builder: (context, actions) => OutlinedButton.icon(
        onPressed: actions.isWorking ? null : () => _confirm(context),
        icon: const Icon(Icons.close, color: AppColors.error),
        label: const Text('Cancel order'),
      ),
    );
  }
}
