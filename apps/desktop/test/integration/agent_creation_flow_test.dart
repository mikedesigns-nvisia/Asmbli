import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/features/agent_wizard/presentation/screens/agent_wizard_screen.dart';
import 'package:agentengine_desktop/features/agents/presentation/screens/my_agents_screen.dart';
import 'package:agentengine_desktop/features/agents/presentation/screens/agent_configuration_screen.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';

import '../test_helpers/mock_services.dart';
import '../test_helpers/test_app_wrapper.dart';

/// Mock agent service for testing agent creation flows
class MockAgentService {
  final List<MockAgent> _agents = [];
  
  Future<MockAgent> createAgent({
    required String name,
    required String description,
    String? systemPrompt,
    Map<String, dynamic>? configuration,
  }) async {
    final agent = MockAgent(
      id: 'agent-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      systemPrompt: systemPrompt ?? 'You are a helpful AI assistant.',
      configuration: configuration ?? {},
      createdAt: DateTime.now(),
    );
    
    _agents.add(agent);
    return agent;
  }
  
  Future<List<MockAgent>> getAllAgents() async {
    return List.from(_agents);
  }
  
  Future<MockAgent?> getAgent(String id) async {
    try {
      return _agents.firstWhere((agent) => agent.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<void> updateAgent(MockAgent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index != -1) {
      _agents[index] = agent;
    }
  }
  
  Future<void> deleteAgent(String id) async {
    _agents.removeWhere((agent) => agent.id == id);
  }
  
  // Test helper methods
  void addMockAgent(MockAgent agent) {
    _agents.add(agent);
  }
  
  void clearMockAgents() {
    _agents.clear();
  }
}

/// Mock agent model for testing
class MockAgent {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final Map<String, dynamic> configuration;
  final DateTime createdAt;
  
  MockAgent({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.configuration,
    required this.createdAt,
  });
  
  MockAgent copyWith({
    String? name,
    String? description,
    String? systemPrompt,
    Map<String, dynamic>? configuration,
  }) {
    return MockAgent(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      configuration: configuration ?? this.configuration,
      createdAt: createdAt,
    );
  }
}

void main() {
  group('Agent Creation Flow Tests', () {
    late SharedPreferences mockPrefs;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;
    late MockAgentService mockAgentService;

    setUpAll(() async {
      await Hive.initFlutter();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      mockAgentService = MockAgentService();
      
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

    testWidgets('Agent wizard screen loads correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agentWizard,
        ),
      );

      await tester.pumpAndSettle();

      // Should show agent wizard screen
      expect(find.byType(AgentWizardScreen), findsOneWidget);
      
      // Should show basic wizard elements
      expect(find.text('Create Your AI Agent'), findsAny);
      expect(find.text('Agent Name'), findsAny);
    });

    testWidgets('User can create a basic agent with required fields', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agentWizard,
        ),
      );

      await tester.pumpAndSettle();

      // Fill in agent name
      final nameField = find.widgetWithText(TextFormField, 'Agent Name').first;
      await tester.enterText(nameField, 'My Test Agent');
      await tester.pumpAndSettle();

      // Fill in agent description
      final descriptionField = find.widgetWithText(TextFormField, 'Description');
      if (descriptionField.evaluate().isNotEmpty) {
        await tester.enterText(descriptionField, 'This is a test agent for automated testing');
        await tester.pumpAndSettle();
      }

      // Look for and tap create/next button
      final createButton = find.text('Create Agent');
      if (createButton.evaluate().isEmpty) {
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          
          // Now look for create button again
          final finalCreateButton = find.text('Create Agent');
          if (finalCreateButton.evaluate().isNotEmpty) {
            await tester.tap(finalCreateButton);
            await tester.pumpAndSettle();
          }
        }
      } else {
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }

      // Should navigate away from wizard or show success message
      expect(find.text('Agent created successfully'), findsAny);
    });

    testWidgets('Agent wizard validates required fields', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agentWizard,
        ),
      );

      await tester.pumpAndSettle();

      // Try to create agent without filling required fields
      final createButton = find.text('Create Agent');
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.textContaining('required'), findsAny);
        expect(find.textContaining('cannot be empty'), findsAny);
      }
    });

    testWidgets('User can select agent template', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: '${AppRoutes.agentWizard}?template=assistant',
        ),
      );

      await tester.pumpAndSettle();

      // Should load with selected template
      expect(find.byType(AgentWizardScreen), findsOneWidget);
      
      // Look for template selection UI
      expect(find.text('Assistant'), findsAny);
      expect(find.text('Code Helper'), findsAny);
      expect(find.text('Creative Writer'), findsAny);
    });

    testWidgets('User can configure agent system prompt', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agentWizard,
        ),
      );

      await tester.pumpAndSettle();

      // Fill basic information
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Agent Name').first,
        'Custom Agent',
      );
      await tester.pumpAndSettle();

      // Look for system prompt field
      final systemPromptField = find.widgetWithText(TextFormField, 'System Prompt');
      if (systemPromptField.evaluate().isNotEmpty) {
        await tester.enterText(
          systemPromptField,
          'You are a specialized AI assistant focused on testing and quality assurance.',
        );
        await tester.pumpAndSettle();
      } else {
        // Navigate to system prompt step if it's in a wizard flow
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          
          final systemPromptFieldStep2 = find.byType(TextFormField).last;
          await tester.enterText(
            systemPromptFieldStep2,
            'You are a specialized AI assistant focused on testing and quality assurance.',
          );
          await tester.pumpAndSettle();
        }
      }

      // Verify system prompt was entered
      expect(find.text('You are a specialized AI assistant'), findsOneWidget);
    });

    testWidgets('My Agents screen shows created agents', (WidgetTester tester) async {
      // Pre-create some test agents
      mockAgentService.addMockAgent(MockAgent(
        id: 'agent1',
        name: 'Test Agent 1',
        description: 'First test agent',
        systemPrompt: 'You are agent 1',
        configuration: {},
        createdAt: DateTime.now(),
      ));
      
      mockAgentService.addMockAgent(MockAgent(
        id: 'agent2',
        name: 'Test Agent 2',
        description: 'Second test agent',
        systemPrompt: 'You are agent 2',
        configuration: {},
        createdAt: DateTime.now(),
      ));

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agents,
        ),
      );

      await tester.pumpAndSettle();

      // Should show My Agents screen
      expect(find.byType(MyAgentsScreen), findsOneWidget);
      
      // Should show agent cards
      expect(find.text('Test Agent 1'), findsOneWidget);
      expect(find.text('Test Agent 2'), findsOneWidget);
      expect(find.text('First test agent'), findsOneWidget);
      expect(find.text('Second test agent'), findsOneWidget);
    });

    testWidgets('User can edit existing agent', (WidgetTester tester) async {
      // Pre-create a test agent
      mockAgentService.addMockAgent(MockAgent(
        id: 'edit-agent',
        name: 'Editable Agent',
        description: 'Agent to be edited',
        systemPrompt: 'Original prompt',
        configuration: {},
        createdAt: DateTime.now(),
      ));

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agents,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap edit button
      final editButton = find.byIcon(Icons.edit).first;
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Should navigate to agent configuration screen
      expect(find.byType(AgentConfigurationScreen), findsOneWidget);
      
      // Should show current agent data
      expect(find.text('Editable Agent'), findsOneWidget);
      expect(find.text('Agent to be edited'), findsOneWidget);
    });

    testWidgets('User can delete agent', (WidgetTester tester) async {
      // Pre-create a test agent
      mockAgentService.addMockAgent(MockAgent(
        id: 'delete-agent',
        name: 'Agent to Delete',
        description: 'This agent will be deleted',
        systemPrompt: 'Delete me',
        configuration: {},
        createdAt: DateTime.now(),
      ));

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agents,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.delete).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Agent'), findsOneWidget);
      expect(find.text('Are you sure'), findsAny);

      // Confirm deletion
      final confirmButton = find.text('Delete');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Agent should be removed from list
      expect(find.text('Agent to Delete'), findsNothing);
      expect(mockAgentService._agents.any((a) => a.id == 'delete-agent'), false);
    });

    testWidgets('User can test agent before deployment', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.agentWizard,
        ),
      );

      await tester.pumpAndSettle();

      // Fill agent information
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Agent Name').first,
        'Test Agent',
      );
      await tester.pumpAndSettle();

      // Look for test button
      final testButton = find.text('Test Agent');
      if (testButton.evaluate().isNotEmpty) {
        await tester.tap(testButton);
        await tester.pumpAndSettle();

        // Should show test interface
        expect(find.text('Test your agent'), findsAny);
        expect(find.byType(TextFormField), findsAny); // Test message input
      }
    });

    testWidgets('Agent configuration screen handles advanced settings', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: '/agents/configure',
        ),
      );

      await tester.pumpAndSettle();

      // Should show agent configuration screen
      expect(find.byType(AgentConfigurationScreen), findsOneWidget);
      
      // Look for advanced settings
      final advancedTab = find.text('Advanced');
      if (advancedTab.evaluate().isNotEmpty) {
        await tester.tap(advancedTab);
        await tester.pumpAndSettle();

        // Should show advanced configuration options
        expect(find.text('Temperature'), findsAny);
        expect(find.text('Max Tokens'), findsAny);
        expect(find.text('Model'), findsAny);
      }
    });
  });
}