import 'dart:async';

import 'package:flutter/foundation.dart';

/// Makes GoRouter re-run its `redirect` whenever [stream] emits.
/// Used from Stage 2 with the auth state stream.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
