import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';
import 'package:hold_that_thought/routing/app_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notFoundTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.notFoundBody),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home()),
              child: Text(l10n.goHomeButton),
            ),
          ],
        ),
      ),
    );
  }
}
