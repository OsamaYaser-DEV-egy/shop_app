import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/core/routing/app_router.dart';
import 'package:shop_app/core/routing/route_names.dart';
import 'package:shop_app/features/auth/presentation/cubit/session_state.dart';
import 'package:shop_app/features/profile/domain/entities/app_user.dart';
import 'package:shop_app/features/profile/domain/entities/user_role.dart';

AppUser _user(UserRole role) => AppUser(
  uid: 'u1',
  name: 'Sam',
  email: 'sam@example.com',
  phone: '',
  address: '',
  role: role,
);

void main() {
  group('AppRouter.redirect', () {
    test('loading goes to splash and stays there', () {
      const state = SessionState.loading();
      expect(AppRouter.redirect(state, RoutePaths.home), RoutePaths.splash);
      expect(AppRouter.redirect(state, RoutePaths.splash), isNull);
    });

    test('signed-out users are limited to public pages', () {
      const state = SessionState.unauthenticated();
      expect(AppRouter.redirect(state, RoutePaths.home), RoutePaths.login);
      expect(
        AppRouter.redirect(state, RoutePaths.adminDashboard),
        RoutePaths.login,
      );
      expect(AppRouter.redirect(state, RoutePaths.login), isNull);
      expect(AppRouter.redirect(state, RoutePaths.register), isNull);
      expect(AppRouter.redirect(state, RoutePaths.forgotPassword), isNull);
    });

    test('customers are kept out of auth pages and the admin area', () {
      final state = SessionState.authenticated(_user(UserRole.customer));
      expect(AppRouter.redirect(state, RoutePaths.login), RoutePaths.home);
      expect(AppRouter.redirect(state, RoutePaths.splash), RoutePaths.home);
      expect(
        AppRouter.redirect(state, RoutePaths.adminDashboard),
        RoutePaths.home,
      );
      expect(AppRouter.redirect(state, RoutePaths.home), isNull);
      expect(AppRouter.redirect(state, RoutePaths.profile), isNull);
      expect(AppRouter.redirect(state, RoutePaths.cart), isNull);
      expect(AppRouter.redirect(state, RoutePaths.favorites), isNull);
    });

    test('cart, checkout and orders are customer-only', () {
      final customer = SessionState.authenticated(_user(UserRole.customer));
      final admin = SessionState.authenticated(_user(UserRole.admin));
      const signedOut = SessionState.unauthenticated();
      for (final location in [
        RoutePaths.cart,
        RoutePaths.favorites,
        RoutePaths.checkout,
        RoutePaths.myOrders,
        '/home/orders/abc',
        '/order-success/abc',
      ]) {
        expect(AppRouter.redirect(customer, location), isNull);
        expect(AppRouter.redirect(admin, location), RoutePaths.adminDashboard);
        expect(AppRouter.redirect(signedOut, location), RoutePaths.login);
      }
    });

    test('admins are sent to the dashboard only', () {
      final state = SessionState.authenticated(_user(UserRole.admin));
      expect(
        AppRouter.redirect(state, RoutePaths.login),
        RoutePaths.adminDashboard,
      );
      expect(
        AppRouter.redirect(state, RoutePaths.home),
        RoutePaths.adminDashboard,
      );
      expect(AppRouter.redirect(state, RoutePaths.adminDashboard), isNull);
    });

    test(
      'missing or invalid profiles are sent to the session problem page',
      () {
        const missing = SessionState.profileMissing();
        const error = SessionState.error('x');
        for (final state in [missing, error]) {
          expect(
            AppRouter.redirect(state, RoutePaths.home),
            RoutePaths.sessionProblem,
          );
          expect(
            AppRouter.redirect(state, RoutePaths.adminDashboard),
            RoutePaths.sessionProblem,
          );
          expect(AppRouter.redirect(state, RoutePaths.sessionProblem), isNull);
        }
      },
    );

    test(
      'admin product screens are admin-only and product pages customer-only',
      () {
        final customer = SessionState.authenticated(_user(UserRole.customer));
        final admin = SessionState.authenticated(_user(UserRole.admin));
        const adminEdit = '/admin/products/abc/edit';
        const details = '/product/abc';

        expect(
          AppRouter.redirect(customer, RoutePaths.adminProducts),
          RoutePaths.home,
        );
        expect(AppRouter.redirect(customer, adminEdit), RoutePaths.home);
        expect(AppRouter.redirect(customer, details), isNull);

        expect(AppRouter.redirect(admin, RoutePaths.adminProducts), isNull);
        expect(AppRouter.redirect(admin, adminEdit), isNull);
        expect(AppRouter.redirect(admin, details), RoutePaths.adminDashboard);

        const signedOut = SessionState.unauthenticated();
        expect(AppRouter.redirect(signedOut, adminEdit), RoutePaths.login);
        expect(AppRouter.redirect(signedOut, details), RoutePaths.login);
      },
    );

    test('every redirect target is stable (no loops)', () {
      final states = <SessionState>[
        const SessionState.loading(),
        const SessionState.unauthenticated(),
        SessionState.authenticated(_user(UserRole.customer)),
        SessionState.authenticated(_user(UserRole.admin)),
        const SessionState.profileMissing(),
        const SessionState.error('x'),
      ];
      const locations = [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.forgotPassword,
        RoutePaths.sessionProblem,
        RoutePaths.home,
        RoutePaths.profile,
        RoutePaths.cart,
        RoutePaths.favorites,
        RoutePaths.adminDashboard,
      ];
      for (final state in states) {
        for (final location in locations) {
          final first = AppRouter.redirect(state, location);
          if (first != null) {
            expect(
              AppRouter.redirect(state, first),
              isNull,
              reason:
                  '${state.status} at $location redirected to $first, '
                  'which redirects again',
            );
          }
        }
      }
    });
  });
}
