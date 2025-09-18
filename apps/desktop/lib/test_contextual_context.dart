import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/design_system.dart';
import 'features/chat/presentation/demo/contextual_context_demo.dart';

/// Simple test app to run the contextual context demo
void main() {
  runApp(const ProviderScope(child: TestApp()));
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contextual Context Test',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4ECDC4)),
      ),
      home: const TestHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contextual Context Test'),
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎯 Contextual Context Feature Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Click the button below to test the new context UX',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContextualContextDemo(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Open Contextual Context Demo',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}