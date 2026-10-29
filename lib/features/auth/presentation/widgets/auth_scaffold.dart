import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared layout for login, register and password reset: soft background
/// glow, brand mark, title, and a scrollable, keyboard-safe content area.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: showBack ? AppBar(backgroundColor: Colors.transparent) : null,
      extendBodyBehindAppBar: showBack,
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: AppColors.primary, size: 320),
          ),
          const Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: AppColors.secondary, size: 320),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(title, style: textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
