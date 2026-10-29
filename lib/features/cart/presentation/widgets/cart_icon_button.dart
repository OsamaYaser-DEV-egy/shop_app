import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// App bar button that opens the cart and shows how many units it holds.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.itemCount,
      builder: (context, count) => IconButton(
        tooltip: 'Cart',
        onPressed: () => context.pushNamed(RouteNames.cart),
        icon: Badge(
          isLabelVisible: count > 0,
          backgroundColor: AppColors.primary,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
      ),
    );
  }
}
