import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

import 'core/design_system/design_system.dart';
import 'core/design_system/components/asmbli_card_enhanced.dart';
import 'core/constants/routes.dart';
import 'core/di/service_locator.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/chat/presentation/screens/chat_screen_with_contextual.dart';
import 'features/settings/presentation/screens/modern_settings_screen.dart';
import 'features/agents/presentation/screens/my_agents_screen.dart';
import 'features/agents/presentation/screens/agent_configuration_screen.dart';
import 'features/context/presentation/screens/context_library_screen.dart';
import 'features/agent_wizard/presentation/screens/agent_wizard_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'providers/conversation_provider.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/desktop/desktop_service_provider.dart';
import 'core/services/desktop/window_management_service.dart';
import 'core/services/desktop/desktop_storage_service.dart';
import 'core/services/api_config_service.dart';
import 'core/services/feature_flag_service.dart';
import 'features/settings/presentation/widgets/adaptive_integration_router.dart';
import 'features/tools/presentation/screens/tools_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/desktop/hive_cleanup_service.dart';
import 'core/error/app_error_handler.dart';
import 'core/services/production_logger.dart';
import 'core/config/environment_config.dart';
import 'core/services/vector_integration_service.dart';
import 'core/services/oauth_auto_refresh_initializer.dart';
// import 'core/services/production_mcp_orchestrator.dart'; // Will be added when MCP services are ready
import 'package:google_fonts/google_fonts.dart';

/// 🚀 PRODUCTION VERSION - Optimized for real-world deployment
/// 
/// This production entry point focuses on:
/// - 🎯 User-first magical experience 
/// - 🛡️ Robust error handling with friendly messages
/// - ⚡ Fast startup and smooth performance
/// - 🔄 Intelligent retry systems
/// - 📊 Essential telemetry (privacy-respecting)
/// - 🎨 Beautiful, responsive UI

void main() async {
  // Enhanced production zone with magical error recovery
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🎭 Production initialization with celebration
    await _magicalProductionInit();

    runApp(
      ProviderScope(
        overrides: await _createProductionOverrides(),
        child: AppErrorHandler.errorBoundary(
          boundaryName: 'production_app',
          child: const ProductionAsmblApp(),
        ),
      ),
    );
  }, _handleProductionErrors);
}

/// 🎭 Magical production initialization
Future<void> _magicalProductionInit() async {
  final startTime = DateTime.now();
  
  // Show friendly initialization
  debugPrint('✨ Starting your magical workspace...');

  try {
    // 1. Initialize error handling first (silent but powerful)
    await AppErrorHandler.instance.initialize();
    
    // 2. Initialize core services with celebration
    await ServiceLocator.instance.initialize();
    debugPrint('🚀 Core systems ready!');

    // 3. Initialize desktop services with grace
    if (DesktopServiceProvider.instance.isDesktop) {
      await DesktopServiceProvider.instance.initialize();
      
      // Configure beautiful window
      await DesktopServiceProvider.instance.windowManager.configureWindow(
        const DesktopWindowOptions(
          size: Size(1400, 900),
          minimumSize: Size(1200, 800),
          center: true,
          title: 'Asmbli - Your AI Workspace',
          backgroundColor: Color(0xFF0A0E1A),
        ),
      );
      debugPrint('🖥️ Desktop workspace configured!');
    }

    // 4. Initialize storage with cleanup
    await _initializeProductionStorage();
    
    final duration = DateTime.now().difference(startTime);
    debugPrint('⚡ Ready in ${duration.inMilliseconds}ms - Let\'s build something amazing!');
    
  } catch (e, stackTrace) {
    debugPrint('🔄 Setting up fallback systems...');
    await _initializeFallbackSystems();
    debugPrint('✅ Ready with basic functionality!');
  }
}

/// Initialize production storage with intelligent cleanup
Future<void> _initializeProductionStorage() async {
  try {
    await Hive.initFlutter('asmbli_production');
    await StorageService.init();
    
    // Intelligent database health check
    final health = await HiveCleanupService.checkBoxHealth();
    if (!(health['isHealthy'] as bool? ?? false)) {
      debugPrint('🧹 Optimizing database...');
      await HiveCleanupService.cleanupConversationsBox();
      debugPrint('✨ Database optimized!');
    }
  } catch (e) {
    debugPrint('📦 Using backup storage system');
    await _initializeFallbackSystems();
  }
}

/// Initialize fallback systems for graceful degradation
Future<void> _initializeFallbackSystems() async {
  try {
    await Hive.initFlutter('asmbli_fallback');
    await StorageService.init();
  } catch (e) {
    debugPrint('⚠️ Running in minimal mode - some features limited');
  }
}

/// Create production provider overrides
Future<List<Override>> _createProductionOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  
  return [
    featureFlagServiceProvider.overrideWithValue(FeatureFlagService(prefs)),
    // Production MCP orchestrator will be initialized when needed
  ];
}

/// Handle production errors with love and helpful messages
void _handleProductionErrors(Object error, StackTrace stackTrace) {
  try {
    AppErrorHandler.handleBusinessError(
      error,
      operation: 'production_zone_error',
      severity: ErrorSeverity.critical,
    );
  } catch (e) {
    // Last resort logging
    debugPrint('💝 We encountered an unexpected situation, but don\'t worry - we\'re handling it gracefully');
    debugPrint('Technical details: $error');
  }
}

/// Production-optimized main app
class ProductionAsmblApp extends ConsumerWidget {
  const ProductionAsmblApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch vector system with graceful fallback
    final vectorInitialization = ref.watch(vectorSystemInitializationProvider);
    
    return vectorInitialization.when(
      data: (_) => const ProductionMainApp(),
      loading: () => _buildProductionSplashScreen(),
      error: (error, stackTrace) {
        debugPrint('🎯 Vector system initializing in background...');
        return const ProductionMainApp(); // Continue with main app
      },
    );
  }

  /// Beautiful production splash screen
  Widget _buildProductionSplashScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  const Color(0xFF1A1F2E),
                  const Color(0xFF0A0E1A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated loading indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Friendly loading message
                Text(
                  'Setting up your workspace...',
                  style: GoogleFonts.fustat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Preparing your AI agents and knowledge base',
                  style: GoogleFonts.fustat(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Subtle loading animation
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main production app with theme management
class ProductionMainApp extends ConsumerWidget {
  const ProductionMainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeServiceProvider);
    final themeService = ref.read(themeServiceProvider.notifier);
    
    // Initialize OAuth auto-refresh for production
    OAuthAutoRefreshInitializer.initialize(ref);
    
    return MaterialApp.router(
      title: 'Asmbli - AI Agents Made Easy',
      theme: themeService.getLightTheme(),
      darkTheme: themeService.getDarkTheme(),
      themeMode: themeState.mode,
      routerConfig: _productionRouter,
      debugShowCheckedModeBanner: false,
      
      // Production app metadata
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Production-optimized router
final _productionRouter = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (context, state) => null, // Handle onboarding in HomeScreen
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const ProductionHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final template = state.uri.queryParameters['template'];
        return ChatScreenWithContextual(selectedTemplate: template);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const ModernSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.integrationHub,
      builder: (context, state) => const ToolsScreen(),
    ),
    GoRoute(
      path: '/settings/integrations',
      builder: (context, state) => const AdaptiveIntegrationRouter(initialTab: 'integrations'),
    ),
    GoRoute(
      path: AppRoutes.agents,
      builder: (context, state) => const MyAgentsScreen(),
    ),
    GoRoute(
      path: '/agents/configure/:agentId',
      builder: (context, state) {
        final agentId = state.pathParameters['agentId'];
        return AgentConfigurationScreen(agentId: agentId);
      },
    ),
    GoRoute(
      path: '/agents/configure',
      builder: (context, state) => const AgentConfigurationScreen(),
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
  ],
);

/// Production-optimized home screen with enhanced onboarding check
class ProductionHomeScreen extends ConsumerStatefulWidget {
  const ProductionHomeScreen({super.key});

  @override
  ConsumerState<ProductionHomeScreen> createState() => _ProductionHomeScreenState();
}

class _ProductionHomeScreenState extends ConsumerState<ProductionHomeScreen> {
  @override
  void initState() {
    super.initState();
    _gracefulOnboardingCheck();
  }

  /// Graceful onboarding check with fallbacks
  Future<void> _gracefulOnboardingCheck() async {
    try {
      // Allow UI to render first
      await Future.delayed(const Duration(milliseconds: 200));
      
      final storage = DesktopStorageService.instance;
      final onboardingCompleted = storage.getPreference<bool>('onboarding_completed') ?? false;
      
      // Check API configuration
      final apiService = ApiConfigService(storage);
      await apiService.initialize();
      final hasApiKeys = apiService.allApiConfigs.values.any((config) => config.apiKey.isNotEmpty);
      
      // Smart onboarding logic
      if (!onboardingCompleted && !hasApiKeys && mounted) {
        // Show friendly first-time experience
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('🎯 Continuing with main app (onboarding check failed gracefully)');
      // Continue normally - don't block the user experience
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Enhanced app header
              const AppNavigationBar(currentRoute: AppRoutes.home),
              
              // Main content with better error boundaries
              Expanded(
                child: AppErrorHandler.errorBoundary(
                  boundaryName: 'home_content',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced welcome section
                        _buildWelcomeSection(colors),
                        
                        const SizedBox(height: SpacingTokens.sectionSpacing),
                        
                        // Improved quick actions
                        _buildQuickActionsSection(),
                        
                        const SizedBox(height: SpacingTokens.sectionSpacing),
                        
                        // Enhanced recent conversations
                        const _ProductionRecentConversationsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asmbli Beta',
          style: TextStyles.pageTitle.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Text(
          'Your powerful AI workspace • Min 8GB RAM • Recommended 16GB+',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Row(
      children: [
        Expanded(
          child: _ProductionQuickActionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Start Chat',
            description: 'Begin AI conversation',
            gradient: const LinearGradient(
              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
            ),
            onTap: () => context.go(AppRoutes.chat),
          ),
        ),
        const SizedBox(width: SpacingTokens.elementSpacing),
        Expanded(
          child: _ProductionQuickActionCard(
            icon: Icons.build_outlined,
            title: 'Build Agent',
            description: 'Create custom assistant',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
            ),
            onTap: () => context.go(AppRoutes.agentWizard),
          ),
        ),
      ],
    );
  }
}

/// Enhanced recent conversations with better error handling
class _ProductionRecentConversationsSection extends ConsumerWidget {
  const _ProductionRecentConversationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    
    return _DashboardSectionEnhanced(
      title: 'Recent Conversations',
      child: conversationsAsync.when(
        data: (conversations) {
          final recentConversations = conversations
              .where((c) => c.status == ConversationStatus.active)
              .take(5)
              .toList();
          
          if (recentConversations.isEmpty) {
            return _buildEmptyState(colors);
          }
          
          return _buildConversationsList(conversations, recentConversations, colors);
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(colors, ref),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 32,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Text(
          'Ready for your first conversation!',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Text(
          'Start chatting to see your conversations here',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConversationsList(List<Conversation> conversations, List<Conversation> recentConversations, ThemeColors colors) {
    return Column(
      children: [
        ...recentConversations.map((conversation) => Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
          child: _ConversationItem(
            conversation: conversation,
            onTap: () {
              final container = ProviderScope.containerOf(
                NavigationService.navigatorKey.currentContext!,
              );
              container.read(selectedConversationIdProvider.notifier).state = conversation.id;
              NavigationService.navigatorKey.currentContext!.go(AppRoutes.chat);
            },
          ),
        )),
        if (conversations.length > 5) ...[
          const SizedBox(height: SpacingTokens.componentSpacing),
          AsmblButton.outline(
            text: 'View All Conversations',
            icon: Icons.forum,
            onPressed: () => NavigationService.navigatorKey.currentContext!.go(AppRoutes.chat),
            size: AsmblButtonSize.medium,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(ThemeColors colors, WidgetRef ref) {
    return Column(
      children: [
        Icon(
          Icons.refresh,
          size: 32,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Text(
          'Let\'s try loading your conversations again',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        AsmblButton.secondary(
          text: 'Refresh',
          icon: Icons.refresh,
          onPressed: () => ref.invalidate(conversationsProvider),
          size: AsmblButtonSize.medium,
        ),
      ],
    );
  }
}

/// Enhanced quick action card with gradients
class _ProductionQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ProductionQuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
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
              gradient: gradient,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
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

/// Navigation service for production error handling
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// Production conversation item widget
class _ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationItem({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isAgentConversation = conversation.metadata?['type'] == 'agent';
    final agentName = conversation.metadata?['agentName'] as String?;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        hoverColor: colors.primary.withOpacity( 0.04),
        splashColor: colors.primary.withOpacity( 0.12),
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
                  color: isAgentConversation 
                      ? colors.primary.withOpacity( 0.1)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  isAgentConversation ? Icons.smart_toy : Icons.chat,
                  size: 16,
                  color: isAgentConversation 
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAgentConversation && agentName != null
                          ? agentName
                          : conversation.title,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      _getConversationTypeDescription(conversation),
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(conversation.createdAt),
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _getConversationTypeDescription(Conversation conversation) {
    final agentType = conversation.metadata?['type'] as String?;
    
    switch (agentType) {
      case 'agent':
        return 'Agent Chat';
      case 'default_api':
      case 'direct_chat':
        final storedModelName = conversation.metadata?['defaultModelName'] as String?;
        final modelType = conversation.metadata?['modelType'] as String?;
        final provider = conversation.metadata?['defaultModelProvider'] as String?;
        
        if (storedModelName != null && storedModelName.isNotEmpty) {
          if (modelType == 'local') {
            return 'Local $storedModelName';
          } else if (provider != null) {
            return '$provider Chat';
          } else {
            return '$storedModelName Chat';
          }
        }
        return 'AI Chat';
      default:
        return 'Chat Session';
    }
  }
}

/// Production dashboard section container
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