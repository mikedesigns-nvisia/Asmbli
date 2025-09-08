import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';

/// Card widget for displaying OAuth provider connection status and actions
class OAuthProviderCard extends StatelessWidget {
  final OAuthProvider provider;
  final OAuthProviderState state;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;

  const OAuthProviderCard({
    super.key,
    required this.provider,
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final info = provider.info;

    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, info),
            SizedBox(height: SpacingTokens.md),
            _buildConnectionStatus(colors),
            SizedBox(height: SpacingTokens.md),
            _buildCapabilities(colors, info),
            SizedBox(height: SpacingTokens.lg),
            _buildActions(colors, info),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, OAuthProviderInfo info) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: _buildProviderIcon(colors),
        ),
        SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    info.name,
                    style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
                  ),
                  if (info.requiresApproval) ...[ 
                    SizedBox(width: SpacingTokens.sm),
                    _buildApprovalBadge(colors),
                  ],
                ],
              ),
              SizedBox(height: SpacingTokens.xs),
              Text(
                info.description,
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildConnectionIndicator(colors),
      ],
    );
  }

  Widget _buildProviderIcon(ThemeColors colors) {
    IconData iconData;
    switch (provider) {
      case OAuthProvider.github:
        iconData = Icons.code;
        break;
      case OAuthProvider.slack:
        iconData = Icons.chat;
        break;
      case OAuthProvider.linear:
        iconData = Icons.linear_scale;
        break;
      case OAuthProvider.microsoft:
        iconData = Icons.business;
        break;
    }

    return Icon(
      iconData,
      size: 24,
      color: state.status.isActive ? colors.primary : colors.onSurfaceVariant,
    );
  }

  Widget _buildConnectionStatus(ThemeColors colors) {
    Color statusColor;
    IconData statusIcon;
    
    switch (state.status) {
      case OAuthConnectionStatus.connected:
        statusColor = colors.primary;
        statusIcon = Icons.check_circle;
        break;
      case OAuthConnectionStatus.connecting:
        statusColor = colors.accent;
        statusIcon = Icons.sync;
        break;
      case OAuthConnectionStatus.expired:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case OAuthConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case OAuthConnectionStatus.disconnected:
        statusColor = colors.onSurfaceVariant;
        statusIcon = Icons.circle_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.status == OAuthConnectionStatus.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(statusIcon, size: 14, color: statusColor),
          SizedBox(width: SpacingTokens.xs),
          Text(
            state.status.displayName,
            style: TextStyles.caption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.connectedAt != null && state.status.isActive) ...[ 
            SizedBox(width: SpacingTokens.sm),
            Text(
              '•',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(width: SpacingTokens.sm),
            Text(
              _formatConnectionTime(state.connectedAt!),
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapabilities(ThemeColors colors, OAuthProviderInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capabilities',
          style: TextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.sm),
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: info.capabilities.map((capability) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.accent.withOpacity(0.3)),
              ),
              child: Text(
                capability,
                style: TextStyles.caption.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeColors colors, OAuthProviderInfo info) {
    return Row(
      children: [
        if (state.status == OAuthConnectionStatus.disconnected ||
            state.status == OAuthConnectionStatus.error)
          AsmblButton.primary(
            text: 'Connect',
            onPressed: onConnect,
            icon: Icons.link,
          )
        else if (state.status == OAuthConnectionStatus.connected)
          Row(
            children: [
              AsmblButton.secondary(
                text: 'Refresh',
                onPressed: onRefresh,
                icon: Icons.refresh,
              ),
              SizedBox(width: SpacingTokens.sm),
              AsmblButton.secondary(
                text: 'Disconnect',
                onPressed: () => _showDisconnectConfirmation(colors),
                icon: Icons.link_off,
              ),
            ],
          )
        else if (state.status == OAuthConnectionStatus.expired)
          AsmblButton.primary(
            text: 'Refresh Token',
            onPressed: onRefresh,
            icon: Icons.refresh,
          )
        else if (state.status == OAuthConnectionStatus.connecting)
          AsmblButton.secondary(
            text: 'Connecting...',
            onPressed: null,
            icon: Icons.hourglass_empty,
          ),
        
        const Spacer(),
        
        // Documentation link
        GestureDetector(
          onTap: () => _launchDocumentation(info.documentationUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline,
                size: 16,
                color: colors.accent,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Docs',
                style: TextStyles.caption.copyWith(
                  color: colors.accent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator(ThemeColors colors) {
    Color indicatorColor;
    switch (state.status) {
      case OAuthConnectionStatus.connected:
        indicatorColor = colors.primary;
        break;
      case OAuthConnectionStatus.connecting:
        indicatorColor = colors.accent;
        break;
      case OAuthConnectionStatus.expired:
        indicatorColor = Colors.orange;
        break;
      case OAuthConnectionStatus.error:
        indicatorColor = Colors.red;
        break;
      case OAuthConnectionStatus.disconnected:
        indicatorColor = colors.onSurfaceVariant.withOpacity(0.3);
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildApprovalBadge(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        border: Border.all(color: colors.accent.withOpacity(0.3)),
      ),
      child: Text(
        'Approval Required',
        style: TextStyles.caption.copyWith(
          color: colors.accent,
                   fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatConnectionTime(DateTime connectedAt) {
    final now = DateTime.now();
    final difference = now.difference(connectedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showDisconnectConfirmation(ThemeColors colors) async {
    // This would show a confirmation dialog
    // For now, directly call disconnect
    HapticFeedback.lightImpact();
    onDisconnect();
  }

  Future<void> _launchDocumentation(String url) async {
    // This would launch the documentation URL
    // Implementation depends on url_launcher package
  }
}