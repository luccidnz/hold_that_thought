import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/notes/note_data.dart';
import 'package:hold_that_thought/routing/app_router.dart';

class CapturePage extends StatelessWidget {
  const CapturePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hold That Thought'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.go(AppRoutes.list()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings()),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Capture Page'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final data = CreateNoteData(title: 'From Capture Page');
                context.go(AppRoutes.create(), extra: data);
              },
              child: const Text('Create Note with extra'),
            ),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.note('123')),
              child: const Text('View Note 123'),
            ),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.list(tag: 'important')),
              child: const Text('View Important Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
