import 'package:flutter/material.dart';
import 'package:hold_that_thought/screens/home_screen.dart';

class HoldThatThoughtApp extends StatelessWidget {
  const HoldThatThoughtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hold That Thought',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
