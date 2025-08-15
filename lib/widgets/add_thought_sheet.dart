import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/providers/thought_providers.dart';

class AddThoughtSheet extends ConsumerStatefulWidget {
  const AddThoughtSheet({super.key});

  @override
  ConsumerState<AddThoughtSheet> createState() => _AddThoughtSheetState();
}

class _AddThoughtSheetState extends ConsumerState<AddThoughtSheet> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveThought() {
    if (_formKey.currentState!.validate()) {
      final text = _textController.text.trim();
      ref.read(thoughtRepositoryProvider).create(text);

      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thought saved!')),
      );

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Close the sheet
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              autofocus: true,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a thought.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveThought,
              child: const Text('Save Thought'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
