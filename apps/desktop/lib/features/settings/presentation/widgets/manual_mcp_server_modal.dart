import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/data/mcp_server_configs.dart';
import '../../../../core/services/mcp_server_configuration_service.dart';

/// Modal for manually selecting and configuring MCP servers from our curated library
class ManualMCPServerModal extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onConfigurationComplete;
  final String? preselectedServerId;

  const ManualMCPServerModal({
    super.key,
    required this.onConfigurationComplete,
    this.preselectedServerId,
  });

  @override
  ConsumerState<ManualMCPServerModal> createState() => _ManualMCPServerModalState();
}

class _ManualMCPServerModalState extends ConsumerState<ManualMCPServerModal> {
  MCPServerConfig? selectedServer;
  final Map<String, String> envVars = {};
  final Map<String, TextEditingController> controllers = {};
  String? customPath;
  bool isConfiguring = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedServerId != null) {
      selectedServer = MCPServerLibrary.getServer(widget.preselectedServerId!);
      if (selectedServer != null) {
        isConfiguring = true;
        _initializeControllers();
      }
    }
  }

  void _initializeControllers() {
    if (selectedServer == null) return;
    
    controllers.clear();
    envVars.clear();
    
    for (final envVar in selectedServer!.requiredEnvVars) {
      controllers[envVar] = TextEditingController();
      envVars[envVar] = '';
    }
    
    for (final envVar in selectedServer!.optionalEnvVars) {
      controllers[envVar] = TextEditingController();
      envVars[envVar] = '';
    }
    
    // Initialize custom path controller if needed
    if (selectedServer!.id == 'filesystem' || selectedServer!.id == 'sqlite') {
      controllers['custom_path'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<MCPServerConfig> get filteredServers {
    final servers = ref.watch(mcpServerConfigurationProvider);
    if (searchQuery.isEmpty) return servers;
    
    return servers.where((server) =>
      server.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      server.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
      server.capabilities.any((cap) => cap.toLowerCase().contains(searchQuery.toLowerCase()))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    Icons.integration_instructions,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual MCP Server Configuration',
                        style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: SpacingTokens.xs_precise),
                      Text(
                        'Select and configure an MCP server from our curated library',
                        style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Content
            Expanded(
              child: isConfiguring && selectedServer != null
                ? _buildConfigurationView()
                : _buildServerSelectionView(),
            ),
            
            const SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isConfiguring) ...[
                  AsmblButton.secondary(
                    text: 'Back to Selection',
                    onPressed: () {
                      setState(() {
                        isConfiguring = false;
                        selectedServer = null;
                      });
                    },
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                ],
                AsmblButton.secondary(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),
                AsmblButton.primary(
                  text: isConfiguring ? 'Add MCP Server' : 'Continue',
                  onPressed: isConfiguring ? _handleAddServer : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSelectionView() {
    final colors = ThemeColors(context);
    
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search MCP servers...',
              border: InputBorder.none,
              icon: Icon(Icons.search, color: colors.onSurfaceVariant),
              hintStyle: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
        
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Server type filter tabs
        Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: true,
              onTap: () => ref.read(mcpServerConfigurationProvider.notifier).resetFilter(),
            ),
            const SizedBox(width: SpacingTokens.iconSpacing),
            _FilterChip(
              label: 'Official',
              isSelected: false,
              onTap: () => ref.read(mcpServerConfigurationProvider.notifier).filterByType(MCPServerType.official),
            ),
            const SizedBox(width: SpacingTokens.iconSpacing),
            _FilterChip(
              label: 'Community',
              isSelected: false,
              onTap: () => ref.read(mcpServerConfigurationProvider.notifier).filterByType(MCPServerType.community),
            ),
            const SizedBox(width: SpacingTokens.iconSpacing),
            _FilterChip(
              label: 'No Auth Required',
              isSelected: false,
              onTap: () {
                final noAuthServers = MCPServerLibrary.getServersWithoutAuth();
                ref.read(mcpServerConfigurationProvider.notifier).state = noAuthServers;
              },
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Server list
        Expanded(
          child: ListView.builder(
            itemCount: filteredServers.length,
            itemBuilder: (context, index) {
              final server = filteredServers[index];
              return _ServerCard(
                server: server,
                onTap: () {
                  setState(() {
                    selectedServer = server;
                    isConfiguring = true;
                  });
                  _initializeControllers();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationView() {
    final colors = ThemeColors(context);
    final server = selectedServer!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected server info
          AsmblCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ServerTypeChip(server.type),
                    const Spacer(),
                    _ServerStatusChip(server.status),
                  ],
                ),
                const SizedBox(height: SpacingTokens.componentSpacing),
                Text(
                  server.name,
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.iconSpacing),
                Text(
                  server.description,
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
                if (server.capabilities.isNotEmpty) ...[
                  const SizedBox(height: SpacingTokens.componentSpacing),
                  Wrap(
                    spacing: SpacingTokens.iconSpacing,
                    runSpacing: SpacingTokens.iconSpacing,
                    children: server.capabilities.map((capability) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.iconSpacing,
                        vertical: SpacingTokens.xs_precise,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        capability.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Configuration form
          if (server.requiredEnvVars.isNotEmpty || server.optionalEnvVars.isNotEmpty || 
              server.id == 'filesystem' || server.id == 'sqlite') ...[
            Text(
              'Configuration',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            
            // Custom path input for filesystem/sqlite
            if (server.id == 'filesystem' || server.id == 'sqlite') ...[
              _buildPathInput(),
              const SizedBox(height: SpacingTokens.componentSpacing),
            ],
            
            // Environment variables
            ...server.requiredEnvVars.map((envVar) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: _buildEnvVarInput(envVar, required: true),
            )),
            
            if (server.optionalEnvVars.isNotEmpty) ...[
              Text(
                'Optional Configuration',
                style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.componentSpacing),
              
              ...server.optionalEnvVars.map((envVar) => Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
                child: _buildEnvVarInput(envVar, required: false),
              )),
            ],
          ],
          
          // Setup instructions
          if (server.setupInstructions != null) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'Setup Instructions',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                MCPServerConfigurationService.getSetupInstructions(server),
                style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathInput() {
    final colors = ThemeColors(context);
    final server = selectedServer!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          server.id == 'filesystem' ? 'Directory Path' : 'Database File Path',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            controller: controllers['custom_path'],
            onChanged: (value) => customPath = value,
            decoration: InputDecoration(
              hintText: server.id == 'filesystem' 
                ? '/path/to/allowed/directory' 
                : '/path/to/database.db',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              suffixIcon: IconButton(
                icon: Icon(Icons.folder_open, color: colors.primary),
                onPressed: () {
                  // TODO: Implement file/folder picker
                },
              ),
            ),
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvVarInput(String envVar, {required bool required}) {
    final colors = ThemeColors(context);
    final description = _getEnvVarDescription(envVar);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              envVar,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: SpacingTokens.xs_precise),
              Text(
                '*',
                style: TextStyles.bodyMedium.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
        const SizedBox(height: SpacingTokens.xs_precise),
        Text(
          description,
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            controller: controllers[envVar],
            onChanged: (value) => envVars[envVar] = value,
            obscureText: envVar.toLowerCase().contains('token') || 
                        envVar.toLowerCase().contains('key') ||
                        envVar.toLowerCase().contains('password'),
            decoration: InputDecoration(
              hintText: 'Enter $envVar...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            ),
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
      ],
    );
  }

  void _handleAddServer() {
    if (selectedServer == null) return;
    
    // Validate configuration
    final validation = MCPServerConfigurationService.validateServerConfig(
      selectedServer!,
      envVars,
    );
    
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: ThemeColors(context).error,
        ),
      );
      return;
    }
    
    // Generate configuration
    final config = MCPServerConfigurationService.generateAgentMCPConfig(
      selectedServer!,
      envVars,
      customPath: customPath,
    );
    
    widget.onConfigurationComplete(config);
    Navigator.of(context).pop();
  }

  /// Get human-readable description for environment variables
  String _getEnvVarDescription(String envVar) {
    switch (envVar) {
      case 'GITHUB_PERSONAL_ACCESS_TOKEN':
        return 'GitHub Personal Access Token with repo permissions';
      case 'SLACK_BOT_TOKEN':
        return 'Slack Bot User OAuth Token (starts with xoxb-)';
      case 'NOTION_API_KEY':
        return 'Notion Integration API Key';
      case 'NOTION_DATABASE_ID':
        return 'ID of the Notion database to access';
      case 'LINEAR_API_KEY':
        return 'Linear API key from account settings';
      case 'POSTGRES_CONNECTION_STRING':
        return 'PostgreSQL connection string (postgresql://user:pass@host:port/db)';
      case 'BRAVE_API_KEY':
        return 'Brave Search API key';
      case 'GOOGLE_DRIVE_CREDENTIALS_JSON':
        return 'Path to Google Drive API credentials JSON file';
      case 'JIRA_URL':
        return 'Your Jira instance URL (e.g., https://yourcompany.atlassian.net)';
      case 'JIRA_EMAIL':
        return 'Your Jira account email';
      case 'JIRA_API_TOKEN':
        return 'Jira API token from account settings';
      case 'DISCORD_BOT_TOKEN':
        return 'Discord bot token from Developer Portal';
      case 'AIRTABLE_API_KEY':
        return 'Airtable API key from account settings';
      case 'AIRTABLE_BASE_ID':
        return 'ID of the Airtable base to access';
      default:
        return 'Required for authentication';
    }
  }
}

// Helper widgets
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.componentSpacing,
          vertical: SpacingTokens.iconSpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final MCPServerConfig server;
  final VoidCallback onTap;
  
  const _ServerCard({
    required this.server,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
        child: AsmblCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      server.name,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                  ),
                  _ServerTypeChip(server.type),
                  const SizedBox(width: SpacingTokens.iconSpacing),
                  _ServerStatusChip(server.status),
                ],
              ),
              const SizedBox(height: SpacingTokens.iconSpacing),
              Text(
                server.description,
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (server.requiredEnvVars.isNotEmpty) ...[
                const SizedBox(height: SpacingTokens.iconSpacing),
                Row(
                  children: [
                    Icon(
                      Icons.key,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: SpacingTokens.xs_precise),
                    Text(
                      'Requires authentication',
                      style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerTypeChip extends StatelessWidget {
  final MCPServerType type;
  
  const _ServerTypeChip(this.type);
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isOfficial = type == MCPServerType.official;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: SpacingTokens.xs_precise,
      ),
      decoration: BoxDecoration(
        color: isOfficial 
          ? colors.primary.withValues(alpha: 0.1)
          : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        isOfficial ? 'OFFICIAL' : 'COMMUNITY',
        style: TextStyles.caption.copyWith(
          color: isOfficial ? colors.primary : colors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ServerStatusChip extends StatelessWidget {
  final MCPServerStatus status;
  
  const _ServerStatusChip(this.status);
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    Color getStatusColor() {
      switch (status) {
        case MCPServerStatus.stable:
          return Colors.green;
        case MCPServerStatus.beta:
          return Colors.orange;
        case MCPServerStatus.alpha:
          return Colors.red;
        case MCPServerStatus.deprecated:
          return colors.onSurfaceVariant;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.iconSpacing,
        vertical: SpacingTokens.xs_precise,
      ),
      decoration: BoxDecoration(
        color: getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyles.caption.copyWith(
          color: getStatusColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}