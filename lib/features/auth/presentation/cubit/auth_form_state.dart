import 'package:equatable/equatable.dart';

enum AuthFormStatus { idle, submitting, success, failure }

class AuthFormState extends Equatable {
  const AuthFormState({this.status = AuthFormStatus.idle, this.message});

  final AuthFormStatus status;
  final String? message;

  bool get isSubmitting => status == AuthFormStatus.submitting;

  @override
  List<Object?> get props => [status, message];
}
