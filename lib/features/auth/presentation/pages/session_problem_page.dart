import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';

/// Shown when the user is signed in but the profile is missing, invalid,
/// or could not be loaded (including expired sessions). No privileges are
/// granted here; the user can retry or sign out.
class SessionProblemPage extends StatelessWidget {
  const SessionProblemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<SessionCubit, SessionState>(
                builder: (context, state) {
                  final isMissing = state.status == SessionStatus.profileMissing;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.manage_accounts_outlined,
                        size: 64,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isMissing ? 'Account setup incomplete' : 'Something went wrong',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message ?? 'Please try again.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () => context.read<SessionCubit>().retry(),
                        child: const Text('Try again'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.read<SessionCubit>().signOut(),
                        child: const Text('Sign out'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
