import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/design_system.dart';
import 'core/constants/routes.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/templates/presentation/screens/templates_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/agents/presentation/screens/my_agents_screen.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/desktop/desktop_service_provider.dart';
import 'core/services/desktop/window_management_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop services
  try {
    await DesktopServiceProvider.instance.initialize();
    print('✓ Desktop services initialized');
  } catch (e) {
    print('Desktop services initialization failed: $e');
    // Fallback to legacy storage
    try {
      await Hive.initFlutter('asmbli_app_data');
      await StorageService.init();
    } catch (e2) {
      print('Fallback storage initialization failed: $e2');
    }
  }

  // Configure desktop window
  if (DesktopServiceProvider.instance.isDesktop) {
    try {
      await DesktopServiceProvider.instance.windowManager.configureWindow(
        const DesktopWindowOptions(
          size: Size(1400, 900),
          minimumSize: Size(1000, 700),
          center: true,
          title: 'AgentEngine - Desktop',
          backgroundColor: Colors.transparent,
        ),
      );
      print('✓ Window configured');
    } catch (e) {
      print('Window configuration failed: $e');
    }
  }

  runApp(
    ProviderScope(
      child: AsmblDesktopApp(),
    ),
  );
}

class AsmblDesktopApp extends ConsumerWidget {
  const AsmblDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeServiceProvider);
    
    return MaterialApp.router(
      title: 'Asmbli - AI Agents Made Easy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Create router outside of the widget to avoid global key issues
final _router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.templates,
      builder: (context, state) => const TemplatesScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.agents,
      builder: (context, state) => const MyAgentsScreen(),
    ),
  ],
);

/// Dashboard-style home screen focused on app functionality
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SemanticColors.backgroundGradientStart,
              SemanticColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Header
              const AppNavigationBar(currentRoute: AppRoutes.home),
              
              // Main Dashboard Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(SpacingTokens.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Text(
                        'Welcome back!',
                        style: TextStyles.pageTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Manage your AI agents and start new conversations',
                        style: TextStyles.bodyLarge.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                      
                      const SizedBox(height: SpacingTokens.sectionSpacing),
                      
                      // Quick Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.chat_bubble_outline,
                              title: 'Start New Chat',
                              description: 'Begin a conversation with your AI agents',
                              onTap: () => context.go(AppRoutes.chat),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.lg),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.library_add,
                              title: 'Browse Templates',
                              description: 'Explore pre-built agent configurations',
                              onTap: () => context.go(AppRoutes.templates),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.lg),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.build,
                              title: 'Create Agent',
                              description: 'Build a custom agent from scratch',
                              onTap: () => context.go(AppRoutes.dashboard),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: SpacingTokens.sectionSpacing),
                      
                      // Recent Activity & My Agents sections
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recent Activity
                          Expanded(
                            flex: 2,
                            child: _DashboardSection(
                              title: 'Recent Activity',
                              child: Column(
                                children: [
                                  _ActivityItem(
                                    icon: Icons.chat,
                                    title: 'Chat with Research Assistant',
                                    subtitle: '2 minutes ago',
                                    onTap: () => context.go(AppRoutes.chat),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.edit,
                                    title: 'Modified Code Review Agent',
                                    subtitle: '1 hour ago',
                                    onTap: () => context.go(AppRoutes.dashboard),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.download,
                                    title: 'Installed Notion MCP Server',
                                    subtitle: 'Yesterday',
                                    onTap: () => context.go(AppRoutes.settings),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.library_books,
                                    title: 'Used Writing Assistant template',
                                    subtitle: '2 days ago',
                                    onTap: () => context.go(AppRoutes.templates),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: SpacingTokens.xxl),
                          
                          // My Agents
                          Expanded(
                            child: _DashboardSection(
                              title: 'My Agents',
                              child: Column(
                                children: [
                                  _AgentCard(
                                    name: 'Research Assistant',
                                    description: 'Helps with research tasks and analysis',
                                    isActive: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _AgentCard(
                                    name: 'Code Reviewer',
                                    description: 'Reviews code and suggests improvements',
                                    isActive: false,
                                  ),
                                  const SizedBox(height: 12),
                                  _AgentCard(
                                    name: 'Writing Assistant',
                                    description: 'Helps with writing and editing',
                                    isActive: true,
                                  ),
                                  const SizedBox(height: 16),
                                  AsmblButton.primary(
                                    text: 'Create New Agent',
                                    icon: Icons.add,
                                    onPressed: () => context.go(AppRoutes.dashboard),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Quick action card for dashboard
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AsmblCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              icon,
              size: 24,
              color: SemanticColors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            title,
            style: TextStyles.cardTitle.copyWith(
              color: SemanticColors.onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            description,
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard section container
class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AsmblCard(
      isInteractive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.sectionTitle.copyWith(
              color: SemanticColors.onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          child,
        ],
      ),
    );
  }
}

// Activity item for recent activity list
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        hoverColor: SemanticColors.primary.withOpacity(0.04),
        splashColor: SemanticColors.primary.withOpacity(0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.md,
            horizontal: SpacingTokens.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: SemanticColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bodyMedium.copyWith(
                        color: SemanticColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      subtitle,
                      style: TextStyles.caption.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Agent card for my agents section
class _AgentCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isActive;

  const _AgentCard({
    required this.name,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: SemanticColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: isActive 
            ? SemanticColors.primary.withOpacity(0.3)
            : SemanticColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? SemanticColors.success : SemanticColors.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyles.bodyMedium.copyWith(
                    color: SemanticColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  description,
                  style: TextStyles.caption.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}