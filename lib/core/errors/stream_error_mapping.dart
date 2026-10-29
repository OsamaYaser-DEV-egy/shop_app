import 'dart:async';

import 'error_mapper.dart';

extension MapStreamErrors<T> on Stream<T> {
  /// Converts every error on this stream into a user-safe `Failure`.
  Stream<T> mapErrors() {
    return transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.addError(ErrorMapper.map(error), stackTrace),
      ),
    );
  }
}
