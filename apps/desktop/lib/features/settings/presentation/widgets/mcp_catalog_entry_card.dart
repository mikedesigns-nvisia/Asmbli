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
                  padding: EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                    border: Border.all(
                      color: _isHovered ? colors.primary.withOpacity(0.3) : colors.border,
                      width: _isHovered ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(colors),
                      SizedBox(height: SpacingTokens.sm),
                      _buildDescription(colors),
                      SizedBox(height: SpacingTokens.md),
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

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        // Server icon
        Container(
          padding: EdgeInsets.all(SpacingTokens.xs),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getServerIcon(),
            size: 20,
            color: colors.primary,
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
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Column(
      children: [
        // Capabilities chips
        if (widget.entry.capabilities.isNotEmpty) ...[
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: widget.entry.capabilities.take(3).map((capability) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: SpacingTokens.xxs,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                  border: Border.all(
                    color: colors.accent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  capability.replaceAll('-', ' '),
                  style: TextStyles.caption.copyWith(
                    color: colors.accent,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: SpacingTokens.sm),
        ],
        
        // Setup status and action
        Row(
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
}