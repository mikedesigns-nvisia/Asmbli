import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/reasoning_workflow.dart';
import '../../../../core/design_system/design_system.dart';

/// Card widget for displaying workflow information in the browser
class WorkflowCard extends StatelessWidget {
  final ReasoningWorkflow workflow;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const WorkflowCard({
    super.key,
    required this.workflow,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return AsmblCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and menu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflow.name,
                          style: TextStyles.cardTitle.copyWith(
                            color: colors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (workflow.isTemplate)
                          Container(
                            margin: const EdgeInsets.only(top: SpacingTokens.xs),
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Template',
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'export':
                          onExport();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: SpacingTokens.sm),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: SpacingTokens.sm),
                            Text('Export'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: colors.error),
                            const SizedBox(width: SpacingTokens.sm),
                            Text('Delete', style: TextStyle(color: colors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              // Description
              if (workflow.description != null && workflow.description!.isNotEmpty)
                Text(
                  workflow.description!,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'No description',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              
              const SizedBox(height: SpacingTokens.md),
              
              // Tags
              if (workflow.tags.isNotEmpty)
                Wrap(
                  spacing: SpacingTokens.xs,
                  runSpacing: SpacingTokens.xs,
                  children: workflow.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      tag,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  )).toList()
                    ..addAll(workflow.tags.length > 3 ? [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: 2,
                        ),
                        child: Text(
                          '+${workflow.tags.length - 3}',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ] : []),
                ),
              
              const Spacer(),
              
              // Stats and metadata
              Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '${workflow.blocks.length} blocks',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Icon(
                    Icons.link,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '${workflow.connections.length} connections',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.sm),
              
              // Updated date
              Text(
                'Updated ${dateFormat.format(workflow.updatedAt)}',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}