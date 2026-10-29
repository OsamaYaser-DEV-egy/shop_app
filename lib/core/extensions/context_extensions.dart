import 'package:flutter/material.dart';

import '../utils/app_messenger.dart';

extension ContextX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  void showSuccess(String message) => AppMessenger.showSuccess(message);

  void showError(String message) => AppMessenger.showError(message);
}
