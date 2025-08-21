import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/flavor.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hold_that_thought/main.dart';
import 'package:hold_that_thought/routing/app_router.dart';

Widget buildTestableWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      flavorProvider.overrideWithValue(Flavor.dev),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Widget buildTestableRouterWidget({
  required ProviderContainer container,
  List<Override> overrides = const [],
}) {
  final router = container.read(appRouterProvider);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}
