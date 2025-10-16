import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../services/workflow_execution_service.dart';
// import '../../services/workflow_execution_engine.dart'; // Temporarily commented due to import conflicts
import 'agency_feedback_panel.dart';

/// Overlay widget that shows real-time execution status on the canvas
class ExecutionOverlay extends ConsumerWidget {
  final List<LogicBlock> blocks;
  final WorkflowExecutionContext? executionContext;
  final bool isExecuting;
  final String? currentBlockId;
  // final Stream<ExecutionEvent>? executionEvents; // Temporarily commented
  
  const ExecutionOverlay({
    super.key,
    required this.blocks,
    this.executionContext,
    this.isExecuting = false,
    this.currentBlockId,
    // this.executionEvents, // Temporarily commented
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    if (!isExecuting && executionContext == null) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Block execution indicators with decision trails
        ...blocks.map((block) => Positioned(
          left: block.position.x + block.defaultWidth + 8,
          top: block.position.y,
          child: _buildEnhancedBlockIndicator(block, colors),
        )),
        
        // Progress indicator
        if (isExecuting)
          Positioned(
            top: 20,
            right: 20,
            child: _buildProgressIndicator(colors),
          ),
        
        // Execution summary
        if (executionContext != null && !isExecuting)
          Positioned(
            top: 20,
            right: 20,
            child: _buildExecutionSummary(executionContext!, colors),
          ),
        
        // Agency feedback panel (expandable)
        if (executionContext != null || isExecuting)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildAgencyInsightsToggle(colors, context),
          ),
      ],
    );
  }

  Widget _buildEnhancedBlockIndicator(LogicBlock block, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBlockExecutionIndicator(block, colors),
        if (_hasDecisionTrail(block))
          const SizedBox(height: 4),
        if (_hasDecisionTrail(block))
          _buildDecisionTrail(block, colors),
      ],
    );
  }

  Widget _buildBlockExecutionIndicator(LogicBlock block, ThemeColors colors) {
    final blockResult = executionContext?.blockResults.where((r) => r.blockId == block.id).firstOrNull;
    final isCurrentBlock = currentBlockId == block.id;
    final hasError = blockResult?.state == BlockExecutionState.failed;
    
    Widget indicator;
    Color indicatorColor;
    String tooltip;
    
    if (isCurrentBlock && isExecuting) {
      // Currently executing
      indicator = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(colors.primary),
        ),
      );
      indicatorColor = colors.primary;
      tooltip = 'Executing...';
    } else if (hasError) {
      // Block had an error
      indicator = Icon(Icons.error, size: 16, color: colors.error);
      indicatorColor = colors.error;
      tooltip = blockResult?.error ?? 'Error occurred';
    } else if (blockResult?.state == BlockExecutionState.completed) {
      // Block completed successfully
      indicator = Icon(Icons.check_circle, size: 16, color: colors.success);
      indicatorColor = colors.success;
      tooltip = 'Completed successfully in ${blockResult!.executionTime.inMilliseconds}ms';
    } else if (blockResult?.state == BlockExecutionState.skipped) {
      // Block was skipped
      indicator = Icon(Icons.skip_next, size: 16, color: colors.warning);
      indicatorColor = colors.warning;
      tooltip = 'Skipped due to conditions';
    } else {
      // Not executed yet
      indicator = Icon(Icons.circle_outlined, size: 16, color: colors.onSurfaceVariant);
      indicatorColor = colors.onSurfaceVariant;
      tooltip = 'Pending execution';
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: indicator,
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeColors colors) {
    return AsmblCard(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              'Executing...',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionSummary(WorkflowExecutionContext context, ThemeColors colors) {
    final completedBlocks = context.blockResults.where((r) => r.state == BlockExecutionState.completed).length;
    final failedBlocks = context.blockResults.where((r) => r.state == BlockExecutionState.failed).length;
    final totalBlocks = context.blockResults.length;
    final duration = context.totalExecutionTime;
    final isSuccessful = context.state == WorkflowExecutionState.completed;
    
    return AsmblCard(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isSuccessful ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: isSuccessful ? colors.success : colors.error,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  isSuccessful ? 'Completed' : 'Failed',
                  style: TextStyles.bodySmall.copyWith(
                    color: isSuccessful ? colors.success : colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xs),
            
            Text(
              'Blocks: $totalBlocks',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            
            Text(
              'Completed: $completedBlocks',
              style: TextStyles.caption.copyWith(color: colors.success),
            ),
            
            if (failedBlocks > 0)
              Text(
                'Failed: $failedBlocks',
                style: TextStyles.caption.copyWith(color: colors.error),
              ),
            
            if (duration != null)
              Text(
                'Duration: ${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}s',
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
  
  bool _hasDecisionTrail(LogicBlock block) {
    // Check if this block has arbitration or evaluation events
    return block.type == LogicBlockType.gateway || 
           block.type == LogicBlockType.reasoning;
  }
  
  Widget _buildDecisionTrail(LogicBlock block, ThemeColors colors) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(SpacingTokens.xs),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 12, color: colors.primary),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Decision Trail',
                style: TextStyles.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Path chosen: Option A (87%)',
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontSize: 10,
            ),
          ),
          Text(
            'Evidence: High confidence match',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAgencyInsightsToggle(ThemeColors colors, BuildContext context) {
    return AsmblButton.accent(
      text: 'Agency Insights',
      onPressed: () => _showAgencyPanel(colors, context),
      icon: Icons.psychology,
    );
  }
  
  void _showAgencyPanel(ThemeColors colors, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          height: 500,
          child: AgencyFeedbackPanel(
            selectedBlockId: currentBlockId,
            executionContext: executionContext,
            // executionEvents: executionEvents, // Temporarily commented
          ),
        ),
      ),
    );
  }
}

/// Real-time execution trace viewer
class ExecutionTraceViewer extends ConsumerStatefulWidget {
  final Stream<WorkflowExecutionContext>? executionUpdates;
  
  const ExecutionTraceViewer({
    super.key,
    this.executionUpdates,
  });

  @override
  ConsumerState<ExecutionTraceViewer> createState() => _ExecutionTraceViewerState();
}

class _ExecutionTraceViewerState extends ConsumerState<ExecutionTraceViewer> {
  final List<BlockExecutionResult> _executionHistory = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<WorkflowExecutionContext>? _subscription;
  
  @override
  void initState() {
    super.initState();
    if (widget.executionUpdates != null) {
      _subscription = widget.executionUpdates!.listen((context) {
        setState(() {
          // Update execution history with new block results
          for (final result in context.blockResults) {
            final existingIndex = _executionHistory.indexWhere((r) => r.blockId == result.blockId);
            if (existingIndex >= 0) {
              _executionHistory[existingIndex] = result;
            } else {
              _executionHistory.add(result);
            }
          }
          
          // Sort by timestamp
          _executionHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        
        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 16, color: colors.primary),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Execution Trace',
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _clearEvents,
                  icon: Icon(Icons.clear_all, size: 16, color: colors.onSurfaceVariant),
                  tooltip: 'Clear trace',
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            
            Expanded(
              child: _executionHistory.isEmpty
                  ? Center(
                      child: Text(
                        'No execution results yet',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _executionHistory.length,
                      itemBuilder: (context, index) {
                        final result = _executionHistory[index];
                        return _buildExecutionItem(result, colors);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionItem(BlockExecutionResult result, ThemeColors colors) {
    final timeStr = _formatTime(result.timestamp);
    
    Widget icon;
    Color iconColor;
    String title;
    String? subtitle;
    
    switch (result.state) {
      case BlockExecutionState.completed:
        icon = Icon(Icons.check_circle, size: 16);
        iconColor = colors.success;
        title = 'Block completed';
        subtitle = 'Executed in ${result.executionTime.inMilliseconds}ms';
        break;
      case BlockExecutionState.failed:
        icon = Icon(Icons.error, size: 16);
        iconColor = colors.error;
        title = 'Block failed';
        subtitle = result.error ?? 'Unknown error';
        break;
      case BlockExecutionState.skipped:
        icon = Icon(Icons.skip_next, size: 16);
        iconColor = colors.warning;
        title = 'Block skipped';
        subtitle = 'Skipped due to conditions';
        break;
      case BlockExecutionState.pending:
        icon = Icon(Icons.pending, size: 16);
        iconColor = colors.onSurfaceVariant;
        title = 'Block pending';
        subtitle = 'Waiting for execution';
        break;
      case BlockExecutionState.active:
        icon = Icon(Icons.play_circle, size: 16);
        iconColor = colors.primary;
        title = 'Block executing';
        subtitle = 'Currently running...';
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: icon,
          ),
          const SizedBox(width: SpacingTokens.xs),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _clearEvents() {
    setState(() {
      _executionHistory.clear();
    });
  }
}