import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../agents/data/models/agent_template.dart';

class EnhancedAgentTemplateCard extends StatefulWidget {
  final AgentTemplate template;
  final VoidCallback? onUseTemplate;
  final VoidCallback? onPreview;
  final VoidCallback? onFavorite;

  const EnhancedAgentTemplateCard({
    super.key,
    required this.template,
    this.onUseTemplate,
    this.onPreview,
    this.onFavorite,
  });

  @override
  State<EnhancedAgentTemplateCard> createState() => _EnhancedAgentTemplateCardState();
}

class _EnhancedAgentTemplateCardState extends State<EnhancedAgentTemplateCard>
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
        onTap: widget.onPreview ?? () => _showPreviewDialog(context),
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
                        ? cardColors.borderColor.withValues(alpha: 0.8) 
                        : cardColors.borderColor.withValues(alpha: 0.3),
                      width: _isHovered ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColors.backgroundColor.withValues(alpha: 0.05),
                        cardColors.backgroundColor.withValues(alpha: 0.02),
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
                      _buildReasoningFlow(colors, cardColors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildRecommendedLLM(colors, cardColors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildTags(colors, cardColors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildMCPServers(colors, cardColors),
                      Spacer(),
                      _buildFooter(colors, cardColors),
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
        // Template icon
        Container(
          padding: EdgeInsets.all(SpacingTokens.xs),
          decoration: BoxDecoration(
            color: cardColors.backgroundColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getCategoryIcon(widget.template.category),
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
                      widget.template.name,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.template.isComingSoon)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: SpacingTokens.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                      ),
                      child: Text(
                        'Soon',
                        style: TextStyles.caption.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2),
              _buildCategoryBadge(colors, cardColors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeColors colors) {
    return Text(
      widget.template.description,
      style: TextStyles.bodySmall.copyWith(
        color: colors.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(ThemeColors colors, _CardColors cardColors) {
    if (widget.template.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Tags',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.xxs),
        Wrap(
          spacing: SpacingTokens.xxs,
          runSpacing: SpacingTokens.xxs,
          children: widget.template.tags.take(3).map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: SpacingTokens.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                tag.replaceAll('-', ' '),
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMCPServers(ThemeColors colors, _CardColors cardColors) {
    if (!widget.template.mcpStack) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.extension_outlined,
          size: 12,
          color: cardColors.accentColor,
        ),
        SizedBox(width: SpacingTokens.xs),
        Text(
          'MCP Enabled',
          style: TextStyles.caption.copyWith(
            color: cardColors.accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: SpacingTokens.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.xs,
            vertical: SpacingTokens.xxs,
          ),
          decoration: BoxDecoration(
            color: cardColors.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
          ),
          child: Text(
            '${widget.template.mcpServers.length} tools',
            style: TextStyles.caption.copyWith(
              color: cardColors.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeColors colors, _CardColors cardColors) {
    return Row(
      children: [
        // Popularity indicator
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                '${widget.template.popularity}%',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Hire button
        _buildHireButton(colors, cardColors),
      ],
    );
  }

  Widget _buildHireButton(ThemeColors colors, _CardColors cardColors) {
    if (widget.template.isComingSoon) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Coming Soon',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onUseTemplate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: cardColors.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: cardColors.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 12,
              color: cardColors.accentColor,
            ),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Create',
              style: TextStyles.caption.copyWith(
                color: cardColors.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ThemeColors colors, _CardColors cardColors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs,
        vertical: SpacingTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: cardColors.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        border: Border.all(
          color: cardColors.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        widget.template.category,
        style: TextStyles.caption.copyWith(
          color: cardColors.accentColor,
          fontWeight: FontWeight.w500,
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

  void _showPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ThemeColors(context).surface,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(SpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(widget.template.category),
                    color: _getCardColors(ThemeColors(context)).iconColor,
                    size: 24,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      widget.template.name,
                      style: TextStyles.pageTitle.copyWith(
                        color: ThemeColors(context).onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: ThemeColors(context).onSurfaceVariant),
                  ),
                ],
              ),
              SizedBox(height: SpacingTokens.lg),
              // Category and popularity
              Row(
                children: [
                  _buildCategoryBadge(ThemeColors(context), _getCardColors(ThemeColors(context))),
                  SizedBox(width: SpacingTokens.sm),
                  Icon(Icons.trending_up, size: 16, color: ThemeColors(context).onSurfaceVariant),
                  SizedBox(width: SpacingTokens.xs),
                  Text(
                    '${widget.template.popularity}% popularity',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingTokens.lg),
              // Description
              Text(
                'Description',
                style: TextStyles.bodyLarge.copyWith(
                  color: ThemeColors(context).onSurface,
                ),
              ),
              SizedBox(height: SpacingTokens.sm),
              Text(
                widget.template.description,
                style: TextStyles.bodyMedium.copyWith(
                  color: ThemeColors(context).onSurface,
                  height: 1.6,
                ),
              ),
              SizedBox(height: SpacingTokens.lg),
              // Example use
              if (widget.template.exampleUse.isNotEmpty) ...[
                Text(
                  'Example Use',
                  style: TextStyles.bodyLarge.copyWith(
                    color: ThemeColors(context).onSurface,
                  ),
                ),
                SizedBox(height: SpacingTokens.sm),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: ThemeColors(context).surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: ThemeColors(context).border),
                  ),
                  child: Text(
                    widget.template.exampleUse,
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              Spacer(),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  if (!widget.template.isComingSoon)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onUseTemplate != null) {
                          widget.onUseTemplate!();
                        }
                      },
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Create Agent'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'research':
        return Icons.search;
      case 'development':
        return Icons.code;
      case 'writing':
        return Icons.edit;
      case 'data analysis':
        return Icons.analytics;
      case 'customer support':
        return Icons.support_agent;
      case 'marketing':
        return Icons.campaign;
      default:
        return Icons.smart_toy;
    }
  }

  /// Get themed colors for the card based on template category
  _CardColors _getCardColors(ThemeColors colors) {
    Color baseColor;
    switch (widget.template.category.toLowerCase()) {
      case 'research':
        baseColor = colors.info; // Blue for research
        break;
      case 'development':
        baseColor = colors.primary; // Primary for development
        break;
      case 'writing':
        baseColor = colors.accent; // Accent for writing
        break;
      case 'data analysis':
        baseColor = colors.success; // Green for data
        break;
      case 'customer support':
        baseColor = colors.warning; // Orange for support
        break;
      case 'marketing':
        baseColor = colors.accent; // Accent for marketing
        break;
      default:
        baseColor = colors.primary; // Primary for general
    }

    return _CardColors(
      backgroundColor: baseColor,
      borderColor: baseColor,
      iconColor: baseColor,
      accentColor: baseColor,
    );
  }

  Widget _buildReasoningFlow(ThemeColors colors, _CardColors cardColors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: cardColors.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: cardColors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.template.reasoningFlow.icon,
            style: TextStyle(
              fontSize: 12,
              color: cardColors.iconColor,
            ),
          ),
          SizedBox(width: SpacingTokens.xs),
          Text(
            widget.template.reasoningFlow.name,
            style: TextStyles.caption.copyWith(
              color: cardColors.iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedLLM(ThemeColors colors, _CardColors cardColors) {
    final recommended = widget.template.recommendedModel;
    if (recommended == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Recommended LLM',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.xxs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.xs,
          ),
          decoration: BoxDecoration(
            color: _getProviderColor(recommended.provider, colors).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            border: Border.all(
              color: _getProviderColor(recommended.provider, colors).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getProviderIcon(recommended.provider),
                size: 12,
                color: _getProviderColor(recommended.provider, colors),
              ),
              SizedBox(width: SpacingTokens.xs),
              Flexible(
                child: Text(
                  recommended.displayName,
                  style: TextStyles.caption.copyWith(
                    color: _getProviderColor(recommended.provider, colors),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (recommended.isLocal) ...[
                SizedBox(width: SpacingTokens.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SpacingTokens.xxs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                  ),
                  child: Text(
                    'Local',
                    style: TextStyles.caption.copyWith(
                      fontSize: 9,
                      color: colors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Show alternatives count if available
        if (widget.template.alternativeModels.isNotEmpty) ...[
          SizedBox(height: SpacingTokens.xxs),
          Text(
            '+${widget.template.alternativeModels.length} alternatives',
            style: TextStyles.caption.copyWith(
              fontSize: 10,
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Color _getProviderColor(String provider, ThemeColors colors) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return colors.success; // Green for OpenAI
      case 'anthropic':
        return colors.accent; // Accent for Anthropic
      case 'google':
        return colors.info; // Blue for Google
      case 'ollama':
        return colors.primary; // Primary for local Ollama
      default:
        return colors.onSurfaceVariant;
    }
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return Icons.auto_awesome;
      case 'anthropic':
        return Icons.hub;
      case 'google':
        return Icons.cloud;
      case 'ollama':
        return Icons.computer;
      default:
        return Icons.psychology;
    }
  }
}

/// Card color scheme for themed template cards
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