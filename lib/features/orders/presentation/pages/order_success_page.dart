import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Shown after an order is placed. It replaces the checkout stack, so back
/// leads to the home screen instead of the (now empty) cart.
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.orderId});

  final String orderId;

  String get _reference =>
      '#${(orderId.length > 8 ? orderId.substring(0, 8) : orderId).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goNamed(RouteNames.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 88,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Order placed!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order $_reference',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We will confirm it soon. Pay in cash when it arrives.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.goNamed(
                      RouteNames.orderDetails,
                      pathParameters: {'id': orderId},
                    ),
                    child: const Text('View order'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.goNamed(RouteNames.home),
                    child: const Text('Continue shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
