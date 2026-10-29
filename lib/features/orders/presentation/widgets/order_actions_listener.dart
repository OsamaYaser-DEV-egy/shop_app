import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_messenger.dart';
import '../cubit/order_actions_cubit.dart';
import '../cubit/order_actions_state.dart';

/// Shows the result of an order action as a snackbar.
class OrderActionsListener extends StatelessWidget {
  const OrderActionsListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderActionsCubit, OrderActionsState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == OrderActionsStatus.success) {
          AppMessenger.showSuccess(state.message ?? 'Done.');
        } else if (state.status == OrderActionsStatus.failure) {
          AppMessenger.showError(state.message ?? 'Something went wrong.');
        }
      },
      child: child,
    );
  }
}
