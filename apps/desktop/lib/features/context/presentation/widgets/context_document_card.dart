import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';

class ContextDocumentCard extends StatefulWidget {
  final ContextDocument document;
  final Function(ContextDocument)? onEdit;
  final Function(String)? onDelete;
  final Function(String)? onAssignToAgent;
  final VoidCallback? onPreview;

  const ContextDocumentCard({
    super.key,
    required this.document,
    this.onEdit,
    this.onDelete,
    this.onAssignToAgent,
    this.onPreview,
  });

  @override
  State<ContextDocumentCard> createState() => _ContextDocumentCardState();
}

class _ContextDocumentCardState extends State<ContextDocumentCard>
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
        onTap: widget.onPreview,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header with type and actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.sm,
                              vertical: SpacingTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(widget.document.type, colors),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            child: Text(
                              widget.document.type.displayName,
                              style: TextStyles.caption.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: colors.onSurfaceVariant,
                              size: 20,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16, color: colors.onSurface),
                                    const SizedBox(width: SpacingTokens.sm),
                                    Text('Edit', style: TextStyles.bodyMedium),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'assign',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add, size: 16, color: colors.onSurface),
                                    const SizedBox(width: SpacingTokens.sm),
                                    Text('Assign to Agent', style: TextStyles.bodyMedium),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 16, color: colors.error),
                                    const SizedBox(width: SpacingTokens.sm),
                                    Text(
                                      'Delete',
                                      style: TextStyles.bodyMedium.copyWith(color: colors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) => _handleMenuAction(value, context),
                          ),
                        ],
                      ),

                      const SizedBox(height: SpacingTokens.lg),

                      // Title
                      Text(
                        widget.document.title,
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: SpacingTokens.sm),

                      // Content preview
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
                          child: Text(
                            widget.document.content,
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: SpacingTokens.lg),

                      // Tags
                      if (widget.document.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: SpacingTokens.xs,
                          runSpacing: SpacingTokens.xs,
                          alignment: WrapAlignment.center,
                          children: widget.document.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                              ),
                              child: Text(
                                tag,
                                style: TextStyles.caption.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                      ],

                      // Footer with timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Updated ${_formatDate(widget.document.updatedAt)}',
                            style: TextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (widget.document.isActive) ...[
                            const SizedBox(width: SpacingTokens.sm),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Color _getTypeColor(ContextType type, ThemeColors colors) {
    switch (type) {
      case ContextType.documentation:
        return colors.primary;
      case ContextType.codebase:
        return colors.info;
      case ContextType.guidelines:
        return colors.warning;
      case ContextType.examples:
        return colors.success;
      case ContextType.knowledge:
        return colors.primary.withOpacity( 0.8);
      case ContextType.custom:
        return colors.onSurfaceVariant;
    }
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'edit':
        if (widget.onEdit != null) {
          widget.onEdit!(widget.document);
        } else {
          _showEditDialog(context);
        }
        break;
      case 'assign':
        if (widget.onAssignToAgent != null) {
          widget.onAssignToAgent!(widget.document.id);
        }
        break;
      case 'delete':
        if (widget.onDelete != null) {
          _showDeleteDialog(context);
        }
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface,
        title: Text(
          'Edit Document',
          style: TextStyles.cardTitle.copyWith(
            color: ThemeColors(context).onSurface,
          ),
        ),
        content: Text(
          'Edit functionality will be implemented here',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface,
        title: Text(
          'Delete Document',
          style: TextStyles.cardTitle.copyWith(
            color: ThemeColors(context).onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.document.title}"? This action cannot be undone.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onDelete != null) {
                widget.onDelete!(widget.document.id);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors(context).error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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

  /// Get themed colors for the card based on document type
  _CardColors _getCardColors(ThemeColors colors) {
    Color baseColor;
    switch (widget.document.type) {
      case ContextType.documentation:
        baseColor = colors.info; // Blue for documentation
        break;
      case ContextType.codebase:
        baseColor = colors.primary; // Primary for code
        break;
      case ContextType.guidelines:
        baseColor = colors.warning; // Orange for guidelines
        break;
      case ContextType.examples:
        baseColor = colors.success; // Green for examples
        break;
      case ContextType.knowledge:
        baseColor = colors.accent; // Accent for knowledge
        break;
      case ContextType.custom:
        baseColor = colors.primary; // Primary for custom
        break;
      default:
        baseColor = colors.primary;
    }

    return _CardColors(
      backgroundColor: baseColor,
      borderColor: baseColor,
      iconColor: baseColor,
      accentColor: baseColor,
    );
  }
}

/// Card color scheme for themed context document cards
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