import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/presentation/cubit/admin_orders_cubit.dart';
import '../../../orders/presentation/cubit/admin_orders_state.dart';
import '../../../orders/presentation/widgets/order_tile.dart';

/// All incoming orders, newest first, filterable by status.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminOrdersCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: SafeArea(
          child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
            builder: (context, state) {
              switch (state.status) {
                case AdminOrdersStatus.loading:
                  return const LoadingView();
                case AdminOrdersStatus.failure:
                  return ErrorView(
                    message: state.message ?? 'Could not load orders.',
                    onRetry: context.read<AdminOrdersCubit>().retry,
                  );
                case AdminOrdersStatus.success:
                  return Column(
                    children: [
                      _StatusFilter(state: state),
                      Expanded(child: _OrderList(state: state)),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.state});

  final AdminOrdersState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();
    Widget chip(String label, OrderStatus? status) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: state.filter == status,
            onSelected: (_) => cubit.setFilter(status),
          ),
        );

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
        children: [
          chip('All (${state.orders.length})', null),
          for (final status in OrderStatus.values)
            chip('${status.label} (${state.countOf(status)})', status),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.state});

  final AdminOrdersState state;

  @override
  Widget build(BuildContext context) {
    final orders = state.visible;
    if (orders.isEmpty) {
      final filter = state.filter;
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: filter == null
            ? 'No orders yet'
            : 'No ${filter.label.toLowerCase()} orders',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderTile(
          order: order,
          showCustomer: true,
          onTap: () => context.pushNamed(
            RouteNames.adminOrderDetails,
            pathParameters: {'id': order.id},
          ),
        );
      },
    );
  }
}
