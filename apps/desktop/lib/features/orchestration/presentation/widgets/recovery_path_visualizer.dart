import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';

/// Visualizes recovery paths and fallback strategies for failed blocks
class RecoveryPathVisualizer extends ConsumerWidget {
  final String blockId;
  final List<RecoveryStep> recoveryPath;
  final RecoveryExecutionState? executionState;
  
  const RecoveryPathVisualizer({
    super.key,
    required this.blockId,
    required this.recoveryPath,
    this.executionState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: SpacingTokens.md),
            
            if (recoveryPath.isEmpty)
              _buildEmptyState(colors)
            else
              _buildRecoverySteps(colors),
            
            const SizedBox(height: SpacingTokens.md),
            _buildRecoveryMetrics(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(Icons.healing, color: colors.warning, size: 20),
        const SizedBox(width: SpacingTokens.sm),
        Text(
          'Recovery Path',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const Spacer(),
        _buildRecoveryStatus(colors),
      ],
    );
  }

  Widget _buildRecoveryStatus(ThemeColors colors) {
    if (executionState == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        ),
        child: Text(
          'Standby',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (executionState!.status) {
      case RecoveryStatus.executing:
        statusColor = colors.primary;
        statusText = 'Recovering';
        statusIcon = Icons.autorenew;
        break;
      case RecoveryStatus.successful:
        statusColor = colors.success;
        statusText = 'Recovered';
        statusIcon = Icons.check_circle;
        break;
      case RecoveryStatus.failed:
        statusColor = colors.error;
        statusText = 'Failed';
        statusIcon = Icons.error;
        break;
      case RecoveryStatus.escalated:
        statusColor = colors.warning;
        statusText = 'Escalated';
        statusIcon = Icons.escalator_warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            statusText,
            style: TextStyles.caption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.shield,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'No recovery needed',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            'Block is executing normally',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverySteps(ThemeColors colors) {
    return Column(
      children: [
        for (int i = 0; i < recoveryPath.length; i++)
          _buildRecoveryStep(recoveryPath[i], i, colors),
      ],
    );
  }

  Widget _buildRecoveryStep(RecoveryStep step, int index, ThemeColors colors) {
    final isCurrentStep = executionState?.currentStep == index;
    final isCompleted = (executionState?.currentStep ?? -1) > index;
    final isFailed = step.status == RecoveryStepStatus.failed;

    Color stepColor;
    IconData stepIcon;

    if (isFailed) {
      stepColor = colors.error;
      stepIcon = Icons.error;
    } else if (isCompleted) {
      stepColor = colors.success;
      stepIcon = Icons.check_circle;
    } else if (isCurrentStep) {
      stepColor = colors.primary;
      stepIcon = Icons.play_circle;
    } else {
      stepColor = colors.onSurfaceVariant;
      stepIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.1),
                  border: Border.all(color: stepColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: isCurrentStep && step.status == RecoveryStepStatus.executing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(stepColor),
                          ),
                        )
                      : Icon(stepIcon, size: 16, color: stepColor),
                ),
              ),
              
              // Connector line (except for last step)
              if (index < recoveryPath.length - 1)
                Container(
                  width: 2,
                  height: 20,
                  color: colors.border,
                  margin: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
                ),
            ],
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${index + 1}. ${step.name}',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (step.attempts > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          'Attempt ${step.attempts}',
                          style: TextStyles.caption.copyWith(
                            color: colors.warning,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    step.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                
                if (step.strategy != RecoveryStrategy.none) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  _buildStrategyTag(step.strategy, colors),
                ],
                
                if (step.error != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.xs),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Error: ${step.error}',
                      style: TextStyles.caption.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
                
                if (step.executionTime != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Completed in ${step.executionTime!.inMilliseconds}ms',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTag(RecoveryStrategy strategy, ThemeColors colors) {
    String label;
    Color tagColor;

    switch (strategy) {
      case RecoveryStrategy.retry:
        label = 'Retry';
        tagColor = colors.primary;
        break;
      case RecoveryStrategy.fallback:
        label = 'Fallback';
        tagColor = colors.warning;
        break;
      case RecoveryStrategy.degrade:
        label = 'Degrade';
        tagColor = colors.warning;
        break;
      case RecoveryStrategy.escalate:
        label = 'Escalate';
        tagColor = colors.error;
        break;
      case RecoveryStrategy.compensate:
        label = 'Compensate';
        tagColor = colors.accent;
        break;
      case RecoveryStrategy.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyles.caption.copyWith(
          color: tagColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecoveryMetrics(ThemeColors colors) {
    if (executionState == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Metrics',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Total Attempts',
                  executionState!.totalAttempts.toString(),
                  colors,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Success Rate',
                  '${(executionState!.successRate * 100).toStringAsFixed(0)}%',
                  colors,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Recovery Time',
                  '${executionState!.totalRecoveryTime.inSeconds}s',
                  colors,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Current Step',
                  '${executionState!.currentStep + 1}/${recoveryPath.length}',
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Supporting data classes
class RecoveryStep {
  final String name;
  final String description;
  final RecoveryStrategy strategy;
  final RecoveryStepStatus status;
  final int attempts;
  final String? error;
  final Duration? executionTime;

  RecoveryStep({
    required this.name,
    required this.description,
    required this.strategy,
    this.status = RecoveryStepStatus.pending,
    this.attempts = 1,
    this.error,
    this.executionTime,
  });
}

class RecoveryExecutionState {
  final RecoveryStatus status;
  final int currentStep;
  final int totalAttempts;
  final double successRate;
  final Duration totalRecoveryTime;

  RecoveryExecutionState({
    required this.status,
    required this.currentStep,
    required this.totalAttempts,
    required this.successRate,
    required this.totalRecoveryTime,
  });
}

enum RecoveryStrategy {
  none,
  retry,
  fallback,
  degrade,
  escalate,
  compensate,
}

enum RecoveryStatus {
  executing,
  successful,
  failed,
  escalated,
}

enum RecoveryStepStatus {
  pending,
  executing,
  completed,
  failed,
}