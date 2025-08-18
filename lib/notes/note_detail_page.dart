import 'package:flutter/material.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Detail'),
      ),
      body: Center(
        child: Text('Note ID: $id'),
      ),
    );
  }
}
