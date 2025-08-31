import 'package:flutter/material.dart';

InlineSpan highlightSpan(BuildContext ctx, String text, String query) {
  if (query.isEmpty) return TextSpan(text: text);
  final lcText = text.toLowerCase();
  final lcQ = query.toLowerCase();
  final spans = <TextSpan>[];
  int i = 0;
  while (true) {
    final idx = lcText.indexOf(lcQ, i);
    if (idx < 0) { spans.add(TextSpan(text: text.substring(i))); break; }
    if (idx > i) spans.add(TextSpan(text: text.substring(i, idx)));
    spans.add(TextSpan(
      text: text.substring(idx, idx + query.length),
      style: TextStyle(
        // withOpacity is deprecated; use withAlpha to avoid precision loss.
        backgroundColor: Theme.of(ctx).colorScheme.secondary.withAlpha((0.25 * 255).round()),
        fontWeight: FontWeight.w600,
      ),
    ));
    i = idx + query.length;
  }
  return TextSpan(children: spans);
}
