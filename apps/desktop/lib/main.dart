import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/design_system.dart';
import 'core/constants/routes.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/chat/presentation/screens/demo_chat_screen.dart'; // Remove after video
import 'features/templates/presentation/screens/templates_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
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
import 'features/settings/presentation/screens/integration_center_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
 WidgetsFlutterBinding.ensureInitialized();

 // Initialize desktop services
 try {
 await DesktopServiceProvider.instance.initialize();
 // Desktop services initialized successfully
 } catch (e) {
 // Desktop services initialization failed - using fallback
 // Fallback to legacy storage
 try {
 await Hive.initFlutter('asmbli_app_data');
 await StorageService.init();
 } catch (e2) {
 // Fallback storage initialization failed
 }
 }

 // Configure desktop window
 if (DesktopServiceProvider.instance.isDesktop) {
 try {
 await DesktopServiceProvider.instance.windowManager.configureWindow(
 DesktopWindowOptions(
 size: Size(1400, 900),
 minimumSize: Size(1000, 700),
 center: true,
 title: 'Asmbli - Desktop',
 backgroundColor: Colors.transparent,
 ),
 );
 // Window configured successfully
 } catch (e) {
 // Window configuration failed
 }
 }

 // Initialize SharedPreferences for feature flags
 final prefs = await SharedPreferences.getInstance();
 
 runApp(
 ProviderScope(
 overrides: [
 featureFlagServiceProvider.overrideWithValue(FeatureFlagService(prefs)),
 ],
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
 redirect: (context, state) {
   // We'll handle onboarding check in HomeScreen instead
   return null;
 },
 routes: [
 GoRoute(
 path: '/onboarding',
 builder: (context, state) => const OnboardingScreen(),
 ),
 GoRoute(
 path: AppRoutes.home,
 builder: (context, state) => HomeScreen(),
 ),
 GoRoute(
 path: AppRoutes.chat,
 builder: (context, state) => const ChatScreen(),
 ),
 // Demo route for video recording (remove after video)
 GoRoute(
 path: AppRoutes.demoChat,
 builder: (context, state) => const DemoChatScreen(),
 ),
 GoRoute(
 path: AppRoutes.templates,
 builder: (context, state) => const TemplatesScreen(),
 ),
 GoRoute(
 path: AppRoutes.settings,
 builder: (context, state) => const ModernSettingsScreen(),
 ),
 GoRoute(
 path: AppRoutes.integrationHub,
 builder: (context, state) => const IntegrationCenterScreen(),
 ),
 // Legacy route redirects to Integration Hub
 GoRoute(
 path: '/settings/integrations',
 builder: (context, state) => const AdaptiveIntegrationRouter(initialTab: 'integrations'),
 ),
 GoRoute(
 path: AppRoutes.agents,
 builder: (context, state) => const MyAgentsScreen(),
 ),
 GoRoute(
 path: '/agents/configure/:agentName',
 builder: (context, state) {
 final agentName = state.pathParameters['agentName'];
 return AgentConfigurationScreen(agentName: agentName);
 },
 ),
 GoRoute(
 path: '/agents/configure',
 builder: (context, state) => AgentConfigurationScreen(),
 ),
 GoRoute(
 path: AppRoutes.context,
 builder: (context, state) => const ContextLibraryScreen(),
 ),
 GoRoute(
  path: AppRoutes.agentWizard,
  builder: (context, state) => const AgentWizardScreen(),
 ),
 ],
);

/// Dashboard-style home screen focused on app functionality
class HomeScreen extends ConsumerStatefulWidget {
 const HomeScreen({super.key});

 @override
 ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
 @override
 void initState() {
   super.initState();
   _checkOnboarding();
 }

 Future<void> _checkOnboarding() async {
   try {
     // Small delay to ensure storage is initialized
     await Future.delayed(Duration(milliseconds: 100));
     
     final storage = DesktopStorageService.instance;
     final onboardingCompleted = storage.getPreference<bool>('onboarding_completed') ?? false;
     
     // Check if any API keys are configured
     final apiService = ApiConfigService(storage);
     await apiService.initialize();
     final hasApiKeys = apiService.allApiConfigs.values.any((config) => config.apiKey.isNotEmpty);
     
     // If not onboarded and no API keys, redirect to onboarding
     if (!onboardingCompleted && !hasApiKeys && mounted) {
       context.go('/onboarding');
     }
   } catch (e) {
     print('Error checking onboarding status: $e');
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
 // App Header
 AppNavigationBar(currentRoute: AppRoutes.home),
 
 // Main Dashboard Content
 Expanded(
 child: SingleChildScrollView(
 padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
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
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 'Manage your AI agents, conversations, and knowledge base',
 style: TextStyles.bodyLarge.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 /* Consumer build - onboarding button removed
 TextButton.icon(
 onPressed: null,
 icon: Icon(Icons.rocket_launch),
 label: Text(''),
 style: TextButton.styleFrom(
 foregroundColor: colors.primary,
 ),
 ),
 
 SizedBox(height: SpacingTokens.md),
*/
 
 // Quick Actions Row
 Row(
 children: [
 Expanded(
 child: _QuickActionCard(
 icon: Icons.chat_bubble_outline,
 title: 'Start Chat',
 description: 'Begin new conversation',
 onTap: () => context.go(AppRoutes.chat),
 ),
 ),
 SizedBox(width: SpacingTokens.elementSpacing),
 Expanded(
 child: _QuickActionCard(
 icon: Icons.build,
 title: 'Build Agent',
 description: 'Create custom AI agent',
 onTap: () => context.go(AppRoutes.agentWizard),
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Main Content - Recent Conversations
 _RecentConversationsSection(),
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

// Recent Conversations Section
class _RecentConversationsSection extends ConsumerWidget {
 const _RecentConversationsSection();

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
 return Column(
 children: [
 Icon(
 Icons.chat_bubble_outline,
 size: 32,
 color: colors.onSurfaceVariant.withValues(alpha: 0.5),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 'No conversations yet',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 );
 }
 
 return Column(
 children: [
 ...recentConversations.map((conversation) => Padding(
 padding: EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
 child: _ConversationItem(
 conversation: conversation,
 onTap: () {
 ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
 context.go(AppRoutes.chat);
 },
 ),
 )),
 if (conversations.length > 5) ...[
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 '+${conversations.length - 5} more conversations',
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButtonEnhanced.outline(
 text: 'View All Chats',
 icon: Icons.forum,
 onPressed: () => context.go(AppRoutes.chat),
 size: AsmblButtonSize.medium,
 ),
 ],
 );
 },
 loading: () => Center(
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
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 'Failed to load conversations',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.error,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButtonEnhanced.secondary(
 text: 'Retry',
 icon: Icons.refresh,
 onPressed: () => ref.invalidate(conversationsProvider),
 size: AsmblButtonSize.medium,
 ),
 ],
 ),
 ),
 );
 }
}

// Conversation item for dashboard
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
 hoverColor: colors.primary.withValues(alpha: 0.04),
 splashColor: colors.primary.withValues(alpha: 0.12),
 child: Container(
 padding: EdgeInsets.symmetric(
 vertical: SpacingTokens.componentSpacing,
 horizontal: SpacingTokens.xs_precise,
 ),
 child: Row(
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.iconSpacing),
 decoration: BoxDecoration(
 color: isAgentConversation 
 ? colors.primary.withValues(alpha: 0.1)
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
 SizedBox(width: SpacingTokens.componentSpacing),
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
 SizedBox(height: SpacingTokens.xs_precise),
 Text(
 isAgentConversation ? 'Agent Chat' : 'Direct API Chat',
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
 padding: EdgeInsets.all(SpacingTokens.iconSpacing),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 icon,
 size: 24,
 color: ThemeColors(context).primary,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 title,
 style: TextStyles.cardTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
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
 SizedBox(height: SpacingTokens.componentSpacing),
 child,
 ],
 ),
 );
 }
}


