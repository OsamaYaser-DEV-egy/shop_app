import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/app_user.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().state.user;
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: SafeArea(
        child: user == null
            ? const SizedBox.shrink()
            : BlocProvider(
                create: (_) => sl<ProfileCubit>(),
                child: _ProfileForm(user: user),
              ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.user});

  final AppUser user;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().save(
          uid: widget.user.uid,
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to place orders.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<SessionCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.saved) {
          context.showSuccess(state.message ?? 'Saved.');
        } else if (state.status == ProfileStatus.failure) {
          context.showError(state.message ?? 'Could not save.');
        }
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Delivery address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.newline,
                validator: Validators.address,
              ),
              const SizedBox(height: 24),
              BlocBuilder<ProfileCubit, ProfileState>(
                buildWhen: (p, c) => p.isSaving != c.isSaving,
                builder: (context, state) => LoadingButton(
                  label: 'Save changes',
                  isLoading: state.isSaving,
                  onPressed: _save,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
