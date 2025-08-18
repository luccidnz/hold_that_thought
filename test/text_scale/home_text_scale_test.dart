import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/pages/capture_page.dart';

void main() {
  testWidgets('Home screen golden test with different text scales',
      (WidgetTester tester) async {
    // Test at 1.0x text scale
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CapturePage(),
        ),
      ),
    );
    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('goldens/home_1x.png'),
    );

    // Test at 2.0x text scale
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaleFactor: 2.0),
            child: CapturePage(),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('goldens/home_2x.png'),
    );
  });
}
