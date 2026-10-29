import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/core/errors/error_mapper.dart';
import 'package:shop_app/core/errors/failures.dart';

FirebaseException _firestore(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code, message: 'raw');

void main() {
  test('keeps Failures as they are', () {
    const failure = Failure('Only 2 left in stock.', code: 'out-of-stock');
    expect(ErrorMapper.map(failure), same(failure));
  });

  test('never shows raw backend messages', () {
    for (final code in ['permission-denied', 'internal', 'weird']) {
      expect(ErrorMapper.map(_firestore(code)).message, isNot(contains('raw')));
    }
  });

  test('maps common Firestore errors to friendly codes', () {
    expect(ErrorMapper.map(_firestore('permission-denied')).code,
        'permission-denied');
    expect(ErrorMapper.map(_firestore('unavailable')).code, 'network');
    expect(ErrorMapper.map(_firestore('deadline-exceeded')).code, 'network');
    expect(ErrorMapper.map(_firestore('resource-exhausted')).code,
        'quota-exceeded');
    expect(ErrorMapper.map(_firestore('aborted')).code, 'aborted');
  });

  test('maps sign-in errors without revealing which part was wrong', () {
    for (final code in ['user-not-found', 'wrong-password', 'invalid-credential']) {
      final failure = ErrorMapper.map(FirebaseAuthException(code: code));
      expect(failure.message, 'Incorrect email or password.');
    }
  });

  test('timeouts and unknown errors get generic messages', () {
    expect(ErrorMapper.map(TimeoutException('slow')).code, 'network');
    expect(
      ErrorMapper.map(StateError('bug')).message,
      'Something went wrong. Please try again.',
    );
  });
}
