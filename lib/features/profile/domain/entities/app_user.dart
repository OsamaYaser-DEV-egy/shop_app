import 'package:equatable/equatable.dart';

import 'user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [uid, name, email, phone, address, role];
}
