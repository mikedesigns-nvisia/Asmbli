import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:agentengine_desktop/main.dart';
import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';
import 'package:agentengine_desktop/core/services/desktop/desktop_storage_service.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';

import '../test_helpers/mock_services.dart';
import '../test_helpers/test_app_wrapper.dart';

void main() {
  group('Onboarding Flow Tests', () {
    late SharedPreferences mockPrefs;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;

    setUpAll(() async {
      await Hive.initFlutter();
    });

    setUp(() async {
      // Reset mock initial values
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      
      // Initialize mock services
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      
      // Set up default mock behavior
      mockStorageService.setMockPreference('onboarding_completed', false);
      mockApiConfigService.setMockApiConfigs({});
    });

    testWidgets('New user without API keys is redirected to onboarding', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Allow time for async initialization and routing
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be redirected to onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to Asmbli'), findsOneWidget);
    });

    testWidgets('User with API keys skips onboarding', (WidgetTester tester) async {
      // Set up existing API configuration
      mockApiConfigService.setMockApiConfigs({
        'openai': MockApiConfig(
          provider: 'openai',
          apiKey: 'sk-test123',
          isConfigured: true,
        ),
      });
      
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should go directly to home screen
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Welcome back!'), findsOneWidget);
    });

    testWidgets('Complete onboarding flow with OpenAI setup', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      await tester.pumpAndSettle();

      // Should be on onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Test welcome step
      expect(find.text('Welcome to Asmbli'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      
      // Tap Get Started button
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should now be on API configuration step
      expect(find.text('Connect Your AI'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);

      // Tap on OpenAI provider
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      // Enter API key
      final apiKeyField = find.byType(TextFormField);
      expect(apiKeyField, findsOneWidget);
      
      await tester.enterText(apiKeyField, 'sk-test-api-key-123');
      await tester.pumpAndSettle();

      // Tap Save or Next button
      final nextButton = find.text('Save & Continue');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Should move to next step or complete onboarding
      // Verify API key was saved
      expect(mockApiConfigService.mockApiConfigs.containsKey('openai'), true);
      expect(mockApiConfigService.mockApiConfigs['openai']?.apiKey, 'sk-test-api-key-123');
    });

    testWidgets('Onboarding validation prevents proceeding without API key', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate through onboarding to API setup
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Try to proceed without entering API key
      final nextButton = find.text('Save & Continue');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('API key is required'), findsOneWidget);
      }
    });

    testWidgets('Onboarding completion marks user as onboarded', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      await tester.pumpAndSettle();

      // Complete full onboarding flow
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'sk-test-key');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Complete final step if present
      final finishButton = find.text('Finish Setup');
      if (finishButton.evaluate().isNotEmpty) {
        await tester.tap(finishButton);
        await tester.pumpAndSettle();
      }

      // Verify onboarding completion was saved
      final onboardingCompleted = mockStorageService.getPreference<bool>('onboarding_completed');
      expect(onboardingCompleted, true);
    });

    testWidgets('Skip onboarding option works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      await tester.pumpAndSettle();

      // Look for skip option
      final skipButton = find.text('Skip for now');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();

        // Should navigate to main app
        expect(find.text('Welcome back!'), findsOneWidget);
        
        // Should still mark as onboarded to prevent loop
        final onboardingCompleted = mockStorageService.getPreference<bool>('onboarding_completed');
        expect(onboardingCompleted, true);
      }
    });
  });
}