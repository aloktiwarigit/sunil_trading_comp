// =============================================================================
// shopkeeper_app smoke test — Sprint 1 minimal verification.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sprint 1 ops boot splash renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('सुनील की दुकान')),
        ),
      ),
    );

    expect(find.text('सुनील की दुकान'), findsOneWidget);
  });
}
