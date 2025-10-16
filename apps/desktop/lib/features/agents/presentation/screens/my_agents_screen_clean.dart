import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/agent_provider.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../widgets/enhanced_agent_card.dart';
import '../widgets/enhanced_agent_template_card.dart';
import '../../../agents/data/models/agent_template.dart';

class MyAgentsScreenClean extends ConsumerStatefulWidget {
  const MyAgentsScreenClean({super.key});

  @override
  ConsumerState<MyAgentsScreenClean> createState() => _MyAgentsScreenCleanState();
}

class _MyAgentsScreenCleanState extends ConsumerState<MyAgentsScreenClean> {
  int selectedTab = 0; // 0 = My Agents, 1 = Agent Library
  String searchQuery = '';
  String selectedCategory = 'All';
  String agentSearchQuery = '';
  AgentStatus? selectedAgentStatus;
  String agentSortBy = 'name'; // 'name', 'created', 'status', 'lastUsed'
  bool sortAscending = true;

  final List<String> categories = [
    'All', 'Research', 'Development', 'Writing', 'Data Analysis', 
    'Customer Support', 'Marketing', 'Design', 'DevOps', 'Security',
    'Product', 'Database', 'API', 'Blockchain', 'QA', 'AI/ML',
    'Content Creation', 'IoT', 'Gaming', 'Robotics', 'AR/VR',
    'Quantum', 'Bioinformatics', 'Finance', 'E-commerce', 'Cloud',
    'Automation', 'Mobile', 'Real Estate', 'Legal', 'Healthcare'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              ThemeColors(context).backgroundGradientStart,
              ThemeColors(context).backgroundGradientMiddle,
              ThemeColors(context).backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const AppNavigationBar(currentRoute: AppRoutes.agents),

              // Compact Header with Inline Tabs
              _buildCompactHeaderWithTabs(),

              // Main Content - Direct content without redundant wrapper
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(SpacingTokens.xxl, SpacingTokens.sm, SpacingTokens.xxl, SpacingTokens.xxl),
                  child: selectedTab == 0 ? _buildMyAgentsContent() : _buildAgentLibraryContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeaderWithTabs() {
    final colors = ThemeColors(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Main header with integrated tabs on same line
          Padding(
            padding: const EdgeInsets.fromLTRB(SpacingTokens.xxl, SpacingTokens.lg, SpacingTokens.xxl, SpacingTokens.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon and Title
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedTab == 0 ? 'My AI Agents' : 'Agent Library',
                      style: TextStyles.headingMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      selectedTab == 0 
                        ? 'Manage and organize your AI-powered assistants'
                        : 'Start with a pre-built template and customize it to your needs',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: SpacingTokens.lg),
                
                // Tab buttons inline with title
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(),
                      _TabButton(
                        text: 'My Agents',
                        isSelected: selectedTab == 0,
                        onTap: () => setState(() => selectedTab = 0),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      _TabButton(
                        text: 'Agent Library',
                        isSelected: selectedTab == 1,
                        onTap: () => setState(() => selectedTab = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keep all other methods the same...
  Widget _buildMyAgentsContent() {
    // Implementation here - simplified for now
    return const Center(child: Text('My Agents Content'));
  }

  Widget _buildAgentLibraryContent() {
    // Implementation here - simplified for now  
    return const Center(child: Text('Agent Library Content'));
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return isSelected 
      ? AsmblButton.primary(text: text, onPressed: onTap)
      : AsmblButton.secondary(text: text, onPressed: onTap);
  }
}