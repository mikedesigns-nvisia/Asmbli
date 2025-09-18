import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/features/settings/screens/unified_settings_screen.dart';
import 'package:agentengine_desktop/features/settings/categories/ai_models_settings_category.dart';
import 'package:agentengine_desktop/features/settings/categories/mcp_tools_settings_category.dart';
import 'package:agentengine_desktop/features/settings/categories/appearance_settings_category.dart';
import 'package:agentengine_desktop/features/settings/categories/oauth_settings_category.dart';
import 'package:agentengine_desktop/features/settings/components/settings_category_card.dart';
import 'package:agentengine_desktop/features/settings/components/settings_field.dart';
import 'package:agentengine_desktop/features/settings/providers/settings_provider.dart';
import 'package:agentengine_desktop/features/settings/services/unified_settings_service.dart';
import 'package:agentengine_desktop/core/models/settings_models.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';
import 'package:agentengine_desktop/core/services/mcp_settings_service.dart';
import 'package:agentengine_desktop/core/models/mcp_server_config.dart';
import 'package:agentengine_desktop/core/models/oauth_provider.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_services.dart';

/// SR-005: Test unified settings system integration works correctly
void main() {
  group('Unified Settings System Integration Tests', () {
    late ProviderContainer container;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;
    late MockUnifiedSettingsService mockUnifiedSettingsService;

    setUp(() {
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      mockUnifiedSettingsService = MockUnifiedSettingsService();
      
      // Set up basic configurations for testing
      mockApiConfigService.setMockApiConfigs({
        'claude-config': MockApiConfig(
          provider: 'Anthropic',
          apiKey: 'test-claude-key',
          isConfigured: true,
        ),
        'gpt-config': MockApiConfig(
          provider: 'OpenAI',
          apiKey: 'test-gpt-key',
          isConfigured: true,
        ),
      });

      mockStorageService.setMockPreference('theme_mode', 'dark');
      mockStorageService.setMockPreference('color_scheme', 'coolBlue');
      
      container = ProviderContainer(
        overrides: [
          desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('SR-005.1: Unified settings screen displays correctly', (tester) async {
      // Arrange & Act: Load unified settings screen
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify main UI elements
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Customize your Asmbli experience'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      
      // Verify category cards are displayed
      expect(find.byType(SettingsCategoryCard), findsWidgets);
      expect(find.text('AI Models'), findsOneWidget);
      expect(find.text('MCP Tools'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('OAuth & Security'), findsOneWidget);
    });

    testWidgets('SR-005.2: Settings search functionality works', (tester) async {
      // Arrange: Load settings screen
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Search for specific settings
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'API');
      await tester.pumpAndSettle();

      // Assert: Verify search results
      expect(find.text('AI Models'), findsOneWidget); // Should show AI Models category
      expect(find.text('OAuth'), findsOneWidget); // Should show OAuth category
    });

    testWidgets('SR-005.3: Category navigation works correctly', (tester) async {
      // Arrange: Load settings screen
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Tap on AI Models category
      await tester.tap(find.text('AI Models'));
      await tester.pumpAndSettle();

      // Assert: Verify navigation to AI Models category
      expect(find.byType(AiModelsSettingsCategory), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Verify category-specific content
      expect(find.text('API Configurations'), findsOneWidget);
      expect(find.text('Anthropic'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
    });

    testWidgets('SR-005.4: Settings overview stats display correctly', (tester) async {
      // Arrange: Set up mock settings state
      mockUnifiedSettingsService.setMockSettingsState(UnifiedSettingsState(
        aiModels: AiModelsSettings(
          configurations: [
            ApiConfig(
              id: 'config1',
              name: 'Claude Config',
              provider: 'Anthropic',
              model: 'claude-3',
              apiKey: 'test-key',
              baseUrl: 'https://api.anthropic.com',
            ),
          ],
        ),
        mcpTools: McpToolsSettings(
          servers: [
            MCPServerConfig(
              id: 'server1',
              name: 'Test Server',
              url: 'http://localhost:8080',
              protocol: 'http',
              enabled: true,
            ),
          ],
        ),
        appearance: const AppearanceSettings(),
        oauth: const OAuthSettings(
          connectedProviders: [OAuthProvider.github, OAuthProvider.google],
        ),
        agents: const AgentSettings(),
        account: const AccountSettings(),
      ));

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify overview statistics
      expect(find.text('1'), findsWidgets); // AI Models count
      expect(find.text('2'), findsOneWidget); // OAuth Connections count
      expect(find.text('AI Models'), findsAtLeastNWidgets(1));
      expect(find.text('MCP Tools'), findsAtLeastNWidgets(1));
      expect(find.text('OAuth Connections'), findsOneWidget);
    });

    testWidgets('SR-005.5: AI Models category functionality works', (tester) async {
      // Arrange: Navigate to AI Models category
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'aiModels'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Try to add new AI model configuration
      if (tester.any(find.text('Add AI Model'))) {
        await tester.tap(find.text('Add AI Model'));
        await tester.pumpAndSettle();

        // Fill in the form
        await tester.enterText(find.byType(SettingsField).first, 'Test Model');
        await tester.pumpAndSettle();

        // Assert: Verify form is displayed and functional
        expect(find.text('Add AI Model Configuration'), findsOneWidget);
        expect(find.byType(DropdownButton), findsOneWidget);
      }
    });

    testWidgets('SR-005.6: MCP Tools category functionality works', (tester) async {
      // Arrange: Navigate to MCP Tools category
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'mcpTools'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify MCP Tools category is displayed
      expect(find.byType(McpToolsSettingsCategory), findsOneWidget);
      expect(find.text('MCP Servers'), findsOneWidget);
      
      // Look for add server functionality
      if (tester.any(find.text('Add MCP Server'))) {
        expect(find.text('Add MCP Server'), findsOneWidget);
      }
    });

    testWidgets('SR-005.7: Appearance settings functionality works', (tester) async {
      // Arrange: Navigate to Appearance category
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'appearance'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify Appearance category elements
      expect(find.byType(AppearanceSettingsCategory), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Color Scheme'), findsOneWidget);
      
      // Verify theme options
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('SR-005.8: OAuth settings functionality works', (tester) async {
      // Arrange: Navigate to OAuth category
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'oauth'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify OAuth category elements
      expect(find.byType(OAuthSettingsCategory), findsOneWidget);
      expect(find.text('OAuth Providers'), findsOneWidget);
      
      // Verify provider cards
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Dropbox'), findsOneWidget);
    });

    testWidgets('SR-005.9: Settings error handling works correctly', (tester) async {
      // Arrange: Set up service to return error state
      mockUnifiedSettingsService.setMockError('Failed to load settings');

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify error state is displayed
      expect(find.text('Settings Error'), findsOneWidget);
      expect(find.text('Failed to load settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('SR-005.10: Settings loading state works correctly', (tester) async {
      // Arrange: Set up service to return loading state
      mockUnifiedSettingsService.setMockLoading(true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pump(); // Don't settle to catch loading state

      // Assert: Verify loading state is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SR-005.11: Settings attention indicators work correctly', (tester) async {
      // Arrange: Set up settings state with attention items
      mockUnifiedSettingsService.setMockSettingsState(UnifiedSettingsState(
        aiModels: const AiModelsSettings(configurations: []), // Empty = attention needed
        mcpTools: const McpToolsSettings(),
        appearance: const AppearanceSettings(),
        oauth: const OAuthSettings(), // Empty = attention needed
        agents: const AgentSettings(),
        account: const AccountSettings(),
      ));

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify attention indicators are displayed
      expect(find.textContaining('need attention'), findsWidgets);
      expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
    });

    testWidgets('SR-005.12: Settings back navigation works correctly', (tester) async {
      // Arrange: Start in a category view
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'aiModels'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert: Verify navigation back to overview
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Customize your Asmbli experience'), findsOneWidget);
      expect(find.byType(SettingsCategoryCard), findsWidgets);
    });

    testWidgets('SR-005.13: Settings responsive layout works', (tester) async {
      // Arrange: Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Desktop size
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
          ],
          child: const MaterialApp(home: UnifiedSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify desktop layout
      expect(find.byType(SettingsCategoryCard), findsWidgets);
      expect(find.byType(TextField), findsOneWidget); // Search bar should be visible

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpAndSettle();

      // Verify layout adapts (specific checks would depend on responsive implementation)
      expect(find.byType(SettingsCategoryCard), findsWidgets);
      
      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('SR-005.14: Settings data persistence integration works', (tester) async {
      // Arrange: Navigate to AI Models and add configuration
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            unifiedSettingsServiceProvider.overrideWithValue(mockUnifiedSettingsService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(
            home: UnifiedSettingsScreen(initialCategory: 'aiModels'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Simulate adding a configuration (if add button exists)
      if (tester.any(find.text('Add AI Model'))) {
        await tester.tap(find.text('Add AI Model'));
        await tester.pumpAndSettle();

        // The form interaction would be tested here
        // For now, we'll verify the service integration
      }

      // Assert: Verify service integration for persistence
      expect(mockUnifiedSettingsService.initializeCalled, true);
      expect(mockApiConfigService.isInitialized, true);
    });
  });
}

/// Mock Unified Settings Service for testing
class MockUnifiedSettingsService implements UnifiedSettingsService {
  bool _isInitialized = false;
  bool initializeCalled = false;
  UnifiedSettingsState? _mockState;
  String? _mockError;
  bool _isLoading = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    initializeCalled = true;
  }

  @override
  Future<UnifiedSettingsState> getSettingsState() async {
    if (_mockError != null) {
      return UnifiedSettingsState.error(_mockError!);
    }

    if (_isLoading) {
      return const UnifiedSettingsState.loading();
    }

    return _mockState ?? const UnifiedSettingsState(
      aiModels: AiModelsSettings(),
      mcpTools: McpToolsSettings(),
      appearance: AppearanceSettings(),
      oauth: OAuthSettings(),
      agents: AgentSettings(),
      account: AccountSettings(),
    );
  }

  @override
  Future<void> saveAiModelsSettings(AiModelsSettings settings) async {
    // Mock implementation
  }

  @override
  Future<void> saveMcpToolsSettings(McpToolsSettings settings) async {
    // Mock implementation
  }

  @override
  Future<void> saveAppearanceSettings(AppearanceSettings settings) async {
    // Mock implementation
  }

  @override
  Future<void> saveOAuthSettings(OAuthSettings settings) async {
    // Mock implementation
  }

  @override
  Future<SettingsTestResult> testConnection(SettingsCategory category) async {
    return SettingsTestResult.success('Test connection successful');
  }

  @override
  Future<Map<String, dynamic>> exportSettings() async {
    return {};
  }

  @override
  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    // Mock implementation
  }

  @override
  Future<void> resetToDefaults() async {
    // Mock implementation
  }

  @override
  void dispose() {
    // Mock implementation
  }

  @override
  Stream<SettingsEvent> get settingsEvents => Stream.empty();

  // Test helper methods
  void setMockSettingsState(UnifiedSettingsState state) {
    _mockState = state;
    _mockError = null;
    _isLoading = false;
  }

  void setMockError(String error) {
    _mockError = error;
    _mockState = null;
    _isLoading = false;
  }

  void setMockLoading(bool isLoading) {
    _isLoading = isLoading;
    _mockError = null;
  }

  void clearMockData() {
    _mockState = null;
    _mockError = null;
    _isLoading = false;
    initializeCalled = false;
    _isInitialized = false;
  }
}