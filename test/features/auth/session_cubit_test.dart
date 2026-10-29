import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_app/core/errors/failures.dart';
import 'package:shop_app/features/auth/domain/usecases/sign_out.dart';
import 'package:shop_app/features/auth/domain/usecases/watch_auth_uid.dart';
import 'package:shop_app/features/auth/presentation/cubit/session_cubit.dart';
import 'package:shop_app/features/auth/presentation/cubit/session_state.dart';
import 'package:shop_app/features/profile/domain/entities/app_user.dart';
import 'package:shop_app/features/profile/domain/entities/user_role.dart';
import 'package:shop_app/features/profile/domain/usecases/watch_profile.dart';

class _MockWatchAuthUid extends Mock implements WatchAuthUid {}

class _MockWatchProfile extends Mock implements WatchProfile {}

class _MockSignOut extends Mock implements SignOut {}

AppUser _user(UserRole role) => AppUser(
      uid: 'u1',
      name: 'Sam',
      email: 'sam@example.com',
      phone: '',
      address: '',
      role: role,
    );

void main() {
  late StreamController<String?> authController;
  late StreamController<AppUser?> profileController;
  late _MockWatchAuthUid watchAuthUid;
  late _MockWatchProfile watchProfile;
  late _MockSignOut signOut;

  SessionCubit buildCubit({Duration grace = const Duration(milliseconds: 30)}) {
    return SessionCubit(
      watchAuthUid: watchAuthUid,
      watchProfile: watchProfile,
      signOut: signOut,
      missingProfileGrace: grace,
    )..start();
  }

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    authController = StreamController<String?>.broadcast();
    profileController = StreamController<AppUser?>.broadcast();
    watchAuthUid = _MockWatchAuthUid();
    watchProfile = _MockWatchProfile();
    signOut = _MockSignOut();
    when(() => watchAuthUid()).thenAnswer((_) => authController.stream);
    when(() => watchProfile('u1')).thenAnswer((_) => profileController.stream);
    when(() => signOut()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authController.close();
    await profileController.close();
  });

  test('starts in loading', () async {
    final cubit = buildCubit();
    expect(cubit.state.status, SessionStatus.loading);
    await cubit.close();
  });

  test('signed-out user becomes unauthenticated', () async {
    final cubit = buildCubit();
    authController.add(null);
    await pump();
    expect(cubit.state.status, SessionStatus.unauthenticated);
    await cubit.close();
  });

  test('customer profile resolves to customer', () async {
    final cubit = buildCubit();
    authController.add('u1');
    await pump();
    expect(cubit.state.status, SessionStatus.loading);
    profileController.add(_user(UserRole.customer));
    await pump();
    expect(cubit.state.status, SessionStatus.customer);
    expect(cubit.state.user?.uid, 'u1');
    await cubit.close();
  });

  test('admin profile resolves to admin', () async {
    final cubit = buildCubit();
    authController.add('u1');
    await pump();
    profileController.add(_user(UserRole.admin));
    await pump();
    expect(cubit.state.status, SessionStatus.admin);
    await cubit.close();
  });

  test('missing profile waits for the grace period, then reports missing',
      () async {
    final cubit = buildCubit();
    authController.add('u1');
    await pump();
    profileController.add(null);
    await pump();
    expect(cubit.state.status, SessionStatus.loading);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(cubit.state.status, SessionStatus.profileMissing);
    await cubit.close();
  });

  test('profile arriving inside the grace period avoids profileMissing',
      () async {
    final cubit = buildCubit(grace: const Duration(milliseconds: 80));
    authController.add('u1');
    await pump();
    profileController.add(null);
    await pump();
    profileController.add(_user(UserRole.customer));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(cubit.state.status, SessionStatus.customer);
    await cubit.close();
  });

  test('invalid profile surfaces an error and grants no role', () async {
    final cubit = buildCubit();
    authController.add('u1');
    await pump();
    profileController.addError(const Failure('Invalid profile'));
    await pump();
    expect(cubit.state.status, SessionStatus.error);
    expect(cubit.state.message, 'Invalid profile');
    expect(cubit.state.user, isNull);
    await cubit.close();
  });

  test('signing out returns to unauthenticated', () async {
    final cubit = buildCubit();
    authController.add('u1');
    await pump();
    profileController.add(_user(UserRole.customer));
    await pump();
    authController.add(null);
    await pump();
    expect(cubit.state.status, SessionStatus.unauthenticated);
    expect(cubit.state.user, isNull);
    await cubit.close();
  });
}
