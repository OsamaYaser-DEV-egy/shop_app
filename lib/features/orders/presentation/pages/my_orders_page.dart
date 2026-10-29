import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/my_orders_cubit.dart';
import '../cubit/my_orders_state.dart';
import '../widgets/order_tile.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<SessionCubit>().state.user?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: SafeArea(
        child: uid == null
            ? const SizedBox.shrink()
            : BlocProvider(
                create: (_) => sl<MyOrdersCubit>(param1: uid),
                child: const _MyOrdersList(),
              ),
      ),
    );
  }
}

class _MyOrdersList extends StatelessWidget {
  const _MyOrdersList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyOrdersCubit, MyOrdersState>(
      builder: (context, state) {
        switch (state.status) {
          case MyOrdersStatus.loading:
            return const LoadingView();
          case MyOrdersStatus.failure:
            return ErrorView(
              message: state.message ?? 'Could not load your orders.',
              onRetry: context.read<MyOrdersCubit>().retry,
            );
          case MyOrdersStatus.success:
            if (state.orders.isEmpty) {
              return EmptyView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                subtitle: 'Orders you place will appear here.',
                action: OutlinedButton(
                  onPressed: () => context.goNamed(RouteNames.home),
                  child: const Text('Start shopping'),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return OrderTile(
                  order: order,
                  onTap: () => context.pushNamed(
                    RouteNames.orderDetails,
                    pathParameters: {'id': order.id},
                  ),
                );
              },
            );
        }
      },
    );
  }
}
