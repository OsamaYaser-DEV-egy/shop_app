import 'package:equatable/equatable.dart';

/// A domain-level error with a message that is safe to show to the user.
class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.code});

  final String message;

  /// Optional machine-readable code, e.g. `out-of-stock`.
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure($code): $message';
}
