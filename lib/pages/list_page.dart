import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({Key? key, this.tag}) : super(key: key);

  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thoughts')),
      body: Center(
        child: Text(
          tag == null ? 'List Page' : 'List Page (Filtered by tag: $tag)',
        ),
      ),
    );
  }
}
