import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/design_system.dart';
import 'core/constants/routes.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/templates/presentation/screens/templates_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/agents/presentation/screens/my_agents_screen.dart';
import 'features/context/presentation/screens/context_screen.dart';
import 'features/context/presentation/providers/context_provider.dart';
import 'features/context/data/models/context_document.dart';
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
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.agents,
      builder: (context, state) => const MyAgentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.context,
      builder: (context, state) => const ContextScreen(),
    ),
  ],
);

/// Dashboard-style home screen focused on app functionality
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
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
                  padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Text(
                        'Welcome back!',
                        style: TextStyles.pageTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.iconSpacing),
                      Text(
                        'Manage your AI agents and start new conversations',
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurfaceVariant,
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
                          const SizedBox(width: SpacingTokens.elementSpacing),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.library_add,
                              title: 'Browse Templates',
                              description: 'Explore pre-built agent configurations',
                              onTap: () => context.go(AppRoutes.templates),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.elementSpacing),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.build,
                              title: 'Create Agent',
                              description: 'Build a custom agent from scratch',
                              onTap: () => context.go(AppRoutes.agents),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: SpacingTokens.sectionSpacing),
                      
                      // Recent Activity, Context & My Agents sections
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
                                    onTap: () => context.go(AppRoutes.agents),
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
                          
                          const SizedBox(width: SpacingTokens.elementSpacing),
                          
                          // Context Documents
                          Expanded(
                            child: _ContextDocumentsSection(),
                          ),
                          
                          const SizedBox(width: SpacingTokens.elementSpacing),
                          
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
                                    onPressed: () => context.go(AppRoutes.agents),
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
            padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
            decoration: BoxDecoration(
              color: ThemeColors(context).primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              icon,
              size: 24,
              color: ThemeColors(context).primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          Text(
            title,
            style: TextStyles.cardTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.iconSpacing),
          Text(
            description,
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
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
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          child,
        ],
      ),
    );
  }
}

// Enhanced dashboard section container
class _DashboardSectionEnhanced extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardSectionEnhanced({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AsmblCardEnhanced.outlined(
      isInteractive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.sectionTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
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
        hoverColor: ThemeColors(context).primary.withOpacity(0.04),
        splashColor: ThemeColors(context).primary.withOpacity(0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.componentSpacing,
            horizontal: SpacingTokens.xs_precise,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: ThemeColors(context).onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bodyMedium.copyWith(
                        color: ThemeColors(context).onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      subtitle,
                      style: TextStyles.caption.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
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
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: ThemeColors(context).surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: isActive 
            ? ThemeColors(context).primary.withOpacity(0.3)
            : ThemeColors(context).border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? ThemeColors(context).success : ThemeColors(context).onSurfaceVariant,
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
                    color: ThemeColors(context).onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  description,
                  style: TextStyles.caption.copyWith(
                    color: ThemeColors(context).onSurfaceVariant,
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

// Context documents section widget for the home dashboard
class _ContextDocumentsSection extends ConsumerWidget {
  const _ContextDocumentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final contextDocuments = ref.watch(contextDocumentsProvider);
    
    return _DashboardSectionEnhanced(
      title: 'Context Documents',
      child: contextDocuments.when(
        data: (documents) {
          final recentDocuments = documents.take(3).toList();
          
          if (documents.isEmpty) {
            return Column(
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 32,
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: SpacingTokens.iconSpacing),
                Text(
                  'No context documents yet',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.componentSpacing),
                AsmblButtonEnhanced.accent(
                  text: 'Create Document',
                  icon: Icons.add,
                  onPressed: () => context.go(AppRoutes.context),
                  size: AsmblButtonSize.medium,
                ),
              ],
            );
          }
          
          return Column(
            children: [
              ...recentDocuments.map((document) => Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
                child: _ContextDocumentItem(document: document),
              )),
              if (documents.length > 3) ...[
                const SizedBox(height: SpacingTokens.iconSpacing),
                Text(
                  '+${documents.length - 3} more',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: SpacingTokens.componentSpacing),
              AsmblButtonEnhanced.outline(
                text: 'Manage Context',
                icon: Icons.library_books,
                onPressed: () => context.go(AppRoutes.context),
                size: AsmblButtonSize.medium,
              ),
            ],
          );
        },
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: colors.error,
            ),
            const SizedBox(height: SpacingTokens.iconSpacing),
            Text(
              'Failed to load context',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            AsmblButtonEnhanced.secondary(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(contextDocumentsProvider),
              size: AsmblButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}

// Context document item for home dashboard
class _ContextDocumentItem extends StatelessWidget {
  final ContextDocument document;

  const _ContextDocumentItem({required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.context),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        hoverColor: colors.primary.withOpacity(0.04),
        splashColor: colors.primary.withOpacity(0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.iconSpacing,
            horizontal: SpacingTokens.xs_precise,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: _getTypeColor(document.type, colors),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  _getTypeIcon(document.type),
                  size: 16,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: SpacingTokens.iconSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      document.type.displayName,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
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

  Color _getTypeColor(ContextType type, ThemeColors colors) {
    switch (type) {
      case ContextType.documentation:
        return colors.primary;
      case ContextType.codebase:
        return colors.info;
      case ContextType.guidelines:
        return colors.warning;
      case ContextType.examples:
        return colors.success;
      case ContextType.knowledge:
        return colors.primary.withOpacity(0.8);
      case ContextType.custom:
        return colors.onSurfaceVariant;
    }
  }

  IconData _getTypeIcon(ContextType type) {
    switch (type) {
      case ContextType.documentation:
        return Icons.description;
      case ContextType.codebase:
        return Icons.code;
      case ContextType.guidelines:
        return Icons.rule;
      case ContextType.examples:
        return Icons.lightbulb;
      case ContextType.knowledge:
        return Icons.school;
      case ContextType.custom:
        return Icons.note;
    }
  }
}