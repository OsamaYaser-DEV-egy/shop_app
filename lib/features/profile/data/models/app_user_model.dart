import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// Serialization for `users/{uid}`.
abstract final class AppUserModel {
  /// Builds an [AppUser] from a Firestore document. Missing text fields
  /// default to empty strings. A missing or unknown role makes the profile
  /// invalid, so the user is never granted privileges by default.
  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    final role = UserRole.tryParse(data['role']);
    if (role == null) {
      throw const Failure(
        'Your account profile is invalid. Please contact support.',
        code: 'invalid-profile',
      );
    }
    return AppUser(
      uid: uid,
      name: _string(data['name']),
      email: _string(data['email']),
      phone: _string(data['phone']),
      address: _string(data['address']),
      role: role,
    );
  }

  /// Fields written when a new account registers. The role is always
  /// `customer`; Firestore rules reject anything else.
  static Map<String, dynamic> newCustomer({
    required String name,
    required String email,
  }) {
    return {
      'name': name,
      'email': email,
      'phone': '',
      'address': '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> profileUpdate({
    required String name,
    required String phone,
    required String address,
  }) {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String _string(Object? value) => value is String ? value : '';
}
