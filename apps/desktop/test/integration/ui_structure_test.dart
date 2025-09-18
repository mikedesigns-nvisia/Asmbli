import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/core/design_system/design_system.dart';
import 'package:agentengine_desktop/core/design_system/components/asmbli_button.dart';
import 'package:agentengine_desktop/core/design_system/components/asmbli_card.dart';

void main() {
  group('UI Structure Tests', () {
    late SharedPreferences mockPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });

    testWidgets('Design system buttons render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                AsmblButton.primary(
                  text: 'Primary Button',
                  onPressed: () {},
                ),
                AsmblButton.secondary(
                  text: 'Secondary Button',
                  onPressed: () {},
                ),
                AsmblButton.outline(
                  text: 'Outline Button',
                  icon: Icons.add,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.text('Outline Button'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Design system cards render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                AsmblCard(
                  child: Text('Card Content'),
                ),
                AsmblCard(
                  onTap: () {},
                  child: Text('Clickable Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Clickable Card'), findsOneWidget);
      expect(find.byType(AsmblCard), findsNWidgets(2));
    });

    testWidgets('Theme colors system works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final colors = ThemeColors(context);
              return Scaffold(
                backgroundColor: colors.background,
                body: Container(
                  color: colors.surface,
                  child: Text(
                    'Themed Content',
                    style: TextStyle(color: colors.onSurface),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Themed Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('Typography system works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                Text('Page Title', style: TextStyles.pageTitle),
                Text('Section Title', style: TextStyles.sectionTitle),
                Text('Body Text', style: TextStyles.bodyMedium),
                Text('Caption Text', style: TextStyles.caption),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Page Title'), findsOneWidget);
      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Body Text'), findsOneWidget);
      expect(find.text('Caption Text'), findsOneWidget);
    });

    testWidgets('Spacing system is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
              child: Column(
                children: [
                  Container(height: 50, color: Colors.red),
                  SizedBox(height: SpacingTokens.sectionSpacing),
                  Container(height: 50, color: Colors.blue),
                  SizedBox(height: SpacingTokens.elementSpacing),
                  Container(height: 50, color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify spacing tokens are numbers and containers render
      expect(SpacingTokens.pageHorizontal, isA<double>());
      expect(SpacingTokens.sectionSpacing, isA<double>());
      expect(SpacingTokens.elementSpacing, isA<double>());
      expect(find.byType(Container), findsNWidgets(3));
    });

    testWidgets('Gradient backgrounds work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final colors = ThemeColors(context);
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colors.backgroundGradientStart,
                        colors.backgroundGradientMiddle,
                        colors.backgroundGradientEnd,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Gradient Background',
                      style: TextStyles.pageTitle.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Gradient Background'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<RadialGradient>());
    });

    testWidgets('Interactive states work on buttons', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: AsmblButton.primary(
              text: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(wasPressed, false);

      // Tap the button
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('Card tap interactions work', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: AsmblCard(
              onTap: () {
                wasTapped = true;
              },
              child: Text('Tappable Card'),
            ),
          ),
        ),
      );

      expect(find.text('Tappable Card'), findsOneWidget);
      expect(wasTapped, false);

      // Tap the card
      await tester.tap(find.text('Tappable Card'));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('Responsive design elements scale correctly', (WidgetTester tester) async {
      // Test at desktop size
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
              child: Row(
                children: [
                  Expanded(
                    child: AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Text('Card 1', style: TextStyles.cardTitle),
                      ),
                    ),
                  ),
                  SizedBox(width: SpacingTokens.elementSpacing),
                  Expanded(
                    child: AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Text('Card 2', style: TextStyles.cardTitle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.byType(AsmblCard), findsNWidgets(2));
    });
  });
}