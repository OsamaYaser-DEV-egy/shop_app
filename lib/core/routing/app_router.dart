import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_order_details_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/cubit/session_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/session_problem_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/orders/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/my_orders_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/order_success_page.dart';
import '../../features/products/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/error_view.dart';
import '../widgets/splash_page.dart';
import 'go_router_refresh_stream.dart';
import 'route_names.dart';

/// Builds the app router. All auth-driven navigation lives in [redirect];
/// login and register screens never navigate after success.
abstract final class AppRouter {
  static GoRouter create(SessionCubit session) {
    return GoRouter(
      initialLocation: RoutePaths.splash,
      refreshListenable: GoRouterRefreshStream(session.stream),
      redirect: (context, state) => redirect(session.state, state.matchedLocation),
      errorBuilder: (context, state) => const Scaffold(
        body: SafeArea(child: ErrorView(message: 'Page not found.')),
      ),
      routes: [
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: RoutePaths.register,
          name: RouteNames.register,
          builder: (_, __) => const RegisterPage(),
        ),
        GoRoute(
          path: RoutePaths.forgotPassword,
          name: RouteNames.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: RoutePaths.sessionProblem,
          name: RouteNames.sessionProblem,
          builder: (_, __) => const SessionProblemPage(),
        ),
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          builder: (_, __) => const HomePage(),
          routes: [
            GoRoute(
              path: 'orders',
              name: RouteNames.myOrders,
              builder: (_, __) => const MyOrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: RouteNames.orderDetails,
                  builder: (_, state) =>
                      OrderDetailsPage(orderId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.checkout,
          name: RouteNames.checkout,
          builder: (_, __) => const CheckoutPage(),
        ),
        GoRoute(
          path: RoutePaths.orderSuccess,
          name: RouteNames.orderSuccess,
          builder: (_, state) =>
              OrderSuccessPage(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: RouteNames.profile,
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: RoutePaths.productDetails,
          name: RouteNames.productDetails,
          builder: (_, state) =>
              ProductDetailsPage(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: RoutePaths.cart,
          name: RouteNames.cart,
          builder: (_, __) => const CartPage(),
        ),
        GoRoute(
          path: RoutePaths.favorites,
          name: RouteNames.favorites,
          builder: (_, __) => const FavoritesPage(),
        ),
        GoRoute(
          path: RoutePaths.adminDashboard,
          name: RouteNames.adminDashboard,
          builder: (_, __) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: RoutePaths.adminProducts,
          name: RouteNames.adminProducts,
          builder: (_, __) => const AdminProductsPage(),
        ),
        GoRoute(
          path: RoutePaths.adminProductNew,
          name: RouteNames.adminProductNew,
          builder: (_, __) => const ProductFormPage(),
        ),
        GoRoute(
          path: RoutePaths.adminProductEdit,
          name: RouteNames.adminProductEdit,
          builder: (_, state) =>
              ProductFormPage(productId: state.pathParameters['id']),
        ),
        GoRoute(
          path: RoutePaths.adminOrders,
          name: RouteNames.adminOrders,
          builder: (_, __) => const AdminOrdersPage(),
        ),
        GoRoute(
          path: RoutePaths.adminOrderDetails,
          name: RouteNames.adminOrderDetails,
          builder: (_, state) =>
              AdminOrderDetailsPage(orderId: state.pathParameters['id']!),
        ),
      ],
    );
  }

  /// Pure function so it can be unit tested. Returns null to stay put.
  ///
  /// Every branch returns a location that its own branch maps to null, so
  /// redirect loops are impossible.
  static String? redirect(SessionState state, String location) {
    final isPublic = RoutePaths.public.contains(location);
    final isAdminArea = location.startsWith(RoutePaths.adminDashboard);

    switch (state.status) {
      case SessionStatus.loading:
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      case SessionStatus.unauthenticated:
        return isPublic ? null : RoutePaths.login;
      case SessionStatus.customer:
        final isGate = isPublic ||
            location == RoutePaths.splash ||
            location == RoutePaths.sessionProblem;
        return (isGate || isAdminArea) ? RoutePaths.home : null;
      case SessionStatus.admin:
        final isGate = isPublic ||
            location == RoutePaths.splash ||
            location == RoutePaths.sessionProblem;
        return (isGate || !isAdminArea) ? RoutePaths.adminDashboard : null;
      case SessionStatus.profileMissing:
      case SessionStatus.error:
        return location == RoutePaths.sessionProblem
            ? null
            : RoutePaths.sessionProblem;
    }
  }
}
