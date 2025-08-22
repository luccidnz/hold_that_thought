import 'package:flutter/material.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.noteDetailTitle),
      ),
      body: Center(
        child: Text(l10n.noteDetailId(id)),
      ),
    );
  }
}
