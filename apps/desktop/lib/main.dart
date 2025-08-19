import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/templates/presentation/screens/templates_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.init();

  // Initialize window manager for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1400, 900),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      title: 'Asmbli - AI Agents Made Easy',
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      child: AsmblDesktopApp(),
    ),
  );
}

class AsmblDesktopApp extends StatelessWidget {
  AsmblDesktopApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Asmbli - AI Agents Made Easy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Dashboard-style home screen focused on app functionality
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF9F5),
              Color(0xFFFCFAF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  border: Border(bottom: BorderSide(color: AppTheme.lightBorder.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    Text(
                      'Asmbli',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.lightForeground,
                      ),
                    ),
                    const Spacer(),
                    _HeaderButton('Templates', Icons.library_books, () => context.go('/templates')),
                    const SizedBox(width: 16),
                    _HeaderButton('Library', Icons.folder, () => context.go('/dashboard')),
                    const SizedBox(width: 16),
                    _HeaderButton('Settings', Icons.settings, () => context.go('/settings')),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: GestureDetector(
                        onTap: () => context.go('/chat'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: AppTheme.lightPrimaryForeground),
                            SizedBox(width: 8),
                            Text(
                              'New Chat',
                              style: TextStyle(
                                color: AppTheme.lightPrimaryForeground,
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Dashboard Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your AI agents and start new conversations',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 16,
                          color: AppTheme.lightMutedForeground,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Quick Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.chat_bubble_outline,
                              title: 'Start New Chat',
                              description: 'Begin a conversation with your AI agents',
                              onTap: () => context.go('/chat'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.library_add,
                              title: 'Browse Templates',
                              description: 'Explore pre-built agent configurations',
                              onTap: () => context.go('/templates'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.build,
                              title: 'Create Agent',
                              description: 'Build a custom agent from scratch',
                              onTap: () => context.go('/dashboard'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
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
                                    onTap: () => context.go('/chat'),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.edit,
                                    title: 'Modified Code Review Agent',
                                    subtitle: '1 hour ago',
                                    onTap: () => context.go('/dashboard'),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.download,
                                    title: 'Installed Notion MCP Server',
                                    subtitle: 'Yesterday',
                                    onTap: () => context.go('/settings'),
                                  ),
                                  _ActivityItem(
                                    icon: Icons.library_books,
                                    title: 'Used Writing Assistant template',
                                    subtitle: '2 days ago',
                                    onTap: () => context.go('/templates'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 24),
                          
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
                                  GestureDetector(
                                    onTap: () => context.go('/dashboard'),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPrimary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, size: 16, color: AppTheme.lightPrimaryForeground),
                                          SizedBox(width: 8),
                                          Text(
                                            'Create New Agent',
                                            style: TextStyle(
                                              color: AppTheme.lightPrimaryForeground,
                                              fontFamily: 'Space Grotesk',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

// Header button for app navigation
class _HeaderButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton(this.text, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.lightMutedForeground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightForeground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 13,
                color: AppTheme.lightMutedForeground,
                height: 1.4,
              ),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 16),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppTheme.lightMutedForeground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive 
            ? AppTheme.lightPrimary.withOpacity(0.3)
            : AppTheme.lightBorder.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : AppTheme.lightMutedForeground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                    color: AppTheme.lightMutedForeground,
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