import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order_status.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  static Color colorOf(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.warning,
        OrderStatus.confirmed => AppColors.secondary,
        OrderStatus.preparing => AppColors.primary,
        OrderStatus.shipped => AppColors.secondary,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
