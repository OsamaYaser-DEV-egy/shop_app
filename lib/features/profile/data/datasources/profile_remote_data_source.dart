import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  Stream<AppUser?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUserModel.fromMap(snapshot.id, data);
    });
  }

  Future<void> createCustomerProfile({
    required String uid,
    required String name,
    required String email,
  }) {
    return _doc(uid).set(AppUserModel.newCustomer(name: name, email: email));
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) {
    return _doc(uid).update(
      AppUserModel.profileUpdate(name: name, phone: phone, address: address),
    );
  }
}
