import 'package:flutter_test/flutter_test.dart';

// Import the UI structure tests
import 'integration/ui_structure_test.dart' as ui_tests;

/// UI-focused test runner that doesn't require service initialization
/// 
/// This runner tests:
/// - Design system components (buttons, cards, etc.)
/// - Theme system (colors, typography)
/// - Spacing and layout tokens
/// - Interactive states
/// - Responsive design elements
/// 
/// These tests verify that your design system works correctly
/// without needing to mock complex backend services.
/// 
/// Run with: flutter test test/ui_test_runner.dart
void main() {
  group('Asmbli Desktop App - UI Component Tests', () {
    
    group('🎨 Design System Tests', () {
      ui_tests.main();
    });
  });
}