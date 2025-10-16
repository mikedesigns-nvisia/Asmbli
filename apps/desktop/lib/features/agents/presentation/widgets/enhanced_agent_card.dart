import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

class EnhancedAgentCard extends StatefulWidget {
  final Agent agent;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onChat;
  final VoidCallback? onActivate;
  final VoidCallback? onOpenChat;

  const EnhancedAgentCard({
    super.key,
    required this.agent,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onChat,
    this.onActivate,
    this.onOpenChat,
  });

  @override
  State<EnhancedAgentCard> createState() => _EnhancedAgentCardState();
}

class _EnhancedAgentCardState extends State<EnhancedAgentCard>
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
        onTap: widget.onOpenChat ?? widget.onChat ?? () => context.go('${AppRoutes.chat}?agent=${widget.agent.id}'),
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
                      _buildCapabilities(colors, cardColors),
                      SizedBox(height: SpacingTokens.xs),
                      _buildReasoning(colors, cardColors),
                      Spacer(),
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
        // Agent icon with status
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: EdgeInsets.all(SpacingTokens.xs),
              decoration: BoxDecoration(
                color: cardColors.backgroundColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: cardColors.iconColor,
              ),
            ),
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(colors),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.surface,
                  width: 1,
                ),
              ),
            ),
          ],
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
                      widget.agent.name,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildActionsMenu(colors),
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

  Widget _buildActionsMenu(ThemeColors colors) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: colors.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      iconSize: 16,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'chat',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: colors.onSurface),
              SizedBox(width: SpacingTokens.xs),
              Text('Chat', style: TextStyles.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 14, color: colors.onSurface),
              SizedBox(width: SpacingTokens.xs),
              Text('Edit', style: TextStyles.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'activate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.agent.status == AgentStatus.active 
                  ? Icons.pause_circle_outline 
                  : Icons.play_circle_outline,
                size: 14, 
                color: colors.onSurface
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                widget.agent.status == AgentStatus.active ? 'Deactivate' : 'Activate',
                style: TextStyles.bodySmall
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_outlined, size: 14, color: colors.onSurface),
              SizedBox(width: SpacingTokens.xs),
              Text('Duplicate', style: TextStyles.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 14, color: colors.error),
              SizedBox(width: SpacingTokens.xs),
              Text('Delete', style: TextStyles.bodySmall.copyWith(color: colors.error)),
            ],
          ),
        ),
      ],
      onSelected: _handleMenuAction,
    );
  }

  Widget _buildDescription(ThemeColors colors) {
    return Text(
      widget.agent.description,
      style: TextStyles.bodySmall.copyWith(
        color: colors.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCapabilities(ThemeColors colors, _CardColors cardColors) {
    if (widget.agent.capabilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.build_outlined,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Capabilities',
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
          children: widget.agent.capabilities.take(3).map((capability) {
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
                capability.replaceAll('-', ' '),
                style: TextStyles.caption.copyWith(
                  color: cardColors.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReasoning(ThemeColors colors, _CardColors cardColors) {
    // Check if agent has reasoning workflows or configuration
    final config = widget.agent.configuration;
    final hasReasoningFlows = config['enableReasoningFlows'] == true;
    final reasoningWorkflows = config['reasoningWorkflowIds'] as List? ?? [];
    final defaultWorkflow = config['defaultReasoningWorkflowId'] as String?;
    
    // If no reasoning capabilities, don't show this section
    if (!hasReasoningFlows && reasoningWorkflows.isEmpty) {
      return const SizedBox.shrink();
    }

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
              'Reasoning',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.xxs),
        
        // Show reasoning status and workflows
        Row(
          children: [
            // Reasoning enabled indicator
            if (hasReasoningFlows) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: SpacingTokens.xxs,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 10,
                      color: colors.success,
                    ),
                    SizedBox(width: SpacingTokens.xxs),
                    Text(
                      'Visual Reasoning',
                      style: TextStyles.caption.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (reasoningWorkflows.isNotEmpty) SizedBox(width: SpacingTokens.xs),
            ],
            
            // Workflow count
            if (reasoningWorkflows.isNotEmpty) ...[
              Container(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 10,
                      color: cardColors.accentColor,
                    ),
                    SizedBox(width: SpacingTokens.xxs),
                    Text(
                      '${reasoningWorkflows.length} workflow${reasoningWorkflows.length == 1 ? '' : 's'}',
                      style: TextStyles.caption.copyWith(
                        color: cardColors.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Default workflow indicator
            if (defaultWorkflow != null) ...[
              SizedBox(width: SpacingTokens.xs),
              Icon(
                Icons.star_outline,
                size: 10,
                color: colors.warning,
              ),
            ],
          ],
        ),
        
        // If no visual reasoning but might have basic reasoning patterns
        if (!hasReasoningFlows && reasoningWorkflows.isEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingTokens.xs,
              vertical: SpacingTokens.xxs,
            ),
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
              border: Border.all(
                color: colors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Basic reasoning',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
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
                Icons.schedule,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                _getLastUsedText(),
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.xs,
            vertical: SpacingTokens.xxs,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(colors).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
            border: Border.all(
              color: _getStatusColor(colors).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyles.caption.copyWith(
              color: _getStatusColor(colors),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getLastUsedText() {
    final lastUsed = widget.agent.configuration['lastUsed'] as String?;
    if (lastUsed != null) {
      try {
        final lastUsedDate = DateTime.parse(lastUsed);
        final now = DateTime.now();
        final diff = now.difference(lastUsedDate);
        
        if (diff.inDays > 7) {
          return '${diff.inDays} days ago';
        } else if (diff.inDays > 0) {
          return '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          return '${diff.inHours}h ago';
        } else if (diff.inMinutes > 0) {
          return '${diff.inMinutes}m ago';
        } else {
          return 'Just now';
        }
      } catch (e) {
        return 'Never used';
      }
    }
    return 'Never used';
  }

  String _getStatusText() {
    switch (widget.agent.status) {
      case AgentStatus.idle:
        return 'Ready';
      case AgentStatus.active:
        return 'Active';
      case AgentStatus.error:
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  Widget _buildCategoryBadge(ThemeColors colors, _CardColors cardColors) {
    final category = widget.agent.configuration?['category'] as String? ?? 'General';
    
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
        category,
        style: TextStyles.caption.copyWith(
          color: cardColors.accentColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeColors colors) {
    switch (widget.agent.status) {
      case AgentStatus.idle:
        return colors.success;
      case AgentStatus.active:
        return colors.warning;
      case AgentStatus.error:
        return colors.error;
      default:
        return colors.onSurfaceVariant;
    }
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'chat':
        if (widget.onOpenChat != null) {
          widget.onOpenChat!();
        } else if (widget.onChat != null) {
          widget.onChat!();
        } else {
          context.go('${AppRoutes.chat}?agent=${widget.agent.id}');
        }
        break;
      case 'edit':
        if (widget.onEdit != null) {
          widget.onEdit!();
        } else {
          context.go('/agents/configure/${widget.agent.id}');
        }
        break;
      case 'activate':
        if (widget.onActivate != null) {
          widget.onActivate!();
        }
        break;
      case 'duplicate':
        if (widget.onDuplicate != null) {
          widget.onDuplicate!();
        }
        break;
      case 'delete':
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
        break;
    }
  }

  /// Get themed colors for the card based on agent category
  _CardColors _getCardColors(ThemeColors colors) {
    final category = widget.agent.configuration?['category'] as String? ?? 'General';
    
    Color baseColor;
    switch (category.toLowerCase()) {
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
      case 'analytics':
        baseColor = colors.success; // Green for data
        break;
      case 'customer support':
      case 'support':
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
}

/// Card color scheme for themed agent cards
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