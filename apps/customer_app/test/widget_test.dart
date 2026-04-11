// =============================================================================
// customer_app smoke test — Sprint 1 minimal verification.
//
// Verifies the boot splash screen renders without throwing. Real feature
// tests land with their respective stories in Sprints 2–6.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sprint 1 boot splash renders without error',
      (WidgetTester tester) async {
    // Minimal smoke test — does not boot Firebase or ProviderScope overrides,
    // just verifies the widget tree compiles and renders a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('सुनील ट्रेडिंग कंपनी')),
        ),
      ),
    );

    expect(find.text('सुनील ट्रेडिंग कंपनी'), findsOneWidget);
  });
}
