import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/order.dart';
import '../cubit/order_details_cubit.dart';
import '../cubit/order_details_state.dart';
import '../widgets/order_status_chip.dart';

/// One order with its items at purchase time and delivery details. Updates
/// live when the store changes the status.
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailsCubit>(param1: orderId),
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
                  return _OrderDetailsBody(order: state.order!);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsBody extends StatelessWidget {
  const _OrderDetailsBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final createdAt = order.createdAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Order ${order.reference}', style: textTheme.titleLarge),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          createdAt == null
              ? 'Placed just now'
              : 'Placed ${Formatters.dateTime(createdAt)}',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('Items', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: textTheme.bodyMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity} × ${Formatters.price(item.price)}',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Formatters.price(item.total),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('Total', style: textTheme.titleMedium)),
                      Text(
                        Formatters.price(order.totalPrice),
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Delivery', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(order.shippingAddress),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(order.phone),
              ),
              const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Cash on delivery'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
