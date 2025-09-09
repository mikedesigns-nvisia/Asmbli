import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agentengine_desktop/main.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';
import 'package:agentengine_desktop/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:agentengine_desktop/features/chat/presentation/screens/chat_screen.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/modern_settings_screen.dart';
import 'package:agentengine_desktop/features/agents/presentation/screens/my_agents_screen.dart';
import 'package:agentengine_desktop/features/context/presentation/screens/context_library_screen.dart';
import 'package:agentengine_desktop/features/agent_wizard/presentation/screens/agent_wizard_screen.dart';
import 'package:agentengine_desktop/features/tools/presentation/screens/tools_screen.dart';
import 'package:agentengine_desktop/core/services/desktop/desktop_storage_service.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';

import 'mock_services.dart';

/// Test wrapper that provides a controlled environment for widget testing
class TestAppWrapper extends ConsumerWidget {
  final List<Override> overrides;
  final MockDesktopStorageService? storageService;
  final MockApiConfigService? apiConfigService;
  final String? initialRoute;
  
  const TestAppWrapper({
    super.key,
    this.overrides = const [],
    this.storageService,
    this.apiConfigService,
    this.initialRoute,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        ...overrides,
        // Note: Service overrides would be implemented in real app providers
      ],
      child: TestMaterialApp(
        initialRoute: initialRoute,
        storageService: storageService,
        apiConfigService: apiConfigService,
      ),
    );
  }
}

/// Material app wrapper for testing with controlled routing
class TestMaterialApp extends StatefulWidget {
  final String? initialRoute;
  final MockDesktopStorageService? storageService;
  final MockApiConfigService? apiConfigService;
  
  const TestMaterialApp({
    super.key,
    this.initialRoute,
    this.storageService,
    this.apiConfigService,
  });
  
  @override
  State<TestMaterialApp> createState() => _TestMaterialAppState();
}

class _TestMaterialAppState extends State<TestMaterialApp> {
  late final GoRouter _router;
  
  @override
  void initState() {
    super.initState();
    _router = _createTestRouter();
  }
  
  GoRouter _createTestRouter() {
    return GoRouter(
      initialLocation: widget.initialRoute ?? _getInitialRoute(),
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const TestHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) {
            final template = state.uri.queryParameters['template'];
            return ChatScreen(selectedTemplate: template);
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const ModernSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.agents,
          builder: (context, state) => const MyAgentsScreen(),
        ),
        GoRoute(
          path: AppRoutes.context,
          builder: (context, state) => const ContextLibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.agentWizard,
          builder: (context, state) {
            final template = state.uri.queryParameters['template'];
            return AgentWizardScreen(selectedTemplate: template);
          },
        ),
        GoRoute(
          path: AppRoutes.integrationHub,
          builder: (context, state) => const ToolsScreen(),
        ),
      ],
    );
  }
  
  String _getInitialRoute() {
    // Simulate the onboarding check logic
    if (widget.storageService != null && widget.apiConfigService != null) {
      final onboardingCompleted = widget.storageService!.getPreference<bool>('onboarding_completed') ?? false;
      final hasApiKeys = widget.apiConfigService!.allApiConfigs.values.any((config) => 
        config['apiKey']?.toString().isNotEmpty ?? false);
      
      if (!onboardingCompleted && !hasApiKeys) {
        return '/onboarding';
      }
    }
    
    return AppRoutes.home;
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Asmbli Test App',
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

/// Simplified home screen for testing
class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asmbli Test'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Manage your AI agents, conversations, and knowledge base'),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TestActionCard(
                  title: 'Start Chat',
                  description: 'Begin new conversation',
                  route: AppRoutes.chat,
                ),
                TestActionCard(
                  title: 'Build Agent',
                  description: 'Create custom AI agent',
                  route: AppRoutes.agentWizard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simplified action card for testing
class TestActionCard extends StatelessWidget {
  final String title;
  final String description;
  final String route;
  
  const TestActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.route,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        width: 200,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}