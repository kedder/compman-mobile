import 'package:flutter/material.dart';

void main() {
  runApp(const CompmanApp());
}

class CompmanApp extends StatelessWidget {
  const CompmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Compman Mobile',
      home: HelloScreen(),
    );
  }
}

class HelloScreen extends StatelessWidget {
  const HelloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compman Mobile')),
      body: const Center(
        child: Text('Hello, World!'),
      ),
    );
  }
}
