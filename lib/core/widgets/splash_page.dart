import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shown while Firebase / the auth state / the user profile is resolving.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_rounded, size: 72, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
