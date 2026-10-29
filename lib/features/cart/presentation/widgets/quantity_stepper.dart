import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Compact "− 2 +" control. A null callback disables that side.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    // Swallows taps on the stepper (including a disabled button), so they
    // never reach a tappable parent such as the cart line card.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _buildStepper(),
    );
  }

  Widget _buildStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.remove),
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
