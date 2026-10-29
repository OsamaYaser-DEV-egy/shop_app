import 'dart:async';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Stream<AppUser?> watchProfile(String uid) {
    return _remote.watchProfile(uid).transform(
          StreamTransformer<AppUser?, AppUser?>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(ErrorMapper.map(error), stackTrace),
          ),
        );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      await _remote.updateProfile(
        uid: uid,
        name: name,
        phone: phone,
        address: address,
      );
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> createCustomerProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _remote.createCustomerProfile(uid: uid, name: name, email: email);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
