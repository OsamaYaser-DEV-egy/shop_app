import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/order.dart';
import '../cubit/order_actions_cubit.dart';
import '../cubit/order_actions_state.dart';
import '../cubit/order_details_cubit.dart';
import '../cubit/order_details_state.dart';
import '../widgets/order_actions_listener.dart';
import '../widgets/order_details_view.dart';

/// Customer view of one order. Updates live when the store changes the
/// status; a pending order can be cancelled here.
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});

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
          appBar: AppBar(title: const Text('Order details')),
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
                      actions: [
                        if (order.status.canBeCancelledByCustomer)
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

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.order});

  final Order order;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel this order?',
      message: 'The store has not confirmed it yet, so you can still cancel.',
      confirmLabel: 'Cancel order',
      cancelLabel: 'Keep order',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<OrderActionsCubit>().cancel(order, byStore: false);
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
