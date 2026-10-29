import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../cubit/auth_form_cubit.dart';
import '../cubit/auth_form_state.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthFormCubit>().resetPassword(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'Reset password',
      subtitle: "Enter your email and we'll send you a reset link.",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            BlocBuilder<AuthFormCubit, AuthFormState>(
              buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
              builder: (context, state) => LoadingButton(
                label: 'Send reset link',
                isLoading: state.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
