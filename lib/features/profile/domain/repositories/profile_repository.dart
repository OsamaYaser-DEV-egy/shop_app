import '../entities/app_user.dart';

abstract interface class ProfileRepository {
  /// Emits the profile for [uid], or null while the document does not exist.
  /// Emits a [Failure] error if the document is malformed or unreadable.
  Stream<AppUser?> watchProfile(String uid);

  /// Updates only name, phone and address. Role and email can never change
  /// from the client.
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  });

  /// Creates the profile document with the `customer` role.
  Future<void> createCustomerProfile({
    required String uid,
    required String name,
    required String email,
  });
}
