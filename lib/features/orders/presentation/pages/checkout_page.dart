import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../cart/domain/entities/cart_summary.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../products/presentation/cubit/product_list_cubit.dart';
import '../../../products/presentation/cubit/product_list_state.dart';
import '../../domain/entities/order_request.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

/// Review the cart, confirm delivery details and place a Cash on Delivery
/// order.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Live prices and stock for the summary.
        BlocProvider(create: (_) => sl<ProductListCubit>()),
        BlocProvider(create: (_) => sl<CheckoutCubit>()),
      ],
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Prefilled from the profile; the customer may change them per order.
    final user = context.read<SessionCubit>().state.user;
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder(CartState cart, CartSummary summary) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<SessionCubit>().state.user;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    context.read<CheckoutCubit>().place(
          OrderRequest(
            userId: user.uid,
            customerName: user.name,
            customerEmail: user.email,
            shippingAddress: _addressController.text,
            phone: _phoneController.text,
            items: cart.items,
            expectedTotal: summary.subtotal,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        final orderId = state.orderId;
        if (state.status == CheckoutStatus.success && orderId != null) {
          context.goNamed(
            RouteNames.orderSuccess,
            pathParameters: {'id': orderId},
          );
        } else if (state.status == CheckoutStatus.failure) {
          AppMessenger.showError(state.message ?? 'Could not place your order.');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: SafeArea(
          child: BlocBuilder<CheckoutCubit, CheckoutState>(
            builder: (context, checkout) {
              // The cart empties as soon as the order is written; keep a
              // neutral screen until the router shows the success page.
              if (checkout.status == CheckoutStatus.success) {
                return const LoadingView();
              }
              return BlocBuilder<CartCubit, CartState>(
                builder: (context, cart) =>
                    BlocBuilder<ProductListCubit, ProductListState>(
                  builder: (context, catalog) =>
                      _buildBody(context, cart, catalog, checkout),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CartState cart,
    ProductListState catalog,
    CheckoutState checkout,
  ) {
    if (cart.status == CartStatus.failure) {
      return ErrorView(
        message: cart.message ?? 'Could not load your cart.',
        onRetry: context.read<CartCubit>().retry,
      );
    }
    if (catalog.status == ProductListStatus.failure) {
      return ErrorView(
        message: catalog.message ?? 'Could not load products.',
        onRetry: context.read<ProductListCubit>().retry,
      );
    }
    if (cart.status != CartStatus.success ||
        catalog.status != ProductListStatus.success) {
      return const LoadingView();
    }

    final summary = CartSummary.build(cart.items, catalog.products);
    if (summary.isEmpty) {
      return EmptyView(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        action: OutlinedButton(
          onPressed: () => context.goNamed(RouteNames.home),
          child: const Text('Browse products'),
        ),
      );
    }
    if (summary.hasIssues ||
        summary.lines.length > OrderRequest.maxDistinctProducts) {
      return EmptyView(
        icon: Icons.warning_amber_rounded,
        title: 'Your cart needs attention',
        subtitle: summary.hasIssues
            ? 'Some items are unavailable or exceed the stock.'
            : 'You can order up to ${OrderRequest.maxDistinctProducts} '
                'different products at a time.',
        action: OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Back to cart'),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Delivery details', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          AppTextField(
            controller: _phoneController,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.phone(v, required: true),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _addressController,
            label: 'Delivery address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.newline,
            validator: (v) => Validators.address(v, required: true),
          ),
          const SizedBox(height: 24),
          Text('Items', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  for (final line in summary.lines)
                    _SummaryRow(
                      label: '${line.quantity} × ${line.product!.name}',
                      value: Formatters.price(line.total),
                    ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Total',
                    value: Formatters.price(summary.subtotal),
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Payment', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined, color: AppColors.success),
              title: Text('Cash on delivery'),
              subtitle: Text('Pay in cash when your order arrives.'),
            ),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Place order · ${Formatters.price(summary.subtotal)}',
            icon: Icons.check_circle_outline,
            isLoading: checkout.isPlacing,
            onPressed: () => _placeOrder(cart, summary),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock and prices are checked again when you place the order.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized ? textTheme.titleMedium : textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: emphasized
                ? textTheme.titleLarge?.copyWith(color: AppColors.secondary)
                : textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
