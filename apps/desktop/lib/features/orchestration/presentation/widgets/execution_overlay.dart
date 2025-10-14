import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../services/workflow_execution_engine.dart';

/// Overlay widget that shows real-time execution status on the canvas
class ExecutionOverlay extends ConsumerWidget {
  final List<LogicBlock> blocks;
  final WorkflowExecutionResult? executionResult;
  final bool isExecuting;
  final String? currentBlockId;
  
  const ExecutionOverlay({
    super.key,
    required this.blocks,
    this.executionResult,
    this.isExecuting = false,
    this.currentBlockId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    if (!isExecuting && executionResult == null) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Block execution indicators
        ...blocks.map((block) => Positioned(
          left: block.position.x + block.defaultWidth + 8,
          top: block.position.y,
          child: _buildBlockExecutionIndicator(block, colors),
        )),
        
        // Progress indicator
        if (isExecuting)
          Positioned(
            top: 20,
            right: 20,
            child: _buildProgressIndicator(colors),
          ),
        
        // Execution summary
        if (executionResult != null && !isExecuting)
          Positioned(
            top: 20,
            right: 20,
            child: _buildExecutionSummary(executionResult!, colors),
          ),
      ],
    );
  }

  Widget _buildBlockExecutionIndicator(LogicBlock block, ThemeColors colors) {
    final blockResult = executionResult?.state.completedBlocks[block.id];
    final isCurrentBlock = currentBlockId == block.id;
    final hasError = executionResult?.state.errors.any((e) => e.blockId == block.id) ?? false;
    
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
      tooltip = 'Error occurred';
    } else if (blockResult != null) {
      // Block completed
      final confidence = blockResult.confidence;
      if (confidence > 0.8) {
        indicator = Icon(Icons.check_circle, size: 16, color: colors.success);
        indicatorColor = colors.success;
        tooltip = 'Completed successfully (${(confidence * 100).round()}% confidence)';
      } else if (confidence > 0.5) {
        indicator = Icon(Icons.warning, size: 16, color: colors.warning);
        indicatorColor = colors.warning;
        tooltip = 'Completed with warnings (${(confidence * 100).round()}% confidence)';
      } else {
        indicator = Icon(Icons.error_outline, size: 16, color: colors.error);
        indicatorColor = colors.error;
        tooltip = 'Low confidence result (${(confidence * 100).round()}%)';
      }
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
          border: Border.all(color: indicatorColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withOpacity(0.2),
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

  Widget _buildExecutionSummary(WorkflowExecutionResult result, ThemeColors colors) {
    final successRate = result.successRate;
    final duration = result.duration;
    final blocksExecuted = result.state.completedBlocks.length;
    final errors = result.state.errors.length;
    
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
                  result.isSuccessful ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: result.isSuccessful ? colors.success : colors.error,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  result.isSuccessful ? 'Completed' : 'Failed',
                  style: TextStyles.bodySmall.copyWith(
                    color: result.isSuccessful ? colors.success : colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xs),
            
            Text(
              'Blocks: $blocksExecuted',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            
            if (errors > 0)
              Text(
                'Errors: $errors',
                style: TextStyles.caption.copyWith(color: colors.error),
              ),
            
            Text(
              'Success: ${(successRate * 100).round()}%',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            
            Text(
              'Duration: ${duration.inSeconds}s',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real-time execution trace viewer
class ExecutionTraceViewer extends ConsumerStatefulWidget {
  final Stream<ExecutionEvent> executionEvents;
  
  const ExecutionTraceViewer({
    super.key,
    required this.executionEvents,
  });

  @override
  ConsumerState<ExecutionTraceViewer> createState() => _ExecutionTraceViewerState();
}

class _ExecutionTraceViewerState extends ConsumerState<ExecutionTraceViewer> {
  final List<ExecutionEvent> _events = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ExecutionEvent>? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = widget.executionEvents.listen((event) {
      setState(() {
        _events.add(event);
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
              child: _events.isEmpty
                  ? Center(
                      child: Text(
                        'No execution events yet',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return _buildEventItem(event, colors);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(ExecutionEvent event, ThemeColors colors) {
    final timeStr = _formatTime(event.timestamp);
    
    Widget icon;
    Color iconColor;
    String title;
    String? subtitle;
    
    if (event is _ExecutionStarted) {
      icon = Icon(Icons.play_arrow, size: 16);
      iconColor = colors.primary;
      title = 'Execution started';
      subtitle = 'Workflow: ${event.workflowId}';
    } else if (event is _ExecutionCompleted) {
      icon = Icon(Icons.check_circle, size: 16);
      iconColor = event.successful ? colors.success : colors.error;
      title = event.successful ? 'Execution completed' : 'Execution failed';
    } else if (event is _ExecutionFailed) {
      icon = Icon(Icons.error, size: 16);
      iconColor = colors.error;
      title = 'Execution failed';
      subtitle = event.error;
    } else if (event is _BlockStarted) {
      icon = Icon(Icons.play_circle_outline, size: 16);
      iconColor = colors.accent;
      title = 'Block started: ${event.type.name}';
      subtitle = 'ID: ${event.blockId}';
    } else if (event is _BlockCompleted) {
      icon = Icon(Icons.check_circle_outline, size: 16);
      iconColor = event.successful ? colors.success : colors.warning;
      title = 'Block completed';
      subtitle = '${(event.confidence * 100).round()}% confidence';
    } else if (event is _BlockError) {
      icon = Icon(Icons.error_outline, size: 16);
      iconColor = colors.error;
      title = 'Block error';
      subtitle = event.error;
    } else if (event is _EarlyTermination) {
      icon = Icon(Icons.stop_circle, size: 16);
      iconColor = colors.warning;
      title = 'Early termination';
      subtitle = event.reason;
    } else {
      icon = Icon(Icons.info_outline, size: 16);
      iconColor = colors.onSurfaceVariant;
      title = 'Unknown event';
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
            child: Icon(
              icon.icon,
              size: 16,
              color: iconColor,
            ),
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
      _events.clear();
    });
  }
}