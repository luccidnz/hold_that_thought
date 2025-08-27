import 'package:flutter/material.dart';

class CapturePage extends StatelessWidget {
  const CapturePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hold That Thought')),
      body: const Center(child: Text('Capture Page')),
    );
  }
}
