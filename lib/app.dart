import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_messenger.dart';
import 'features/auth/presentation/cubit/auth_form_cubit.dart';
import 'features/auth/presentation/cubit/auth_form_state.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: sl<SessionCubit>()),
        BlocProvider<AuthFormCubit>.value(value: sl<AuthFormCubit>()),
        BlocProvider<CartCubit>.value(value: sl<CartCubit>()),
        BlocProvider<FavoritesCubit>.value(value: sl<FavoritesCubit>()),
      ],
      // Auth feedback is shown globally because login/register pages are
      // replaced by the router as soon as the session changes.
      child: BlocListener<AuthFormCubit, AuthFormState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final message = state.message;
          if (message == null) return;
          if (state.status == AuthFormStatus.failure) {
            AppMessenger.showError(message);
          } else if (state.status == AuthFormStatus.success) {
            AppMessenger.showSuccess(message);
          }
        },
        child: MaterialApp.router(
          title: 'Shop',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: AppMessenger.key,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: sl<GoRouter>(),
        ),
      ),
    );
  }
}
