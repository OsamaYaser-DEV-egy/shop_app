/// Route names and paths. Add new routes here as features are built.
abstract final class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String sessionProblem = 'session-problem';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String productDetails = 'product-details';
  static const String cart = 'cart';
  static const String favorites = 'favorites';
  static const String checkout = 'checkout';
  static const String orderSuccess = 'order-success';
  static const String myOrders = 'my-orders';
  static const String orderDetails = 'order-details';
  static const String adminDashboard = 'admin-dashboard';
  static const String adminProducts = 'admin-products';
  static const String adminProductNew = 'admin-product-new';
  static const String adminProductEdit = 'admin-product-edit';
}

abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String sessionProblem = '/session-problem';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String productDetails = '/product/:id';
  static const String cart = '/cart';
  static const String favorites = '/favorites';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success/:id';

  /// Nested under home, so opening an order directly (e.g. from the success
  /// page or, later, a notification) still has Home and My orders behind it.
  static const String myOrders = '/home/orders';
  static const String orderDetails = '/home/orders/:id';

  /// Everything under this prefix is admin-only (see AppRouter.redirect).
  static const String adminDashboard = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminProductNew = '/admin/products/new';
  static const String adminProductEdit = '/admin/products/:id/edit';

  /// Pages a signed-out user may open.
  static const Set<String> public = {login, register, forgotPassword};
}
