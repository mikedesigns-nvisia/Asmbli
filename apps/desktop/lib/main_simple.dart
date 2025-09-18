import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/design_system.dart';
import 'features/agents/presentation/widgets/agent_terminal_widget.dart';
import 'features/agents/presentation/widgets/mcp_server_logs_widget.dart';
import 'features/settings/presentation/widgets/security_policy_widget.dart';
import 'features/settings/presentation/widgets/agent_permissions_widget.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgentEngine Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Fustat',
      ),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(SpacingTokens.headerPadding),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'AgentEngine',
                    style: TextStyles.brandTitle.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'UI Components Demo',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.terminal), text: 'Terminal'),
                  Tab(icon: Icon(Icons.bug_report), text: 'Server Logs'),
                  Tab(icon: Icon(Icons.security), text: 'Security'),
                  Tab(icon: Icon(Icons.admin_panel_settings), text: 'Permissions'),
                ],
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.primary,
              ),
            ),

            // Tab content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Terminal Demo
                    AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agent Terminal',
                              style: TextStyles.pageTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            const Expanded(
                              child: AgentTerminalWidget(
                                agentId: 'demo-agent',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Server Logs Demo
                    AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MCP Server Logs',
                              style: TextStyles.pageTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            const Expanded(
                              child: MCPServerLogsWidget(
                                agentId: 'demo-agent',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Security Demo
                    AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Policies',
                              style: TextStyles.pageTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            const Expanded(
                              child: SecurityPolicyWidget(
                                agentId: 'demo-agent',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Permissions Demo
                    AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agent Permissions',
                              style: TextStyles.pageTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            const Expanded(
                              child: AgentPermissionsWidget(
                                agentId: 'demo-agent',
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
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}