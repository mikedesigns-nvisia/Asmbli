import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';
import 'package:agentengine_desktop/core/services/mcp_settings_service.dart';
import 'package:agentengine_desktop/core/services/oauth_integration_service.dart';
import 'package:agentengine_desktop/core/services/theme_service.dart';
import 'package:agentengine_desktop/core/services/agent_context_prompt_service.dart';
import 'package:agentengine_desktop/features/settings/services/unified_settings_service.dart';
import 'package:agentengine_desktop/features/settings/providers/settings_provider.dart';
import 'package:agentengine_desktop/core/models/settings_models.dart';
import 'package:agentengine_desktop/core/models/mcp_server_config.dart';
import 'package:agentengine_desktop/core/models/oauth_provider.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_services.dart';

/// SR-001: Test all settings service integrations work correctly
void main() {
  group('Settings Services Integration Tests', () {
    late ProviderContainer container;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;

    setUp(() {
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      
      container = ProviderContainer(
        overrides: [
          // Override services with mocks for testing
          desktopStorageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('SR-001.1: UnifiedSettingsService initializes all services correctly', (tester) async {
      // Arrange: Set up test environment
      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          overrides: [
            desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          ],
        ),
      );

      // Act: Initialize unified settings service
      final settingsService = container.read(unifiedSettingsServiceProvider);
      await settingsService.initialize();
      
      // Assert: Verify service is initialized
      expect(settingsService, isNotNull);
      
      // Verify settings state can be retrieved
      final settingsState = await settingsService.getSettingsState();
      expect(settingsState, isA<UnifiedSettingsState>());
      expect(settingsState.isLoading, false);
      expect(settingsState.error, isNull);
    });

    testWidgets('SR-001.2: AI Models settings integration works correctly', (tester) async {
      // Arrange: Set up API configurations
      mockApiConfigService.setMockApiConfigs({
        'anthropic-1': MockApiConfig(
          provider: 'Anthropic',
          apiKey: 'test-api-key-1',
          isConfigured: true,
        ),
        'openai-1': MockApiConfig(
          provider: 'OpenAI',
          apiKey: 'test-api-key-2',
          isConfigured: true,
        ),
      });

      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Get settings state
      final settingsService = container.read(unifiedSettingsServiceProvider);
      final settingsState = await settingsService.getSettingsState();

      // Assert: Verify AI models are properly loaded
      expect(settingsState.aiModels.configurations.length, equals(2));
      expect(settingsState.aiModels.configurations.any((c) => c.provider == 'Anthropic'), true);
      expect(settingsState.aiModels.configurations.any((c) => c.provider == 'OpenAI'), true);

      // Test saving AI models settings
      final newConfig = ApiConfig(
        id: 'test-config',
        name: 'Test Model',
        provider: 'Google',
        model: 'gemini-pro',
        apiKey: 'test-google-key',
        baseUrl: 'https://api.google.com',
      );

      final newSettings = AiModelsSettings(
        configurations: [newConfig],
        defaultModelId: 'test-config',
      );

      await settingsService.saveAiModelsSettings(newSettings);

      // Verify the configuration was saved
      final updatedState = await settingsService.getSettingsState();
      expect(updatedState.aiModels.configurations.length, greaterThan(0));
    });

    testWidgets('SR-001.3: MCP Tools settings integration works correctly', (tester) async {
      // Arrange: Mock MCP servers
      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Test MCP settings service integration
      final settingsService = container.read(unifiedSettingsServiceProvider);
      
      // Create test MCP server configuration
      final mcpConfig = MCPServerConfig(
        id: 'test-mcp-server',
        name: 'Test MCP Server',
        url: 'http://localhost:8080',
        protocol: 'http',
        description: 'Test server for integration testing',
        enabled: true,
        capabilities: ['files', 'web_search'],
      );

      final mcpSettings = McpToolsSettings(
        servers: [mcpConfig],
        enabledTools: {'test-mcp-server': true},
      );

      // Act: Save MCP settings
      await settingsService.saveMcpToolsSettings(mcpSettings);

      // Assert: Verify MCP settings were saved
      final settingsState = await settingsService.getSettingsState();
      expect(settingsState.mcpTools.servers.length, equals(1));
      expect(settingsState.mcpTools.servers.first.name, equals('Test MCP Server'));
      expect(settingsState.mcpTools.enabledTools['test-mcp-server'], true);
    });

    testWidgets('SR-001.4: Theme settings integration works correctly', (tester) async {
      // Arrange: Set up theme preferences
      mockStorageService.setMockPreference('theme_mode', 'dark');
      mockStorageService.setMockPreference('color_scheme', 'coolBlue');

      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Get settings state
      final settingsService = container.read(unifiedSettingsServiceProvider);
      final settingsState = await settingsService.getSettingsState();

      // Assert: Verify appearance settings are loaded correctly
      expect(settingsState.appearance, isA<AppearanceSettings>());
      
      // Test saving appearance settings
      final newAppearanceSettings = AppearanceSettings(
        themeMode: ThemeMode.light,
        colorScheme: 'warmNeutral',
        fontSize: 16.0,
        compactMode: true,
      );

      await settingsService.saveAppearanceSettings(newAppearanceSettings);

      // Verify settings were applied
      final updatedState = await settingsService.getSettingsState();
      expect(updatedState.appearance.themeMode, equals(ThemeMode.light));
      expect(updatedState.appearance.fontSize, equals(16.0));
      expect(updatedState.appearance.compactMode, true);
    });

    testWidgets('SR-001.5: OAuth settings integration works correctly', (tester) async {
      // Arrange: Mock OAuth providers
      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Test OAuth settings
      final settingsService = container.read(unifiedSettingsServiceProvider);
      
      final oauthSettings = OAuthSettings(
        connectedProviders: [OAuthProvider.github, OAuthProvider.google],
        connectionDates: {
          OAuthProvider.github: DateTime.now(),
          OAuthProvider.google: DateTime.now().subtract(const Duration(days: 1)),
        },
        grantedScopes: {
          OAuthProvider.github: ['repo', 'user'],
          OAuthProvider.google: ['profile', 'email'],
        },
      );

      await settingsService.saveOAuthSettings(oauthSettings);

      // Assert: Verify OAuth settings were saved
      final settingsState = await settingsService.getSettingsState();
      expect(settingsState.oauth.connectedProviders.length, equals(2));
      expect(settingsState.oauth.connectedProviders.contains(OAuthProvider.github), true);
      expect(settingsState.oauth.connectedProviders.contains(OAuthProvider.google), true);
    });

    testWidgets('SR-001.6: Settings export and import work correctly', (tester) async {
      // Arrange: Set up test data
      mockApiConfigService.setMockApiConfigs({
        'test-config': MockApiConfig(
          provider: 'Anthropic',
          apiKey: 'test-key',
          isConfigured: true,
        ),
      });

      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Export settings
      final settingsService = container.read(unifiedSettingsServiceProvider);
      final exportedSettings = await settingsService.exportSettings();

      // Assert: Verify export structure
      expect(exportedSettings, isA<Map<String, dynamic>>());
      expect(exportedSettings.containsKey('aiModels'), true);
      expect(exportedSettings.containsKey('mcpTools'), true);
      expect(exportedSettings.containsKey('appearance'), true);
      expect(exportedSettings.containsKey('oauth'), true);

      // Test import settings
      await settingsService.importSettings(exportedSettings);

      // Verify import worked
      final reimportedState = await settingsService.getSettingsState();
      expect(reimportedState, isA<UnifiedSettingsState>());
      expect(reimportedState.error, isNull);
    });

    testWidgets('SR-001.7: Settings reset to defaults works correctly', (tester) async {
      // Arrange: Set up existing settings
      mockApiConfigService.setMockApiConfigs({
        'config1': MockApiConfig(provider: 'Test', apiKey: 'key', isConfigured: true),
      });

      mockStorageService.setMockPreference('theme_mode', 'dark');

      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Reset settings to defaults
      final settingsService = container.read(unifiedSettingsServiceProvider);
      await settingsService.resetToDefaults();

      // Assert: Verify settings were reset
      final settingsState = await settingsService.getSettingsState();
      expect(settingsState, isA<UnifiedSettingsState>());
      // After reset, configurations should be cleared
      expect(settingsState.aiModels.configurations, isEmpty);
    });

    testWidgets('SR-001.8: Settings connection testing works correctly', (tester) async {
      // Arrange: Set up configurations for testing
      mockApiConfigService.setMockApiConfigs({
        'working-config': MockApiConfig(
          provider: 'Anthropic',
          apiKey: 'valid-key',
          isConfigured: true,
        ),
        'broken-config': MockApiConfig(
          provider: 'OpenAI',
          apiKey: '',
          isConfigured: false,
        ),
      });

      await tester.pumpWidget(
        TestAppWrapper(
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
        ),
      );

      // Act: Test connections
      final settingsService = container.read(unifiedSettingsServiceProvider);
      
      // Test AI Models connections
      final aiModelsResult = await settingsService.testConnection(SettingsCategory.aiModels);
      expect(aiModelsResult, isA<SettingsTestResult>());
      expect(aiModelsResult.message, contains('connection'));

      // Test MCP Tools connections
      final mcpToolsResult = await settingsService.testConnection(SettingsCategory.mcpTools);
      expect(mcpToolsResult, isA<SettingsTestResult>());

      // Test OAuth connections
      final oauthResult = await settingsService.testConnection(SettingsCategory.oauth);
      expect(oauthResult, isA<SettingsTestResult>());
    });

    testWidgets('SR-001.9: Settings provider state management works correctly', (tester) async {
      // Arrange: Set up provider container
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          ],
          child: const MaterialApp(home: TestSettingsConsumer()),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert: Verify provider provides correct state
      expect(find.text('Settings loaded'), findsOneWidget);
    });

    testWidgets('SR-001.10: Settings error handling works correctly', (tester) async {
      // Arrange: Create a failing storage service
      final failingStorageService = FailingMockStorageService();

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            desktopStorageServiceProvider.overrideWithValue(failingStorageService),
          ],
        ),
      );

      // Act: Try to get settings state
      final settingsService = container.read(unifiedSettingsServiceProvider);
      final settingsState = await settingsService.getSettingsState();

      // Assert: Verify error is handled gracefully
      expect(settingsState, isA<UnifiedSettingsState>());
      expect(settingsState.error, isNotNull);
      expect(settingsState.error, contains('Failed to load settings'));
    });

    testWidgets('SR-001.11: Settings attention provider works correctly', (tester) async {
      // Arrange: Set up conditions that should trigger attention items
      mockApiConfigService.clearMockConfigs(); // No API configs = attention item

      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(home: TestAttentionConsumer()),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert: Verify attention items are generated
      expect(find.textContaining('attention'), findsWidgets);
    });
  });
}

/// Test consumer widget for settings provider
class TestSettingsConsumer extends ConsumerWidget {
  const TestSettingsConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    if (settingsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (settingsState.error != null) {
      return Scaffold(body: Center(child: Text('Error: ${settingsState.error}')));
    }

    return const Scaffold(body: Center(child: Text('Settings loaded')));
  }
}

/// Test consumer widget for attention provider
class TestAttentionConsumer extends ConsumerWidget {
  const TestAttentionConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attentionItems = ref.watch(settingsAttentionProvider);

    return Scaffold(
      body: Column(
        children: [
          Text('Attention items: ${attentionItems.length}'),
          ...attentionItems.map((item) => Text('${item.category.name}: ${item.message}')),
        ],
      ),
    );
  }
}

/// Mock storage service that fails for error testing
class FailingMockStorageService extends MockDesktopStorageService {
  @override
  T? getPreference<T>(String key, {T? defaultValue}) {
    throw Exception('Simulated storage failure');
  }

  @override
  Future<void> setPreference<T>(String key, T value) async {
    throw Exception('Simulated storage failure');
  }
}