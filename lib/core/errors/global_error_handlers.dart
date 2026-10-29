import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Last line of defence for errors no screen handled.
///
/// Expected failures (network, permissions, validation) are already turned
/// into friendly messages by ErrorMapper and shown by each screen. This only
/// catches bugs: they are logged instead of crashing silently, and in
/// release builds a broken widget shows a short message instead of a grey
/// box. There is no crash-reporting service (none is configured).
void installGlobalErrorHandlers() {
  // Errors thrown while building, laying out or painting widgets.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Uncaught errors from async code (futures, streams, platform channels).
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const _BrokenWidget();
  }
}

class _BrokenWidget extends StatelessWidget {
  const _BrokenWidget();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Something went wrong while showing this part of the screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
