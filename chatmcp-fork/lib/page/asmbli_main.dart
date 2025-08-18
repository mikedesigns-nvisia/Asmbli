import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../agent_builder/models/agent_config.dart';
import '../agent_builder/services/agent_builder_service.dart';
import '../provider/chat_provider.dart';
import '../provider/mcp_server_provider.dart';
import '../agent_builder/services/extension_service.dart';
import 'layout/chat_page/chat_page.dart';
import '../agent_builder/pages/agent_builder_page.dart';
import '../agent_builder/pages/role_selection_page.dart';
import '../agent_builder/pages/extensions_selection_page.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform.dart';

class AsmbliMain extends StatefulWidget {
  const AsmbliMain({super.key});

  @override
  State<AsmbliMain> createState() => _AsmbliMainState();
}

class _AsmbliMainState extends State<AsmbliMain> with TickerProviderStateMixin {
  // Navigation state
  NavigationMode _navigationMode = NavigationMode.chat;
  
  // Agent management
  AgentConfig? _activeAgent;
  List<AgentConfig> _savedAgents = [];
  
  // Builder state
  AgentConfig _buildingAgent = AgentConfig(
    name: '',
    description: '',
    role: '',
    purpose: '',
    extensions: [],
    style: AgentStyle(),
  );
  int _builderStep = 0;
  
  // UI state
  bool _sidebarCollapsed = false;
  late AnimationController _sidebarAnimController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedAgents();
    _sidebarAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _sidebarAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAgents() async {
    final agents = await AgentBuilderService.loadSavedAgents();
    setState(() {
      _savedAgents = agents;
      if (_activeAgent == null && agents.isNotEmpty) {
        _activeAgent = agents.first;
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (_sidebarCollapsed) {
        _sidebarAnimController.forward();
      } else {
        _sidebarAnimController.reverse();
      }
    });
  }

  void _switchAgent(AgentConfig agent) {
    setState(() {
      _activeAgent = agent;
      _navigationMode = NavigationMode.chat;
    });
    // Apply agent configuration to chat
    _applyAgentToChat(agent);
  }

  void _applyAgentToChat(AgentConfig agent) async {
    // Start MCP servers based on agent extensions
    final mcpProvider = Provider.of<McpServerProvider>(context, listen: false);
    
    // Map extensions to MCP servers and start them
    for (final extension in agent.extensions) {
      // Check if this extension corresponds to an MCP server
      final serverName = _mapExtensionToMcpServer(extension.id);
      if (serverName != null && !mcpProvider.mcpServerIsRunning(serverName)) {
        await mcpProvider.startMcpServer(serverName);
      }
    }
    
    // Update chat context with agent personality
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.setSystemPrompt(_generateSystemPrompt(agent));
  }
  
  String? _mapExtensionToMcpServer(String extensionId) {
    // Map extension IDs to MCP server names
    final mapping = {
      'filesystem-mcp': 'Filesystem',
      'github-mcp': 'GitHub',
      'web-fetch-mcp': 'Web Fetch',
      'postgres-mcp': 'PostgreSQL',
      'memory-mcp': 'Memory',
      'math': 'Math',
      'artifact-instructions': 'Artifact Instructions',
    };
    return mapping[extensionId];
  }

  String _generateSystemPrompt(AgentConfig agent) {
    return '''You are ${agent.name}, ${agent.description}.
    
Role: ${agent.role}
Purpose: ${agent.purpose}

Communication Style:
- Tone: ${agent.style.tone}
- Response Length: ${agent.style.responseLength}

Available Tools: ${agent.extensions.map((e) => e.name).join(', ')}

${agent.style.constraints.isNotEmpty ? 'Constraints:\n${agent.style.constraints.join('\n')}' : ''}
''';
  }

  void _startBuildingAgent() {
    setState(() {
      _navigationMode = NavigationMode.builder;
      _builderStep = 0;
      _buildingAgent = AgentConfig(
        name: '',
        description: '',
        role: '',
        purpose: '',
        extensions: [],
        style: AgentStyle(),
      );
    });
  }

  void _finishBuildingAgent() async {
    // Save the agent
    await AgentBuilderService.saveAgent(_buildingAgent);
    
    // Reload agents list
    await _loadSavedAgents();
    
    // Switch to the new agent
    _switchAgent(_buildingAgent);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agent "${_buildingAgent.name}" created and activated!'),
          backgroundColor: AsmbliDesignSystem.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
            ? AsmbliDesignSystem.darkGradient
            : AsmbliDesignSystem.lightGradient,
        ),
        child: Row(
          children: [
            // Sidebar
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                final width = _sidebarCollapsed ? 80.0 : 280.0;
                return Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: isDark ? AsmbliDesignSystem.darkSurface : AsmbliDesignSystem.lightSurface,
                    border: Border(
                      right: BorderSide(
                        color: isDark 
                          ? AsmbliDesignSystem.neutral700.withOpacity(0.3)
                          : AsmbliDesignSystem.neutral200,
                      ),
                    ),
                  ),
                  child: _buildSidebar(),
                );
              },
            ),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Logo and Brand
        Container(
          padding: const EdgeInsets.all(AsmbliDesignSystem.space4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AsmbliDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: AsmbliDesignSystem.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => 
                          AsmbliDesignSystem.primaryGradient.createShader(bounds),
                        child: Text(
                          'ASMBLI',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'AI Agent Platform',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              IconButton(
                icon: Icon(_sidebarCollapsed ? Icons.menu_open : Icons.menu),
                onPressed: _toggleSidebar,
                tooltip: 'Toggle Sidebar',
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Navigation Items
        Padding(
          padding: const EdgeInsets.all(AsmbliDesignSystem.space2),
          child: Column(
            children: [
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                isSelected: _navigationMode == NavigationMode.chat,
                onTap: () => setState(() => _navigationMode = NavigationMode.chat),
              ),
              const SizedBox(height: AsmbliDesignSystem.space1),
              _buildNavItem(
                icon: Icons.add_circle_outline,
                label: 'Build Agent',
                isSelected: _navigationMode == NavigationMode.builder,
                onTap: _startBuildingAgent,
              ),
              const SizedBox(height: AsmbliDesignSystem.space1),
              _buildNavItem(
                icon: Icons.folder_outlined,
                label: 'My Agents',
                isSelected: _navigationMode == NavigationMode.agents,
                onTap: () => setState(() => _navigationMode = NavigationMode.agents),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Active Agent Display
        if (_activeAgent != null && !_sidebarCollapsed) ...[
          Padding(
            padding: const EdgeInsets.all(AsmbliDesignSystem.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Agent',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AsmbliDesignSystem.space2),
                AsmbliCard(
                  padding: const EdgeInsets.all(AsmbliDesignSystem.space3),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRoleColor(_activeAgent!.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusSm),
                        ),
                        child: Icon(
                          _getRoleIcon(_activeAgent!.role),
                          color: _getRoleColor(_activeAgent!.role),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AsmbliDesignSystem.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeAgent!.name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_activeAgent!.extensions.length} tools',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const Spacer(),
        
        // Recent Agents List (collapsed shows icons only)
        if (_savedAgents.isNotEmpty) ...[
          Container(
            height: 200,
            padding: const EdgeInsets.all(AsmbliDesignSystem.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_sidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AsmbliDesignSystem.space2,
                      vertical: AsmbliDesignSystem.space1,
                    ),
                    child: Text(
                      'Recent Agents',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _savedAgents.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final agent = _savedAgents[index];
                      if (_sidebarCollapsed) {
                        return Tooltip(
                          message: agent.name,
                          child: IconButton(
                            icon: Icon(
                              _getRoleIcon(agent.role),
                              color: _getRoleColor(agent.role),
                            ),
                            onPressed: () => _switchAgent(agent),
                          ),
                        );
                      }
                      return _buildAgentTile(agent);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Settings
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AsmbliDesignSystem.space2),
          child: _buildNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: false,
            onTap: () {
              // Open settings
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: isSelected 
        ? AsmbliDesignSystem.primaryIndigo.withOpacity(0.1)
        : Colors.transparent,
      borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarCollapsed ? 12 : AsmbliDesignSystem.space3,
            vertical: AsmbliDesignSystem.space2,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected 
                  ? AsmbliDesignSystem.primaryIndigo
                  : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: AsmbliDesignSystem.space3),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected 
                        ? AsmbliDesignSystem.primaryIndigo
                        : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentTile(AgentConfig agent) {
    final theme = Theme.of(context);
    final isActive = _activeAgent?.name == agent.name;
    
    return Material(
      color: isActive 
        ? AsmbliDesignSystem.primaryIndigo.withOpacity(0.05)
        : Colors.transparent,
      borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusSm),
      child: InkWell(
        onTap: () => _switchAgent(agent),
        borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AsmbliDesignSystem.space2,
            vertical: AsmbliDesignSystem.space1,
          ),
          child: Row(
            children: [
              Icon(
                _getRoleIcon(agent.role),
                color: _getRoleColor(agent.role),
                size: 16,
              ),
              const SizedBox(width: AsmbliDesignSystem.space2),
              Expanded(
                child: Text(
                  agent.name,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AsmbliDesignSystem.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb or Title
          Text(
            _getPageTitle(),
            style: theme.textTheme.titleMedium,
          ),
          
          const Spacer(),
          
          // Quick Actions
          if (_navigationMode == NavigationMode.chat && _activeAgent != null) ...[
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Switch Agent'),
              onPressed: () => setState(() => _navigationMode = NavigationMode.agents),
            ),
            const SizedBox(width: AsmbliDesignSystem.space2),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Agent'),
              onPressed: _startBuildingAgent,
            ),
          ],
          
          if (_navigationMode == NavigationMode.builder) ...[
            Text(
              'Step ${_builderStep + 1} of 4',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: AsmbliDesignSystem.space4),
            if (_builderStep > 0)
              TextButton(
                onPressed: () => setState(() => _builderStep--),
                child: const Text('Previous'),
              ),
            const SizedBox(width: AsmbliDesignSystem.space2),
            ElevatedButton(
              onPressed: () {
                if (_builderStep < 3) {
                  setState(() => _builderStep++);
                } else {
                  _finishBuildingAgent();
                }
              },
              child: Text(_builderStep < 3 ? 'Next' : 'Finish & Deploy'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_navigationMode) {
      case NavigationMode.chat:
        return ChatPage();
        
      case NavigationMode.builder:
        return _buildAgentBuilder();
        
      case NavigationMode.agents:
        return _buildAgentsLibrary();
    }
  }

  Widget _buildAgentBuilder() {
    return Container(
      padding: const EdgeInsets.all(AsmbliDesignSystem.space6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AsmbliCard(
            padding: const EdgeInsets.all(AsmbliDesignSystem.space6),
            child: IndexedStack(
              index: _builderStep,
              children: [
                _BuilderStep1Profile(
                  agent: _buildingAgent,
                  onUpdate: (agent) => setState(() => _buildingAgent = agent),
                ),
                _BuilderStep2Extensions(
                  agent: _buildingAgent,
                  onUpdate: (agent) => setState(() => _buildingAgent = agent),
                ),
                _BuilderStep3Style(
                  agent: _buildingAgent,
                  onUpdate: (agent) => setState(() => _buildingAgent = agent),
                ),
                _BuilderStep4Review(
                  agent: _buildingAgent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentsLibrary() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AsmbliDesignSystem.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Library',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AsmbliDesignSystem.space2),
          Text(
            'Select an agent to activate it in the chat',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AsmbliDesignSystem.space6),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: AsmbliDesignSystem.space4,
                crossAxisSpacing: AsmbliDesignSystem.space4,
                childAspectRatio: 1.2,
              ),
              itemCount: _savedAgents.length,
              itemBuilder: (context, index) {
                final agent = _savedAgents[index];
                return _buildAgentCard(agent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(AgentConfig agent) {
    final theme = Theme.of(context);
    final isActive = _activeAgent?.name == agent.name;
    
    return AsmbliCard(
      isSelected: isActive,
      onTap: () => _switchAgent(agent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRoleColor(agent.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
                ),
                child: Icon(
                  _getRoleIcon(agent.role),
                  color: _getRoleColor(agent.role),
                ),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AsmbliDesignSystem.space2,
                    vertical: AsmbliDesignSystem.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AsmbliDesignSystem.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AsmbliDesignSystem.accentGreen,
                      ),
                      const SizedBox(width: AsmbliDesignSystem.space1),
                      Text(
                        'Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AsmbliDesignSystem.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AsmbliDesignSystem.space3),
          Text(
            agent.name,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AsmbliDesignSystem.space1),
          Text(
            agent.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Wrap(
            spacing: AsmbliDesignSystem.space1,
            children: [
              Chip(
                label: Text('${agent.extensions.length} tools'),
                labelStyle: theme.textTheme.labelSmall,
                backgroundColor: theme.colorScheme.surfaceContainer,
              ),
              Chip(
                label: Text(agent.role),
                labelStyle: theme.textTheme.labelSmall,
                backgroundColor: _getRoleColor(agent.role).withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_navigationMode) {
      case NavigationMode.chat:
        return _activeAgent != null 
          ? 'Chat with ${_activeAgent!.name}'
          : 'ASMBLI Chat';
      case NavigationMode.builder:
        return 'Build New Agent';
      case NavigationMode.agents:
        return 'Agent Library';
    }
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

enum NavigationMode {
  chat,
  builder,
  agents,
}

// Builder Step Components
class _BuilderStep1Profile extends StatelessWidget {
  final AgentConfig agent;
  final Function(AgentConfig) onUpdate;

  const _BuilderStep1Profile({
    required this.agent,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agent Profile',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Text(
          'Define your agent\'s identity and purpose',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AsmbliDesignSystem.space6),
        
        TextFormField(
          initialValue: agent.name,
          decoration: const InputDecoration(
            labelText: 'Agent Name',
            hintText: 'e.g., Code Assistant, Research Helper',
          ),
          onChanged: (value) => onUpdate(agent.copyWith(name: value)),
        ),
        
        const SizedBox(height: AsmbliDesignSystem.space4),
        
        TextFormField(
          initialValue: agent.description,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of what your agent does',
          ),
          maxLines: 3,
          onChanged: (value) => onUpdate(agent.copyWith(description: value)),
        ),
        
        const SizedBox(height: AsmbliDesignSystem.space4),
        
        Text(
          'Select Role',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        
        Wrap(
          spacing: AsmbliDesignSystem.space2,
          children: [
            'developer',
            'creator', 
            'researcher',
            'enterprise',
          ].map((role) => ChoiceChip(
            label: Text(role.substring(0, 1).toUpperCase() + role.substring(1)),
            selected: agent.role == role,
            onSelected: (selected) {
              if (selected) {
                onUpdate(agent.copyWith(role: role));
              }
            },
          )).toList(),
        ),
      ],
    );
  }
}

class _BuilderStep2Extensions extends StatefulWidget {
  final AgentConfig agent;
  final Function(AgentConfig) onUpdate;

  const _BuilderStep2Extensions({
    required this.agent,
    required this.onUpdate,
  });

  @override
  State<_BuilderStep2Extensions> createState() => _BuilderStep2ExtensionsState();
}

class _BuilderStep2ExtensionsState extends State<_BuilderStep2Extensions> {
  List<Extension> _availableExtensions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }
  
  Future<void> _loadExtensions() async {
    try {
      final extensions = await ExtensionService.loadExtensions();
      setState(() {
        _availableExtensions = extensions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _toggleExtension(Extension extension) {
    final currentExtensions = List<Extension>.from(widget.agent.extensions);
    if (currentExtensions.any((e) => e.id == extension.id)) {
      currentExtensions.removeWhere((e) => e.id == extension.id);
    } else {
      currentExtensions.add(extension);
    }
    widget.onUpdate(widget.agent.copyWith(extensions: currentExtensions));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Filter extensions based on agent role
    final roleExtensions = _availableExtensions.where((ext) {
      if (widget.agent.role == 'developer') {
        return ['core', 'development', 'database'].contains(ext.category);
      } else if (widget.agent.role == 'creator') {
        return ['core', 'design', 'productivity'].contains(ext.category);
      } else if (widget.agent.role == 'researcher') {
        return ['core', 'connectivity', 'database'].contains(ext.category);
      } else if (widget.agent.role == 'enterprise') {
        return true; // All extensions available
      }
      return ['core'].contains(ext.category);
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extensions & Tools',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Text(
          'Select the tools your agent will use',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AsmbliDesignSystem.space6),
        
        // Selected count
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AsmbliDesignSystem.space3,
            vertical: AsmbliDesignSystem.space2,
          ),
          decoration: BoxDecoration(
            color: AsmbliDesignSystem.primaryIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: AsmbliDesignSystem.primaryIndigo,
              ),
              const SizedBox(width: AsmbliDesignSystem.space2),
              Text(
                '${widget.agent.extensions.length} tools selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AsmbliDesignSystem.primaryIndigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AsmbliDesignSystem.space4),
        
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisSpacing: AsmbliDesignSystem.space3,
              crossAxisSpacing: AsmbliDesignSystem.space3,
              childAspectRatio: 1.3,
            ),
            itemCount: roleExtensions.length,
            itemBuilder: (context, index) {
              final extension = roleExtensions[index];
              final isSelected = widget.agent.extensions.any((e) => e.id == extension.id);
              
              return AsmbliCard(
                isSelected: isSelected,
                onTap: () => _toggleExtension(extension),
                padding: const EdgeInsets.all(AsmbliDesignSystem.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AsmbliDesignSystem.space2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(extension.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AsmbliDesignSystem.radiusSm),
                          ),
                          child: Icon(
                            _getExtensionIcon(extension.icon),
                            color: _getCategoryColor(extension.category),
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AsmbliDesignSystem.accentGreen,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: AsmbliDesignSystem.space2),
                    Text(
                      extension.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AsmbliDesignSystem.space1),
                    Text(
                      extension.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'core':
        return AsmbliDesignSystem.primaryIndigo;
      case 'development':
        return AsmbliDesignSystem.roleDeveloper;
      case 'design':
        return AsmbliDesignSystem.roleCreator;
      case 'connectivity':
        return AsmbliDesignSystem.secondaryPurple;
      case 'database':
        return AsmbliDesignSystem.accentAmber;
      default:
        return AsmbliDesignSystem.neutral500;
    }
  }
  
  IconData _getExtensionIcon(String icon) {
    switch (icon) {
      case 'folder':
        return Icons.folder;
      case 'github':
        return Icons.code;
      case 'globe':
        return Icons.public;
      case 'database':
        return Icons.storage;
      case 'save':
        return Icons.save;
      default:
        return Icons.extension;
    }
  }
}

class _BuilderStep3Style extends StatelessWidget {
  final AgentConfig agent;
  final Function(AgentConfig) onUpdate;

  const _BuilderStep3Style({
    required this.agent,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Style',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Text(
          'Define how your agent communicates',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AsmbliDesignSystem.space6),
        
        Text(
          'Tone',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Wrap(
          spacing: AsmbliDesignSystem.space2,
          children: [
            'Professional',
            'Friendly',
            'Technical',
            'Casual',
          ].map((tone) => ChoiceChip(
            label: Text(tone),
            selected: agent.style.tone == tone,
            onSelected: (selected) {
              if (selected) {
                onUpdate(agent.copyWith(
                  style: agent.style.copyWith(tone: tone),
                ));
              }
            },
          )).toList(),
        ),
        
        const SizedBox(height: AsmbliDesignSystem.space4),
        
        Text(
          'Response Length',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Wrap(
          spacing: AsmbliDesignSystem.space2,
          children: [
            'Concise',
            'Balanced',
            'Detailed',
          ].map((length) => ChoiceChip(
            label: Text(length),
            selected: agent.style.responseLength == length,
            onSelected: (selected) {
              if (selected) {
                onUpdate(agent.copyWith(
                  style: agent.style.copyWith(responseLength: length),
                ));
              }
            },
          )).toList(),
        ),
      ],
    );
  }
}

class _BuilderStep4Review extends StatelessWidget {
  final AgentConfig agent;

  const _BuilderStep4Review({
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Deploy',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AsmbliDesignSystem.space2),
        Text(
          'Review your agent configuration before deployment',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AsmbliDesignSystem.space6),
        
        AsmbliCard(
          padding: const EdgeInsets.all(AsmbliDesignSystem.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem('Name', agent.name),
              _buildReviewItem('Description', agent.description),
              _buildReviewItem('Role', agent.role),
              _buildReviewItem('Tone', agent.style.tone),
              _buildReviewItem('Response Length', agent.style.responseLength),
              _buildReviewItem('Extensions', '${agent.extensions.length} selected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AsmbliDesignSystem.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'Not set' : value),
          ),
        ],
      ),
    );
  }
}