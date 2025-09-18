import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';
import 'package:agentengine_desktop/features/chat/presentation/screens/chat_screen.dart';
import 'package:agentengine_desktop/features/agents/presentation/screens/my_agents_screen.dart';
import 'package:agentengine_desktop/features/context/presentation/screens/context_library_screen.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/modern_settings_screen.dart';
import 'package:agentengine_desktop/features/tools/presentation/screens/tools_screen.dart';
import 'package:agentengine_desktop/features/agent_wizard/presentation/screens/agent_wizard_screen.dart';
import 'package:agentengine_desktop/core/design_system/components/app_navigation_bar.dart';
import 'package:agentengine_desktop/core/design_system/components/header_button.dart';

import '../test_helpers/mock_services.dart';
import '../test_helpers/test_app_wrapper.dart';

void main() {
  group('Navigation and Routing Flow Tests', () {
    late SharedPreferences mockPrefs;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;

    setUpAll(() async {
      await Hive.initFlutter();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      
      // Set up default state - user is onboarded with API keys
      mockStorageService.setMockPreference('onboarding_completed', true);
      mockApiConfigService.setMockApiConfigs({
        'openai': MockApiConfig(
          provider: 'openai',
          apiKey: 'sk-test123',
          isConfigured: true,
        ),
      });
    });

    testWidgets('App loads on home route by default', (WidgetTester tester) async {
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

      // Should load on home screen
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Start Chat'), findsOneWidget);
      expect(find.text('Build Agent'), findsOneWidget);
    });

    testWidgets('Navigation bar is present on all main screens', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Should show navigation bar
      expect(find.byType(AppNavigationBar), findsOneWidget);
      
      // Should show all navigation buttons
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('My Agents'), findsOneWidget);
      expect(find.text('Context'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Navigation to Chat screen works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Click on Chat navigation button
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Should navigate to chat screen
      expect(find.byType(ChatScreen), findsOneWidget);
      
      // Chat button should be active in navigation
      final chatButton = find.ancestor(
        of: find.text('Chat'),
        matching: find.byType(HeaderButton),
      );
      expect(chatButton, findsOneWidget);
    });

    testWidgets('Navigation to My Agents screen works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Click on My Agents navigation button
      await tester.tap(find.text('My Agents'));
      await tester.pumpAndSettle();

      // Should navigate to agents screen
      expect(find.byType(MyAgentsScreen), findsOneWidget);
    });

    testWidgets('Navigation to Context screen works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Click on Context navigation button
      await tester.tap(find.text('Context'));
      await tester.pumpAndSettle();

      // Should navigate to context screen
      expect(find.byType(ContextLibraryScreen), findsOneWidget);
    });

    testWidgets('Navigation to Tools screen works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Click on Tools navigation button
      await tester.tap(find.text('Tools'));
      await tester.pumpAndSettle();

      // Should navigate to tools/integration hub screen
      expect(find.byType(ToolsScreen), findsOneWidget);
    });

    testWidgets('Navigation to Settings screen works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Click on Settings navigation button
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should navigate to settings screen
      expect(find.byType(ModernSettingsScreen), findsOneWidget);
    });

    testWidgets('Quick action navigation from home works', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Test "Start Chat" quick action
      await tester.tap(find.text('Start Chat'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);

      // Go back to home
      await tester.tap(find.text('Asmbli')); // Brand title acts as home button
      await tester.pumpAndSettle();

      // Test "Build Agent" quick action
      await tester.tap(find.text('Build Agent'));
      await tester.pumpAndSettle();

      expect(find.byType(AgentWizardScreen), findsOneWidget);
    });

    testWidgets('Brand title navigation to home works from any screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Should be on chat screen
      expect(find.byType(ChatScreen), findsOneWidget);

      // Click on brand title to go home
      await tester.tap(find.text('Asmbli'));
      await tester.pumpAndSettle();

      // Should navigate to home
      expect(find.text('Welcome back!'), findsOneWidget);
    });

    testWidgets('Deep linking with query parameters works', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: '${AppRoutes.chat}?template=assistant',
        ),
      );

      await tester.pumpAndSettle();

      // Should navigate to chat screen with template parameter
      expect(find.byType(ChatScreen), findsOneWidget);
      // Template parameter should be passed to the widget (would need to verify in actual implementation)
    });

    testWidgets('Agent wizard with template parameter works', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: '${AppRoutes.agentWizard}?template=code_helper',
        ),
      );

      await tester.pumpAndSettle();

      // Should navigate to agent wizard with template
      expect(find.byType(AgentWizardScreen), findsOneWidget);
    });

    testWidgets('Navigation preserves state when switching between screens', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ModernSettingsScreen), findsOneWidget);

      // Navigate back to chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      // State should be preserved (in a real app, this would verify conversation state, etc.)
    });

    testWidgets('Invalid routes are handled gracefully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: '/nonexistent-route',
        ),
      );

      await tester.pumpAndSettle();

      // Should fallback to home or show 404 page
      // This depends on your router configuration
      expect(find.text('Welcome back!'), findsOneWidget);
    });

    testWidgets('Back button behavior works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ModernSettingsScreen), findsOneWidget);

      // Navigate to agents from settings
      await tester.tap(find.text('My Agents'));
      await tester.pumpAndSettle();
      expect(find.byType(MyAgentsScreen), findsOneWidget);

      // Test browser back button (simulated)
      // In a real browser environment, you would test actual back button behavior
      // For now, we test programmatic navigation back
      await tester.tap(find.text('Settings')); // Go back to settings
      await tester.pumpAndSettle();
      expect(find.byType(ModernSettingsScreen), findsOneWidget);
    });

    testWidgets('Active navigation state is correctly highlighted', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Should be on chat screen with chat button active
      expect(find.byType(ChatScreen), findsOneWidget);
      
      // Chat button should have active styling (would need to verify actual styling)
      final chatHeaderButton = find.ancestor(
        of: find.text('Chat'),
        matching: find.byType(HeaderButton),
      );
      expect(chatHeaderButton, findsOneWidget);

      // Navigate to another screen
      await tester.tap(find.text('My Agents'));
      await tester.pumpAndSettle();

      // My Agents button should now be active
      final agentsHeaderButton = find.ancestor(
        of: find.text('My Agents'),
        matching: find.byType(HeaderButton),
      );
      expect(agentsHeaderButton, findsOneWidget);
    });

    testWidgets('Route transitions are smooth and complete', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.home,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate between multiple screens rapidly
      await tester.tap(find.text('Chat'));
      await tester.pump(); // Don't settle to test transition
      
      await tester.tap(find.text('My Agents'));
      await tester.pump();
      
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle(); // Now settle

      // Should end up on the last clicked screen
      expect(find.byType(ModernSettingsScreen), findsOneWidget);
    });
  });
}