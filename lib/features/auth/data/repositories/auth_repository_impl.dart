import 'dart:async';

import '../../../../core/errors/error_mapper.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required ProfileRemoteDataSource profileDataSource,
  })  : _auth = authDataSource,
        _profiles = profileDataSource;

  final AuthRemoteDataSource _auth;
  final ProfileRemoteDataSource _profiles;

  @override
  Stream<String?> watchAuthUid() {
    return _auth.watchUid().transform(
          StreamTransformer<String?, String?>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(ErrorMapper.map(error), stackTrace),
          ),
        );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signIn(email: email, password: password);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final uid = await _auth.createAccount(email: email, password: password);
      try {
        await _profiles.createCustomerProfile(uid: uid, name: name, email: email);
      } catch (_) {
        // Do not leave an account without a profile behind.
        await _auth.deleteCurrentUserQuietly();
        rethrow;
      }
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordReset(email);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
