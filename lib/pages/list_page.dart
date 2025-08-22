import 'package:flutter/material.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key, this.tag});

  final String? tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listPageTitle)),
      body: Center(
        child: Text(
          tag == null ? l10n.listPageBody : l10n.listPageBodyFiltered(tag!),
        ),
      ),
    );
  }
}
