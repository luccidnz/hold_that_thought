import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/routing/test_app_harness.dart';

import '../fakes/stub_notes_repository.dart';

void main() {
  testWidgets('valid id shows detail page', (tester) async {
    final stubRepo = StubNotesRepository(existsResult: true);

    await tester.pumpWidget(
      TestApp(
        initialLocation: '/note/abc123',
        notesRepository: stubRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Note Detail'), findsOneWidget);
  });

  testWidgets('invalid id shows NotFound', (tester) async {
    final stubRepo = StubNotesRepository(existsResult: false);

    await tester.pumpWidget(
      TestApp(
        initialLocation: '/note/bad-id',
        notesRepository: stubRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page Not Found'), findsOneWidget);
  });
}
