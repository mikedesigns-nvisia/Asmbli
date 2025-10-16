import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/design_system.dart';
import 'core/services/theme_service.dart';
import 'demo/demo_app.dart';
import 'demo/services/demo_mode_service.dart';

/// Demo-specific main entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize demo mode
  await DemoModeService.instance.initialize();

  runApp(const ProviderScope(child: DemoAppWrapper()));
}

class DemoAppWrapper extends ConsumerWidget {
  const DemoAppWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Asmbli Demo',
      theme: _buildTheme(),
      home: const DemoApp(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4ECDC4), // Asmbli primary color
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Inter',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        ),
        elevation: 2,
      ),
    );
  }
}