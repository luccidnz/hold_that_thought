import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/main.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/routing/app_router.dart';

class FakeNotesRepository implements NotesRepository {
  @override
  bool exists(String id) {
    return id == '123';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppRouter tests', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
      ],
    );
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Test initial route
    expect(find.text('Capture Page'), findsOneWidget);

    // Test navigation to a valid note
    router.go(AppRoutes.note('123'));
    await tester.pumpAndSettle();
    expect(find.text('Note ID: 123'), findsOneWidget);

    // Test navigation to an invalid note
    router.go(AppRoutes.note('zzz'));
    await tester.pumpAndSettle();
    expect(find.text('404 - Page Not Found'), findsOneWidget);

    // Test navigation with query parameters
    router.go(AppRoutes.list(tag: 'work'));
    await tester.pumpAndSettle();
    expect(find.text('List Page (Filtered by tag: work)'), findsOneWidget);
  });
}
