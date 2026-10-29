import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../widgets/dashboard_tile.dart';

/// Admin landing page. Order management is added in Stage 6.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<SessionCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.read<SessionCubit>().state.user?.name ?? 'Admin';
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome, $name', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Manage your store.', style: textTheme.bodySmall),
            const SizedBox(height: 20),
            DashboardTile(
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              subtitle: 'Create, edit and delete products',
              onTap: () => context.pushNamed(RouteNames.adminProducts),
            ),
          ],
        ),
      ),
    );
  }
}
