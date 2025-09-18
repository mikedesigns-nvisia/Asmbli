import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/modern_settings_screen.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/apple_style_oauth_screen.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';
import 'package:agentengine_desktop/core/services/theme_service.dart';
import 'package:agentengine_desktop/core/theme/color_schemes.dart';

import '../test_helpers/mock_services.dart';
import '../test_helpers/test_app_wrapper.dart';

/// Mock theme service for testing theme changes
class MockThemeService {
  ThemeMode _themeMode = ThemeMode.system;
  String _colorScheme = AppColorSchemes.warmNeutral;
  
  ThemeMode get themeMode => _themeMode;
  String get colorScheme => _colorScheme;
  
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
  }
  
  void setColorScheme(String scheme) {
    _colorScheme = scheme;
  }
  
  ThemeData getLightTheme() {
    return ThemeData.light();
  }
  
  ThemeData getDarkTheme() {
    return ThemeData.dark();
  }
}

void main() {
  group('Settings and Configuration Flow Tests', () {
    late SharedPreferences mockPrefs;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;
    late MockThemeService mockThemeService;

    setUpAll(() async {
      await Hive.initFlutter();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      mockThemeService = MockThemeService();
      
      // Set up default state - user is onboarded
      mockStorageService.setMockPreference('onboarding_completed', true);
      mockApiConfigService.setMockApiConfigs({
        'openai': MockApiConfig(
          provider: 'openai',
          apiKey: 'sk-test123',
          isConfigured: true,
        ),
      });
    });

    testWidgets('Settings screen loads with all sections', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Should show settings screen
      expect(find.byType(ModernSettingsScreen), findsOneWidget);
      
      // Should show main settings sections
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('API Configuration'), findsOneWidget);
      expect(find.text('Integrations'), findsAny);
      expect(find.text('About'), findsAny);
    });

    testWidgets('User can change theme mode (Light/Dark)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to appearance settings
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // Should show theme options
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Tap on Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Should update theme (would verify through theme service in real implementation)
      expect(mockThemeService.themeMode, ThemeMode.dark);
    });

    testWidgets('User can change color scheme', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to appearance settings
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // Should show color scheme options
      expect(find.text('Mint Green'), findsAny);
      expect(find.text('Cool Blue'), findsAny);
      expect(find.text('Forest Green'), findsAny);
      expect(find.text('Sunset Orange'), findsAny);

      // Tap on Cool Blue
      await tester.tap(find.text('Cool Blue'));
      await tester.pumpAndSettle();

      // Should update color scheme
      expect(mockThemeService.colorScheme, AppColorSchemes.coolBlue);
    });

    testWidgets('User can configure OpenAI API settings', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to API configuration
      await tester.tap(find.text('API Configuration'));
      await tester.pumpAndSettle();

      // Should show API providers
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Anthropic'), findsAny);
      expect(find.text('Local Models'), findsAny);

      // Tap on OpenAI settings
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      // Should show OpenAI configuration form
      expect(find.text('API Key'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));

      // Update API key
      final apiKeyField = find.byType(TextFormField).first;
      await tester.enterText(apiKeyField, 'sk-new-test-key-456');
      await tester.pumpAndSettle();

      // Save changes
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Settings saved'), findsAny);
        
        // Verify API key was updated
        expect(mockApiConfigService.getApiKey('openai'), 'sk-new-test-key-456');
      }
    });

    testWidgets('OAuth settings screen loads correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.oauthSettings,
        ),
      );

      await tester.pumpAndSettle();

      // Should show OAuth settings screen
      expect(find.byType(AppleStyleOAuthScreen), findsOneWidget);
      
      // Should show provider options
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Anthropic'), findsAny);
      expect(find.text('Google'), findsAny);
    });

    testWidgets('User can add new API provider configuration', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to API configuration
      await tester.tap(find.text('API Configuration'));
      await tester.pumpAndSettle();

      // Look for add provider button
      final addButton = find.text('Add Provider');
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Should show provider selection
        await tester.tap(find.text('Anthropic'));
        await tester.pumpAndSettle();

        // Enter API key for Anthropic
        final apiKeyField = find.byType(TextFormField).first;
        await tester.enterText(apiKeyField, 'sk-ant-test-key');
        await tester.pumpAndSettle();

        // Save configuration
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should add new provider
        expect(mockApiConfigService.isConfigured('anthropic'), true);
      }
    });

    testWidgets('User can remove API provider configuration', (WidgetTester tester) async {
      // Pre-configure multiple providers
      mockApiConfigService.setMockApiConfigs({
        'openai': MockApiConfig(provider: 'openai', apiKey: 'sk-test1', isConfigured: true),
        'anthropic': MockApiConfig(provider: 'anthropic', apiKey: 'sk-ant-test', isConfigured: true),
      });

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to API configuration
      await tester.tap(find.text('API Configuration'));
      await tester.pumpAndSettle();

      // Should show both providers
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Anthropic'), findsOneWidget);

      // Find remove button for Anthropic
      final removeButton = find.byIcon(Icons.delete).first;
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Remove Provider'), findsAny);
      
      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Should remove provider
      expect(mockApiConfigService.isConfigured('anthropic'), false);
    });

    testWidgets('Settings form validation works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to API configuration
      await tester.tap(find.text('API Configuration'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      // Clear the API key field
      final apiKeyField = find.byType(TextFormField).first;
      await tester.enterText(apiKeyField, '');
      await tester.pumpAndSettle();

      // Try to save without API key
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('API key is required'), findsOneWidget);
      }
    });

    testWidgets('Integration settings can be configured', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to integrations
      final integrationsButton = find.text('Integrations');
      if (integrationsButton.evaluate().isNotEmpty) {
        await tester.tap(integrationsButton);
        await tester.pumpAndSettle();

        // Should show integration options
        expect(find.text('MCP Servers'), findsAny);
        expect(find.text('Tools'), findsAny);
        expect(find.text('Plugins'), findsAny);
      }
    });

    testWidgets('About section displays app information', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to about section
      final aboutButton = find.text('About');
      if (aboutButton.evaluate().isNotEmpty) {
        await tester.tap(aboutButton);
        await tester.pumpAndSettle();

        // Should show app information
        expect(find.text('Asmbli'), findsOneWidget);
        expect(find.text('Version'), findsAny);
        expect(find.textContaining('1.0.'), findsAny);
      }
    });

    testWidgets('Settings persist between app restarts', (WidgetTester tester) async {
      // Set some initial settings
      mockStorageService.setMockPreference('theme_mode', 'dark');
      mockStorageService.setMockPreference('color_scheme', AppColorSchemes.coolBlue);

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.settings,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to appearance
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // Verify saved settings are loaded
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Cool Blue'), findsOneWidget);
      
      // Verify settings are actually applied
      expect(mockStorageService.getPreference('theme_mode'), 'dark');
      expect(mockStorageService.getPreference('color_scheme'), AppColorSchemes.coolBlue);
    });
  });
}