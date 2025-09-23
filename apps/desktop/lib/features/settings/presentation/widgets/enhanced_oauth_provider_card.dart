import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/oauth_provider.dart' as core;
import '../screens/enhanced_oauth_settings_screen.dart' as enhanced;

/// Enhanced OAuth provider card with comprehensive status display and actions
class EnhancedOAuthProviderCard extends StatefulWidget {
  final core.OAuthProvider provider;
  final core.OAuthProviderState state;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onRefresh;
  final VoidCallback? onManageScopes;
  final VoidCallback? onViewDetails;

  const EnhancedOAuthProviderCard({
    super.key,
    required this.provider,
    required this.state,
    this.onConnect,
    this.onDisconnect,
    this.onRefresh,
    this.onManageScopes,
    this.onViewDetails,
  });

  @override
  State<EnhancedOAuthProviderCard> createState() => _EnhancedOAuthProviderCardState();
}

class _EnhancedOAuthProviderCardState extends State<EnhancedOAuthProviderCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      isInteractive: true,
      onTap: _toggleExpanded,
      child: Column(
        children: [
          // Main card content
          _buildMainContent(colors),
          
          // Expandable details section
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors) {
    return Row(
      children: [
        // Provider icon and info
        Expanded(
          child: Row(
            children: [
              // Provider icon with status indicator
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getProviderColor(widget.provider).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Icon(
                      _getProviderIcon(widget.provider),
                      color: _getProviderColor(widget.provider),
                      size: 24,
                    ),
                  ),
                  
                  // Status indicator
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.state.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: widget.state.status == core.OAuthConnectionStatus.connecting ||
                             widget.state.status == core.core.OAuthConnectionStatus.connecting
                          ? const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(strokeWidth: 1),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: SpacingTokens.md),
              
              // Provider details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.provider.displayName,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      _getStatusText(),
                      style: TextStyles.bodyMedium.copyWith(
                        color: _getStatusTextColor(colors),
                      ),
                    ),
                    if (widget.state.isConnected && widget.state.grantedScopes.isNotEmpty) ...[
                      const SizedBox(height: SpacingTokens.xs),
                      _buildScopesBadge(colors),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons and expand indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick action button
            if (widget.state.isConnected) ...[
              _buildQuickActionButton(colors),
              const SizedBox(width: SpacingTokens.sm),
            ],
            
            // Primary action button
            _buildPrimaryActionButton(colors),
            
            const SizedBox(width: SpacingTokens.sm),
            
            // Expand indicator
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeColors colors) {
    if (!_isExpanded) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.md),
      padding: const EdgeInsets.only(top: SpacingTokens.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection details
          if (widget.state.isConnected) ...[
            _buildConnectionDetails(colors),
            const SizedBox(height: SpacingTokens.md),
          ],
          
          // Error details
          if (widget.state.status == core.OAuthConnectionStatus.error) ...[
            _buildErrorDetails(colors),
            const SizedBox(height: SpacingTokens.md),
          ],
          
          // Scopes section
          if (widget.state.grantedScopes.isNotEmpty) ...[
            _buildScopesSection(colors),
            const SizedBox(height: SpacingTokens.md),
          ],
          
          // Action buttons
          _buildActionButtons(colors),
        ],
      ),
    );
  }

  Widget _buildConnectionDetails(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection Details',
          style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildDetailRow('Connected', _formatDateTime(widget.state.connectedAt), colors),
        if (widget.state.lastRefresh != null)
          _buildDetailRow('Last Refresh', _formatDateTime(widget.state.lastRefresh), colors),
        if (widget.state.expiresAt != null) ...[
          _buildDetailRow(
            'Expires',
            _formatDateTime(widget.state.expiresAt),
            colors,
            warning: widget.state.isExpiringSoon,
          ),
        ],
        
        _buildDetailRow(
          'Refreshable',
          widget.state.isRefreshable ? 'Yes' : 'No',
          colors,
        ),
      ],
    );
  }

  Widget _buildErrorDetails(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 16),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Error Details',
              style: TextStyles.labelLarge.copyWith(color: colors.error),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            border: Border.all(color: colors.error.withOpacity(0.3)),
          ),
          child: Text(
            widget.state.error ?? 'Unknown error occurred',
            style: TextStyles.bodySmall.copyWith(color: colors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildScopesSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Granted Permissions',
              style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onManageScopes,
              child: Text(
                'Manage',
                style: TextStyles.labelMedium.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        Wrap(
          spacing: SpacingTokens.xs,
          runSpacing: SpacingTokens.xs,
          children: widget.state.grantedScopes.take(6).map((scope) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                border: Border.all(color: colors.primary.withOpacity(0.3)),
              ),
              child: Text(
                _formatScopeName(scope),
                style: TextStyles.caption.copyWith(color: colors.primary),
              ),
            );
          }).toList(),
        ),
        
        if (widget.state.grantedScopes.length > 6) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '+${widget.state.grantedScopes.length - 6} more permissions',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value, ThemeColors colors, {bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (warning) ...[
                  Icon(Icons.warning_amber, color: colors.warning, size: 16),
                  const SizedBox(width: SpacingTokens.xs),
                ],
                Text(
                  value ?? 'N/A',
                  style: TextStyles.bodyMedium.copyWith(
                    color: warning ? colors.warning : colors.onSurface,
                    fontWeight: warning ? TypographyTokens.medium : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopesBadge(ThemeColors colors) {
    final scopeCount = widget.state.grantedScopes.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
      ),
      child: Text(
        '$scopeCount permission${scopeCount != 1 ? 's' : ''}',
        style: TextStyles.caption.copyWith(color: colors.primary),
      ),
    );
  }

  Widget _buildQuickActionButton(ThemeColors colors) {
    if (widget.state.isExpired || widget.state.isExpiringSoon) {
      return AsmblButton.secondary(
        text: 'Refresh',
        icon: Icons.refresh,
        size: AsmblButtonSize.small,
        onPressed: widget.onRefresh,
      );
    }
    
    return AsmblButton.secondary(
      text: 'Test',
      icon: Icons.check_circle_outline,
      size: AsmblButtonSize.small,
      onPressed: () => _testConnection(),
    );
  }

  Widget _buildPrimaryActionButton(ThemeColors colors) {
    switch (widget.state.status) {
      case core.OAuthConnectionStatus.connected:
        return AsmblButton.outline(
          text: 'Disconnect',
          icon: Icons.link_off,
          size: AsmblButtonSize.small,
          onPressed: widget.onDisconnect,
        );
      
      case core.OAuthConnectionStatus.disconnected:
      case core.OAuthConnectionStatus.error:
        return AsmblButton.primary(
          text: 'Connect',
          icon: Icons.link,
          size: AsmblButtonSize.small,
          onPressed: widget.onConnect,
        );
      
      case core.OAuthConnectionStatus.connecting:
        return AsmblButton.primary(
          text: 'Connecting...',
          isLoading: true,
          size: AsmblButtonSize.small,
          onPressed: null,
        );
      
      case core.core.OAuthConnectionStatus.connecting:
        return AsmblButton.secondary(
          text: 'Refreshing...',
          isLoading: true,
          size: AsmblButtonSize.small,
          onPressed: null,
        );
    }
  }

  Widget _buildActionButtons(ThemeColors colors) {
    return Row(
      children: [
        if (widget.state.isConnected) ...[
          AsmblButton.secondary(
            text: 'View Details',
            icon: Icons.info_outline,
            size: AsmblButtonSize.small,
            onPressed: widget.onViewDetails,
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          if (widget.state.isRefreshable)
            AsmblButton.secondary(
              text: 'Refresh Token',
              icon: Icons.refresh,
              size: AsmblButtonSize.small,
              onPressed: widget.onRefresh,
            ),
        ],
        
        const Spacer(),
        
        // Copy connection info
        if (widget.state.isConnected)
          IconButton(
            icon: Icon(Icons.copy, color: colors.onSurfaceVariant),
            onPressed: () => _copyConnectionInfo(),
            tooltip: 'Copy connection details',
          ),
      ],
    );
  }

  // Helper methods
  Color _getProviderColor(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return const Color(BrandColors.github);
      case OAuthProvider.slack:
        return const Color(0xFF4A154B);
      case OAuthProvider.linear:
        return const Color(0xFF5E6AD2);
      case OAuthProvider.microsoft:
        return const Color(BrandColors.microsoft);
      default:
        return const Color(BrandColors.defaultBrand);
    }
  }

  IconData _getProviderIcon(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return Icons.code;
      case OAuthProvider.slack:
        return Icons.chat;
      case OAuthProvider.linear:
        return Icons.linear_scale;
      case OAuthProvider.microsoft:
        return Icons.business;
      default:
        return Icons.integration_instructions;
    }
  }

  Color _getStatusColor(core.OAuthConnectionStatus status) {
    final colors = ThemeColors(context);
    switch (status) {
      case core.OAuthConnectionStatus.connected:
        return colors.success;
      case core.OAuthConnectionStatus.disconnected:
        return colors.onSurfaceVariant.withOpacity(0.5);
      case core.OAuthConnectionStatus.error:
        return colors.error;
      case core.OAuthConnectionStatus.connecting:
      case core.core.OAuthConnectionStatus.connecting:
        return colors.warning;
    }
  }

  Color _getStatusTextColor(ThemeColors colors) {
    switch (widget.state.status) {
      case core.OAuthConnectionStatus.connected:
        return widget.state.isExpired ? colors.error : colors.success;
      case core.OAuthConnectionStatus.error:
        return colors.error;
      default:
        return colors.onSurfaceVariant;
    }
  }

  String _getStatusText() {
    switch (widget.state.status) {
      case core.OAuthConnectionStatus.connected:
        if (widget.state.isExpired) {
          return 'Token expired';
        } else if (widget.state.isExpiringSoon) {
          return 'Token expires soon';
        }
        return 'Connected • Active';
      
      case core.OAuthConnectionStatus.disconnected:
        return 'Not connected';
      
      case core.OAuthConnectionStatus.error:
        return 'Connection error';
      
      case core.OAuthConnectionStatus.connecting:
        return 'Connecting...';
      
      case core.core.OAuthConnectionStatus.connecting:
        return 'Refreshing token...';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatScopeName(String scope) {
    return scope
        .split('.')
        .map((part) => part.replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}',
            ))
        .join(' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _testConnection() async {
    // Implement connection testing
    HapticFeedback.lightImpact();
    // Show test results
  }

  void _copyConnectionInfo() {
    final info = {
      'provider': widget.provider.displayName,
      'status': _getStatusText(),
      'connected_at': widget.state.connectedAt?.toIso8601String(),
      'expires_at': widget.state.expiresAt?.toIso8601String(),
      'scopes': widget.state.grantedScopes,
    };
    
    Clipboard.setData(ClipboardData(text: info.toString()));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection details copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}