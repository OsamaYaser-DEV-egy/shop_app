import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';
import 'order_status_chip.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final createdAt = order.createdAt;
    final count = order.itemCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.reference}',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt == null
                          ? 'Just now'
                          : Formatters.dateTime(createdAt),
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'item' : 'items'}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OrderStatusChip(status: order.status),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.price(order.totalPrice),
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
