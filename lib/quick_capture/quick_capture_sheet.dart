import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/routing/app_router.dart';

class QuickCaptureSheet extends ConsumerStatefulWidget {
  const QuickCaptureSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<QuickCaptureSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _bodyFocusNode = FocusNode();
  bool _isPinned = false;
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Capture context-dependent objects before async gaps.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notesRepository = ref.read(notesRepositoryProvider);

    final title = _titleController.text;
    final body = _bodyController.text;

    try {
      final newNote = await notesRepository.create(
        title: title,
        body: body,
        isPinned: _isPinned,
      );

      HapticFeedback.lightImpact();
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(l10n.noteSaved),
              const Spacer(),
              TextButton(
                onPressed: () {
                  notesRepository.delete(newNote.id);
                  messenger.hideCurrentSnackBar();
                },
                child: Text(l10n.undo),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // The context here is from the SnackBar's builder, which is valid.
                  context.go(AppRoutes.note(newNote.id));
                  messenger.hideCurrentSnackBar();
                },
                child: Text(l10n.view),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      log('Failed to save note', error: e, stackTrace: st);
      setState(() {
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event.isControlPressed || event.isMetaPressed) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _save();
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorText != null)
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.titleHint,
                border: InputBorder.none,
              ),
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_bodyFocusNode);
              },
            ),
            TextField(
              controller: _bodyController,
              focusNode: _bodyFocusNode,
              decoration: InputDecoration(
                hintText: l10n.bodyHint,
                border: InputBorder.none,
              ),
              maxLines: 5,
              minLines: 1,
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isPinned ? Icons.star : Icons.star_border),
                  onPressed: () {
                    setState(() {
                      _isPinned = !_isPinned;
                    });
                  },
                  tooltip: l10n.pinButtonTooltip,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, child) {
                    return FilledButton(
                      onPressed: value.text.isNotEmpty ? _save : null,
                      child: Text(l10n.save),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
