import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';
import 'order_status_chip.dart';

/// Order header, items at purchase time, total and delivery details.
/// Shared by the customer and admin order pages.
class OrderDetailsView extends StatelessWidget {
  const OrderDetailsView({
    super.key,
    required this.order,
    this.showCustomer = false,
    this.actions = const [],
  });

  final Order order;

  /// Admin view: shows who placed the order.
  final bool showCustomer;

  /// Buttons shown under the details (status changes, cancel).
  final List<Widget> actions;

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
        if (showCustomer) ...[
          const SizedBox(height: 20),
          Text('Customer', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                order.customerName.isEmpty ? 'Unknown' : order.customerName,
              ),
              subtitle: Text(order.customerEmail),
            ),
          ),
        ],
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
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            actions[i],
          ],
        ],
      ],
    );
  }
}
