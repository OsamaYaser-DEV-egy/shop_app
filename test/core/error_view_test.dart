import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/core/widgets/error_view.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorView', () {
    testWidgets('shows the message without a retry button by default',
        (tester) async {
      await tester.pumpWidget(_host(const ErrorView(message: 'Boom.')));

      expect(find.text('Boom.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('calls onRetry when the retry button is tapped',
        (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(ErrorView(message: 'Boom.', onRetry: () => retries++)),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, 1);
    });
  });
}
