import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/anthropic_style_mcp_service.dart';

/// Anthropic Product Manager approach to MCP integration
/// Focus: Safety, simplicity, user value over technical complexity
class AnthropicMCPScreen extends ConsumerStatefulWidget {
  const AnthropicMCPScreen({super.key});

  @override
  ConsumerState<AnthropicMCPScreen> createState() => _AnthropicMCPScreenState();
}

class _AnthropicMCPScreenState extends ConsumerState<AnthropicMCPScreen> {
  UserExpertiseLevel _selectedLevel = UserExpertiseLevel.beginner;
  MCPCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final mcpService = ref.read(anthropicMCPServiceProvider);
    
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
              _buildHeader(colors),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(SpacingTokens.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroSection(colors),
                      SizedBox(height: SpacingTokens.sectionSpacing),
                      _buildExpertiseLevelSelector(colors),
                      SizedBox(height: SpacingTokens.sectionSpacing),
                      _buildTierSection(
                        'Essential AI Tools',
                        'Verified by Anthropic for safety and reliability',
                        AnthropicStyleMCPService.essentialServers
                            .where((s) => s.trustLevel == MCPTrustLevel.anthropicOfficial)
                            .toList(),
                        colors,
                        MCPTrustLevel.anthropicOfficial,
                      ),
                      SizedBox(height: SpacingTokens.sectionSpacing),
                      _buildTierSection(
                        'Enterprise Integrations',
                        'Production-ready servers from major companies',
                        AnthropicStyleMCPService.essentialServers
                            .where((s) => s.trustLevel == MCPTrustLevel.enterpriseVerified)
                            .toList(),
                        colors,
                        MCPTrustLevel.enterpriseVerified,
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

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.headerPadding),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: colors.onSurface,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tool Connections',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Safe, verified tools to extend your AI capabilities',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.security,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety First',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'Every tool is carefully vetted for security and reliability',
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: colors.accent.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colors.accent,
                    size: 16,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'These tools run locally and only access what you explicitly allow',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
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

  Widget _buildExpertiseLevelSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your comfort level',
          style: TextStyles.sectionTitle.copyWith(
            color: colors.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Row(
          children: UserExpertiseLevel.values.map((level) {
            final isSelected = _selectedLevel == level;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: level != UserExpertiseLevel.values.last 
                      ? SpacingTokens.md 
                      : 0,
                ),
                child: AsmblCard(
                  onTap: () => setState(() => _selectedLevel = level),
                  child: Container(
                    padding: EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      border: isSelected ? Border.all(
                        color: colors.primary,
                        width: 2,
                      ) : null,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getExpertiseIcon(level),
                          color: isSelected ? colors.primary : colors.onSurfaceVariant,
                          size: 24,
                        ),
                        SizedBox(height: SpacingTokens.sm),
                        Text(
                          _getExpertiseLabel(level),
                          style: TextStyles.bodyMedium.copyWith(
                            color: isSelected ? colors.primary : colors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: SpacingTokens.xs),
                        Text(
                          _getExpertiseDescription(level),
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTierSection(
    String title,
    String description,
    List<CuratedMCPServer> servers,
    ThemeColors colors,
    MCPTrustLevel trustLevel,
  ) {
    final filteredServers = AnthropicStyleMCPService.getRecommendedServers(_selectedLevel)
        .where((s) => servers.contains(s))
        .toList();

    if (filteredServers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildTrustBadge(trustLevel, colors),
            SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.sectionTitle.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.lg),
        ...filteredServers.map((server) => Padding(
          padding: EdgeInsets.only(bottom: SpacingTokens.lg),
          child: _buildServerCard(server, colors),
        )),
      ],
    );
  }

  Widget _buildTrustBadge(MCPTrustLevel trustLevel, ThemeColors colors) {
    final trustData = _getTrustData(trustLevel);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: trustData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: trustData.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trustData.icon,
            color: trustData.color,
            size: 16,
          ),
          SizedBox(width: SpacingTokens.xs),
          Text(
            trustData.label,
            style: TextStyles.bodySmall.copyWith(
              color: trustData.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(CuratedMCPServer server, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    _getCategoryIcon(server.category),
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        server.valueProposition,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Text(
              server.description,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildServerDetails(server, colors),
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: AsmblButton.primary(
                    text: _getSetupButtonText(server.setupComplexity),
                    icon: _getSetupIcon(server.setupComplexity),
                    onPressed: () => _setupServer(server),
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                AsmblButton.outline(
                  text: 'Learn More',
                  icon: Icons.info_outline,
                  onPressed: () => _showServerDetails(server),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerDetails(CuratedMCPServer server, ThemeColors colors) {
    return Column(
      children: [
        _buildDetailRow(
          'What it can do',
          server.capabilities.take(3).join(', '),
          Icons.build,
          colors,
        ),
        SizedBox(height: SpacingTokens.sm),
        _buildDetailRow(
          'Data access',
          server.dataAccess.take(2).join(', '),
          Icons.security,
          colors,
        ),
        if (server.authRequired) ...[
          SizedBox(height: SpacingTokens.sm),
          _buildDetailRow(
            'Authentication',
            'Secure OAuth required',
            Icons.verified_user,
            colors,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colors.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  IconData _getExpertiseIcon(UserExpertiseLevel level) {
    switch (level) {
      case UserExpertiseLevel.beginner:
        return Icons.school;
      case UserExpertiseLevel.intermediate:
        return Icons.work;
      case UserExpertiseLevel.advanced:
        return Icons.engineering;
    }
  }

  String _getExpertiseLabel(UserExpertiseLevel level) {
    switch (level) {
      case UserExpertiseLevel.beginner:
        return 'Just Getting Started';
      case UserExpertiseLevel.intermediate:
        return 'Some Experience';
      case UserExpertiseLevel.advanced:
        return 'Technical User';
    }
  }

  String _getExpertiseDescription(UserExpertiseLevel level) {
    switch (level) {
      case UserExpertiseLevel.beginner:
        return 'Show me the essentials';
      case UserExpertiseLevel.intermediate:
        return 'I can handle OAuth';
      case UserExpertiseLevel.advanced:
        return 'All options available';
    }
  }

  ({Color color, IconData icon, String label}) _getTrustData(MCPTrustLevel trustLevel) {
    switch (trustLevel) {
      case MCPTrustLevel.anthropicOfficial:
        return (
          color: Colors.green,
          icon: Icons.verified,
          label: 'Anthropic Verified'
        );
      case MCPTrustLevel.enterpriseVerified:
        return (
          color: Colors.blue,
          icon: Icons.business,
          label: 'Enterprise'
        );
      case MCPTrustLevel.communityVerified:
        return (
          color: Colors.orange,
          icon: Icons.people,
          label: 'Community'
        );
      case MCPTrustLevel.experimental:
        return (
          color: Colors.amber,
          icon: Icons.science,
          label: 'Experimental'
        );
      case MCPTrustLevel.unknown:
        return (
          color: Colors.grey,
          icon: Icons.help,
          label: 'Unknown'
        );
    }
  }

  IconData _getCategoryIcon(MCPCategory category) {
    switch (category) {
      case MCPCategory.development:
        return Icons.code;
      case MCPCategory.productivity:
        return Icons.work;
      case MCPCategory.information:
        return Icons.search;
      case MCPCategory.communication:
        return Icons.chat;
      case MCPCategory.reasoning:
        return Icons.psychology;
      case MCPCategory.utility:
        return Icons.build;
      case MCPCategory.creative:
        return Icons.palette;
    }
  }

  String _getSetupButtonText(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return 'Install Now';
      case MCPSetupComplexity.oauth:
        return 'Connect Account';
      case MCPSetupComplexity.minimal:
        return 'Add API Key';
      case MCPSetupComplexity.guided:
        return 'Setup Guide';
      case MCPSetupComplexity.advanced:
        return 'Manual Setup';
    }
  }

  IconData _getSetupIcon(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return Icons.download;
      case MCPSetupComplexity.oauth:
        return Icons.account_circle;
      case MCPSetupComplexity.minimal:
        return Icons.key;
      case MCPSetupComplexity.guided:
        return Icons.assistant;
      case MCPSetupComplexity.advanced:
        return Icons.settings;
    }
  }

  void _setupServer(CuratedMCPServer server) {
    // Implementation would depend on setup complexity
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup ${server.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.valueProposition),
            SizedBox(height: SpacingTokens.md),
            if (server.installCommand.isNotEmpty) ...[
              Text('Installation command:'),
              SizedBox(height: SpacingTokens.xs),
              Container(
                padding: EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  server.installCommand,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Actual installation logic would go here
            },
            child: const Text('Install'),
          ),
        ],
      ),
    );
  }

  void _showServerDetails(CuratedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(server.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.description),
              SizedBox(height: SpacingTokens.md),
              Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.capabilities.map((cap) => Text('• $cap')),
              SizedBox(height: SpacingTokens.md),
              Text('Data Access:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.dataAccess.map((data) => Text('• $data')),
              if (server.documentationUrl != null) ...[
                SizedBox(height: SpacingTokens.md),
                Text('Documentation: ${server.documentationUrl}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}