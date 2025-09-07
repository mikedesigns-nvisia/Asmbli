import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';

class MCPCatalogEntryCard extends StatefulWidget {
  final MCPCatalogEntry entry;
  final VoidCallback? onTap;

  const MCPCatalogEntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  State<MCPCatalogEntryCard> createState() => _MCPCatalogEntryCardState();
}

class _MCPCatalogEntryCardState extends State<MCPCatalogEntryCard>
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
    final cardColors = _getCardColors(colors);

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AsmblCard(
                child: Container(
                  padding: EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                    border: Border.all(
                      color: _isHovered 
                        ? cardColors.borderColor.withOpacity(0.8) 
                        : cardColors.borderColor.withOpacity(0.3),
                      width: _isHovered ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColors.backgroundColor.withOpacity(0.05),
                        cardColors.backgroundColor.withOpacity(0.02),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(colors, cardColors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildDescription(colors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildMetaInfo(colors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildCapabilities(colors, cardColors),
                      SizedBox(height: SpacingTokens.sm),
                      _buildFooter(colors),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, _CardColors cardColors) {
    return Row(
      children: [
        // Server icon
        Container(
          padding: EdgeInsets.all(SpacingTokens.xs),
          decoration: BoxDecoration(
            color: cardColors.backgroundColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getServerIcon(),
            size: 20,
            color: cardColors.iconColor,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.name,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.entry.isOfficial)
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: colors.primary,
                    ),
                ],
              ),
              if (widget.entry.pricing != null) ...[
                SizedBox(height: SpacingTokens.xs),
                _buildPricingBadge(colors),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeColors colors) {
    return Text(
      widget.entry.description,
      style: TextStyles.bodySmall.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.2,
        fontSize: 11,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaInfo(ThemeColors colors) {
    return Row(
      children: [
        // Version
        _buildInfoChip(
          icon: Icons.tag,
          text: 'v${widget.entry.version}',
          colors: colors,
        ),
        SizedBox(width: SpacingTokens.xs),
        // Transport type
        _buildInfoChip(
          icon: _getTransportIcon(),
          text: widget.entry.transport.name.toUpperCase(),
          colors: colors,
        ),
        if (widget.entry.lastUpdated != null) ...[
          SizedBox(width: SpacingTokens.xs),
          _buildInfoChip(
            icon: Icons.schedule,
            text: _getTimeAgo(widget.entry.lastUpdated!),
            colors: colors,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ThemeColors colors,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs,
        vertical: SpacingTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        border: Border.all(
          color: colors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: colors.onSurfaceVariant,
          ),
          SizedBox(width: SpacingTokens.xxs),
          Text(
            text,
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilities(ThemeColors colors, _CardColors cardColors) {
    if (widget.entry.capabilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.build,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Capabilities',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.xxs),
        Wrap(
          spacing: SpacingTokens.xxs,
          runSpacing: SpacingTokens.xxs,
          children: widget.entry.capabilities.take(3).map((capability) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: SpacingTokens.xxs,
              ),
              decoration: BoxDecoration(
                color: cardColors.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                border: Border.all(
                  color: cardColors.accentColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                capability.replaceAll('-', ' '),
                style: TextStyles.caption.copyWith(
                  color: cardColors.accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                widget.entry.hasAuth ? Icons.key : Icons.check_circle_outline,
                size: 14,
                color: widget.entry.hasAuth 
                    ? colors.onSurfaceVariant 
                    : colors.primary,
              ),
              SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  widget.entry.hasAuth ? 'Auth required' : 'Ready to use',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: colors.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildPricingBadge(ThemeColors colors) {
    Color badgeColor;
    String badgeText;

    switch (widget.entry.pricing!) {
      case MCPPricingModel.free:
        badgeColor = colors.primary;
        badgeText = 'Free';
        break;
      case MCPPricingModel.freemium:
        badgeColor = colors.accent;
        badgeText = 'Freemium';
        break;
      case MCPPricingModel.paid:
        badgeColor = Colors.orange;
        badgeText = 'Paid';
        break;
      case MCPPricingModel.usageBased:
        badgeColor = Colors.purple;
        badgeText = 'Usage';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs,
        vertical: SpacingTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyles.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  IconData _getServerIcon() {
    switch (widget.entry.category) {
      case MCPServerCategory.ai:
        return Icons.psychology;
      case MCPServerCategory.cloud:
        return Icons.cloud;
      case MCPServerCategory.communication:
        return Icons.chat;
      case MCPServerCategory.database:
        return Icons.storage;
      case MCPServerCategory.design:
        return Icons.palette;
      case MCPServerCategory.development:
        return Icons.code;
      case MCPServerCategory.filesystem:
        return Icons.folder;
      case MCPServerCategory.productivity:
        return Icons.work;
      case MCPServerCategory.security:
        return Icons.security;
      case MCPServerCategory.web:
        return Icons.web;
    }
  }

  IconData _getTransportIcon() {
    switch (widget.entry.transport) {
      case MCPTransportType.stdio:
        return Icons.terminal;
      case MCPTransportType.sse:
        return Icons.stream;
      case MCPTransportType.http:
        return Icons.http;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  /// Get themed colors for the card based on server category and attributes
  _CardColors _getCardColors(ThemeColors colors) {
    // Base color selection based on server category
    Color baseColor;
    switch (widget.entry.category) {
      case MCPServerCategory.ai:
        baseColor = colors.info; // Blue for AI
        break;
      case MCPServerCategory.database:
        baseColor = colors.success; // Green for databases
        break;
      case MCPServerCategory.web:
        baseColor = colors.accent; // Accent color for web/APIs
        break;
      case MCPServerCategory.development:
        baseColor = colors.primary; // Primary for dev tools
        break;
      case MCPServerCategory.cloud:
        baseColor = colors.info; // Blue for cloud services
        break;
      case MCPServerCategory.security:
        baseColor = colors.warning; // Orange/yellow for security
        break;
      case MCPServerCategory.communication:
        baseColor = colors.success; // Green for communication
        break;
      case MCPServerCategory.productivity:
        baseColor = colors.accent; // Accent for productivity
        break;
      case MCPServerCategory.filesystem:
        baseColor = colors.warning; // Orange for filesystem
        break;
      case MCPServerCategory.design:
        baseColor = colors.primary; // Primary for design tools
        break;
      default:
        baseColor = colors.primary;
    }

    // Modify base color for official vs community servers
    Color finalColor = baseColor;
    Color accentColor = baseColor;
    
    if (widget.entry.isOfficial) {
      // Official servers get more vibrant, trustworthy colors
      finalColor = baseColor;
      accentColor = baseColor;
    } else {
      // Community servers get slightly muted colors with different accent
      finalColor = baseColor.withOpacity(0.8);
      accentColor = colors.accent; // Use accent color for community servers
    }

    // Special handling for featured servers - make them stand out more
    if (widget.entry.isFeatured) {
      finalColor = baseColor;
      accentColor = colors.primary; // Featured servers use primary accent
    }

    return _CardColors(
      backgroundColor: finalColor,
      borderColor: finalColor,
      iconColor: finalColor,
      accentColor: accentColor,
    );
  }
}

/// Card color scheme for themed MCP server cards
class _CardColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color accentColor;

  const _CardColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.accentColor,
  });
}