import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/anthropic_style_mcp_service.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/models/oauth_provider.dart';

class EnhancedMCPServerCard extends ConsumerStatefulWidget {
  final CuratedMCPServer server;
  final VoidCallback? onInstall;
  final VoidCallback? onLearnMore;

  const EnhancedMCPServerCard({
    super.key,
    required this.server,
    this.onInstall,
    this.onLearnMore,
  });

  @override
  ConsumerState<EnhancedMCPServerCard> createState() => _EnhancedMCPServerCardState();
}

class _EnhancedMCPServerCardState extends ConsumerState<EnhancedMCPServerCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AsmblCard(
              child: IntrinsicHeight(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 420,
                    maxHeight: 480,
                  ), // Flexible height with constraints
                  padding: EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                  border: Border.all(
                    color: _isHovered 
                      ? colors.primary.withOpacity(0.6) 
                      : colors.border.withOpacity(0.3),
                    width: _isHovered ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors),
                    SizedBox(height: SpacingTokens.sm),
                    _buildContent(colors),
                    SizedBox(height: SpacingTokens.sm),
                    _buildFooter(colors),
                  ],
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        // Category icon
        Container(
          padding: EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getCategoryIcon(widget.server.category),
            color: colors.primary,
            size: 20,
          ),
        ),
        const Spacer(),
        // Trust level badge
        _buildTrustBadge(colors),
      ],
    );
  }

  Widget _buildTrustBadge(ThemeColors colors) {
    final trustData = _getTrustData(widget.server.trustLevel);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: trustData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
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
            size: 12,
          ),
          SizedBox(width: SpacingTokens.xs),
          Text(
            trustData.label,
            style: TextStyles.caption.copyWith(
              color: trustData.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors colors) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name and value prop
          Text(
            widget.server.name,
            style: TextStyles.cardTitle.copyWith(
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SpacingTokens.xs / 2),
          Text(
            widget.server.valueProposition,
            style: TextStyles.bodySmall.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SpacingTokens.xs / 2),
          
          // Description
          Flexible(
            child: Text(
              widget.server.description,
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: SpacingTokens.xs),
          
          // Key details
          _buildDetailRows(colors),
        ],
      ),
    );
  }

  Widget _buildDetailRows(ThemeColors colors) {
    return Column(
      children: [
        _buildDetailRow(
          'Setup',
          _getComplexityLabel(widget.server.setupComplexity),
          _getComplexityIcon(widget.server.setupComplexity),
          _getComplexityColor(widget.server.setupComplexity),
          colors,
        ),
        SizedBox(height: SpacingTokens.xs / 2),
        _buildDetailRow(
          'Type',
          widget.server.isRemote ? 'Remote Server' : 'Local Command',
          widget.server.isRemote ? Icons.cloud : Icons.terminal,
          colors.onSurfaceVariant,
          colors,
        ),
        if (widget.server.authRequired) ...[
          SizedBox(height: SpacingTokens.xs / 2),
          _buildDetailRow(
            'Auth',
            'Required',
            Icons.security,
            Colors.orange,
            colors,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ThemeColors colors,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 14,
        ),
        SizedBox(width: SpacingTokens.xs),
        Text(
          '$label: ',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyles.caption.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Column(
      children: [
        // Install command preview
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SpacingTokens.xs),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            widget.server.installCommand.length > 40 
                ? '${widget.server.installCommand.substring(0, 37)}...'
                : widget.server.installCommand,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ),
        SizedBox(height: SpacingTokens.xs),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: AsmblButton.primary(
                text: _getActionButtonText(),
                icon: _getActionButtonIcon(),
                onPressed: () => _handleActionButton(),
                size: AsmblButtonSize.small,
              ),
            ),
            SizedBox(width: SpacingTokens.sm),
            AsmblButton.outline(
              text: 'Info',
              icon: Icons.info_outline,
              onPressed: widget.onLearnMore,
              size: AsmblButtonSize.small,
            ),
          ],
        ),
      ],
    );
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleActionButton() {
    if (widget.server.setupComplexity == MCPSetupComplexity.oauth) {
      _handleOAuthConnect();
    } else {
      // Handle regular installation
      widget.onInstall?.call();
    }
  }

  Future<void> _handleOAuthConnect() async {
    // Map server names to OAuth providers using proper enum
    OAuthProvider? provider = _getOAuthProviderForServer(widget.server.name);

    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OAuth not configured for ${widget.server.name}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      
      // Check if already connected
      final hasToken = await oauthService.hasValidToken(provider);
      if (hasToken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.server.name} is already connected!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Connecting to ${widget.server.name}...'),
            ],
          ),
        ),
      );

      // Start OAuth flow
      final result = await oauthService.authenticate(provider);

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to ${widget.server.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Map server names to OAuth providers using the actual enum values
  OAuthProvider? _getOAuthProviderForServer(String serverName) {
    final normalizedName = serverName.toLowerCase().replaceAll(' ', '');
    
    // Map to actual OAuthProvider enum values
    switch (normalizedName) {
      case 'github':
        return OAuthProvider.github;
      case 'slack':
        return OAuthProvider.slack;
      case 'linear':
        return OAuthProvider.linear;
      case 'microsoft':
        return OAuthProvider.microsoft;
      case 'notion':
        return OAuthProvider.notion;
      case 'bravesearch':
      case 'brave-search':
        return OAuthProvider.braveSearch;
      default:
        return null;
    }
  }

  // Helper methods
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

  ({Color color, IconData icon, String label}) _getTrustData(MCPTrustLevel trustLevel) {
    switch (trustLevel) {
      case MCPTrustLevel.anthropicOfficial:
        return (
          color: const Color(0xFF10B981), // Green-500
          icon: Icons.verified,
          label: 'Official'
        );
      case MCPTrustLevel.enterpriseVerified:
        return (
          color: const Color(0xFF3B82F6), // Blue-500
          icon: Icons.business,
          label: 'Enterprise'
        );
      case MCPTrustLevel.communityVerified:
        return (
          color: const Color(0xFF8B5CF6), // Purple-500
          icon: Icons.groups,
          label: 'Community'
        );
      case MCPTrustLevel.experimental:
        return (
          color: const Color(0xFFF59E0B), // Amber-500
          icon: Icons.science,
          label: 'Experimental'
        );
      case MCPTrustLevel.unknown:
        return (
          color: const Color(0xFF6B7280), // Gray-500
          icon: Icons.help_outline,
          label: 'Unknown'
        );
    }
  }

  String _getComplexityLabel(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return 'One Command';
      case MCPSetupComplexity.oauth:
        return 'OAuth Required';
      case MCPSetupComplexity.minimal:
        return 'API Key';
      case MCPSetupComplexity.guided:
        return 'Guided Setup';
      case MCPSetupComplexity.advanced:
        return 'Advanced';
    }
  }

  IconData _getComplexityIcon(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return Icons.flash_on;
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

  Color _getComplexityColor(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return const Color(0xFF10B981); // Green - easy
      case MCPSetupComplexity.minimal:
        return const Color(0xFF3B82F6); // Blue - moderate
      case MCPSetupComplexity.oauth:
      case MCPSetupComplexity.guided:
        return const Color(0xFFF59E0B); // Amber - requires attention
      case MCPSetupComplexity.advanced:
        return const Color(0xFFEF4444); // Red - complex
    }
  }

  String _getActionButtonText() {
    switch (widget.server.setupComplexity) {
      case MCPSetupComplexity.oneClick:
        return 'Install';
      case MCPSetupComplexity.oauth:
        return 'Connect';
      case MCPSetupComplexity.minimal:
        return 'Setup';
      case MCPSetupComplexity.guided:
        return 'Guide';
      case MCPSetupComplexity.advanced:
        return 'Configure';
    }
  }

  IconData _getActionButtonIcon() {
    switch (widget.server.setupComplexity) {
      case MCPSetupComplexity.oneClick:
        return Icons.download;
      case MCPSetupComplexity.oauth:
        return Icons.link;
      case MCPSetupComplexity.minimal:
        return Icons.key;
      case MCPSetupComplexity.guided:
        return Icons.assistant;
      case MCPSetupComplexity.advanced:
        return Icons.settings;
    }
  }
}