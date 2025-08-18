import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../agent_builder/pages/asmbli_agent_builder.dart';
import '../../agent_builder/models/agent_config.dart';
import '../../agent_builder/services/agent_builder_service.dart';
import '../layout/layout.dart';
import '../../provider/chat_provider.dart';
import '../../provider/chat_model_provider.dart';

class AsmbliHome extends StatefulWidget {
  const AsmbliHome({super.key});

  @override
  State<AsmbliHome> createState() => _AsmbliHomeState();
}

class _AsmbliHomeState extends State<AsmbliHome> {
  PageMode _currentMode = PageMode.welcome;
  AgentConfig? _deployedAgent;
  List<AgentConfig> _savedAgents = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAgents();
  }

  Future<void> _loadSavedAgents() async {
    final agents = await AgentBuilderService.loadSavedAgents();
    setState(() {
      _savedAgents = agents;
    });
  }

  void _switchToMode(PageMode mode, {AgentConfig? agent}) {
    setState(() {
      _currentMode = mode;
      if (agent != null) {
        _deployedAgent = agent;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentMode) {
      case PageMode.welcome:
        return _buildWelcomeScreen();
      case PageMode.agentBuilder:
        return AsmbliAgentBuilder(
          onDeploy: (config) => _switchToMode(PageMode.chat, agent: config),
          onBack: () => _switchToMode(PageMode.welcome),
        );
      case PageMode.chat:
        return LayoutPage(
          deployedAgent: _deployedAgent,
          onBackToHome: () => _switchToMode(PageMode.welcome),
        );
    }
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
            ? AsmbliDesignSystem.darkGradient
            : AsmbliDesignSystem.lightGradient,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(AsmbliDesignSystem.space6),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AsmbliDesignSystem.space10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildMainOptions(),
                          ),
                          const SizedBox(width: AsmbliDesignSystem.space6),
                          Expanded(
                            flex: 2,
                            child: _buildSavedAgents(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AsmbliDesignSystem.space3),
              decoration: BoxDecoration(
                gradient: AsmbliDesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusLg),
                boxShadow: AsmbliDesignSystem.shadowGlow,
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: AsmbliDesignSystem.space4),
            Text(
              'ASMBLI',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                background: Paint()
                  ..shader = AsmbliDesignSystem.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Text(
          'AI Agent Configuration Platform',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMainOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOptionCard(
          title: 'Build New Agent',
          subtitle: 'Create a custom AI agent tailored to your needs',
          icon: Icons.build_circle,
          color: AsmbliDesignSystem.primaryIndigo,
          features: [
            'Visual agent configuration',
            'Pre-built templates & roles',
            'MCP server integration',
            'Real-time preview',
          ],
          onTap: () => _switchToMode(PageMode.agentBuilder),
        ),
        const SizedBox(height: AsmbliDesignSystem.space4),
        _buildOptionCard(
          title: 'Deploy Existing Agent',
          subtitle: 'Use a pre-configured agent or template',
          icon: Icons.rocket_launch_outlined,
          color: AsmbliDesignSystem.secondaryPurple,
          features: [
            'Quick deployment',
            'Production-ready configs',
            'Enterprise templates',
            'Team collaboration',
          ],
          onTap: () {
            if (_savedAgents.isNotEmpty) {
              _switchToMode(PageMode.chat, agent: _savedAgents.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No saved agents found. Build one first!'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: AsmbliDesignSystem.space4),
        _buildOptionCard(
          title: 'Quick Start Chat',
          subtitle: 'Jump directly into ASMBLI Chat with default settings',
          icon: Icons.chat_bubble_outline,
          color: AsmbliDesignSystem.accentGreen,
          features: [
            'Instant access',
            'Default configuration',
            'Basic MCP tools',
            'Perfect for testing',
          ],
          onTap: () => _switchToMode(PageMode.chat),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AsmbliCard(
      onTap: onTap,
      showGlow: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AsmbliDesignSystem.space4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: AsmbliDesignSystem.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AsmbliDesignSystem.space1),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AsmbliDesignSystem.space3),
                Wrap(
                  spacing: AsmbliDesignSystem.space2,
                  runSpacing: AsmbliDesignSystem.space1,
                  children: features.map((feature) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AsmbliDesignSystem.accentGreen,
                      ),
                      const SizedBox(width: AsmbliDesignSystem.space1),
                      Text(
                        feature,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  )).toList(),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAgents() {
    final theme = Theme.of(context);
    
    return AsmbliCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Agents',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSavedAgents,
              ),
            ],
          ),
          const SizedBox(height: AsmbliDesignSystem.space3),
          Expanded(
            child: _savedAgents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: AsmbliDesignSystem.space3),
                        Text(
                          'No agents yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: AsmbliDesignSystem.space2),
                        Text(
                          'Build your first agent to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _savedAgents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AsmbliDesignSystem.space2),
                    itemBuilder: (context, index) {
                      final agent = _savedAgents[index];
                      return _buildAgentTile(agent);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentTile(AgentConfig agent) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(agent.role);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AsmbliDesignSystem.space3,
        vertical: AsmbliDesignSystem.space2,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AsmbliDesignSystem.space2),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
        ),
        child: Icon(
          _getRoleIcon(agent.role),
          color: roleColor,
          size: 24,
        ),
      ),
      title: Text(
        agent.name,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        agent.description,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${agent.extensions.length} tools',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(width: AsmbliDesignSystem.space2),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _switchToMode(PageMode.chat, agent: agent),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'developer':
        return AsmbliDesignSystem.roleDeveloper;
      case 'creator':
        return AsmbliDesignSystem.roleCreator;
      case 'researcher':
        return AsmbliDesignSystem.roleResearcher;
      case 'enterprise':
        return AsmbliDesignSystem.roleEnterprise;
      default:
        return AsmbliDesignSystem.primaryIndigo;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'developer':
        return Icons.code;
      case 'creator':
        return Icons.palette;
      case 'researcher':
        return Icons.science;
      case 'enterprise':
        return Icons.business;
      default:
        return Icons.smart_toy;
    }
  }
}

enum PageMode {
  welcome,
  agentBuilder,
  chat,
}

// Extension to update AsmbliAgentBuilder
extension AsmbliAgentBuilderExtension on AsmbliAgentBuilder {
  static Widget withCallbacks({
    required Function(AgentConfig) onDeploy,
    required VoidCallback onBack,
  }) {
    return _AsmbliAgentBuilderWrapper(
      onDeploy: onDeploy,
      onBack: onBack,
    );
  }
}

class _AsmbliAgentBuilderWrapper extends StatelessWidget {
  final Function(AgentConfig) onDeploy;
  final VoidCallback onBack;

  const _AsmbliAgentBuilderWrapper({
    required this.onDeploy,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBack();
        return false;
      },
      child: AsmbliAgentBuilder(),
    );
  }
}