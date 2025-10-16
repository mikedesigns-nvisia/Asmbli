import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../services/workflow_execution_service.dart';

// Temporary event types until proper implementation
enum EvaluationResult { pass, fail, warning }

class PathAlternative {
  final String path;
  final double score;
  
  PathAlternative({required this.path, required this.score});
}

class ArbitrationEvent {
  final String id;
  final String reasoning;
  final DateTime timestamp;
  final String decision;
  final String chosenPath;
  final double confidence;
  final List<PathAlternative> alternatives;
  final String evidence;
  
  ArbitrationEvent({
    required this.id,
    required this.reasoning,
    required this.timestamp,
    required this.decision,
    this.chosenPath = '',
    this.confidence = 0.0,
    this.alternatives = const [],
    this.evidence = '',
  });
}

class EvaluationEvent {
  final String id;
  final String criteria;
  final double score;
  final DateTime timestamp;
  final String feedback;
  final EvaluationResult result;
  final String details;
  
  EvaluationEvent({
    required this.id,
    required this.criteria,
    required this.score,
    required this.timestamp,
    required this.feedback,
    this.result = EvaluationResult.pass,
    this.details = '',
  });
}

class RecoveryEvent {
  final String id;
  final String strategy;
  final String error;
  final DateTime timestamp;
  final String status;
  final int step;
  final int attempt;
  final int maxAttempts;
  final String reason;
  
  RecoveryEvent({
    required this.id,
    required this.strategy,
    required this.error,
    required this.timestamp,
    required this.status,
    this.step = 1,
    this.attempt = 1,
    this.maxAttempts = 3,
    this.reason = '',
  });
}

/// Agency transparency panel that shows reasoning, evaluation, and recovery details
class AgencyFeedbackPanel extends ConsumerStatefulWidget {
  final String? selectedBlockId;
  final WorkflowExecutionContext? executionContext;
  // final Stream<ExecutionEvent>? executionEvents; // Temporarily commented
  
  const AgencyFeedbackPanel({
    super.key,
    this.selectedBlockId,
    this.executionContext,
    // this.executionEvents, // Temporarily commented
  });

  @override
  ConsumerState<AgencyFeedbackPanel> createState() => _AgencyFeedbackPanelState();
}

class _AgencyFeedbackPanelState extends ConsumerState<AgencyFeedbackPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ArbitrationEvent> _arbitrationHistory = [];
  final List<EvaluationEvent> _evaluationHistory = [];
  final List<RecoveryEvent> _recoveryHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // if (widget.executionEvents != null) {
    //   _subscription = widget.executionEvents!.listen(_handleExecutionEvent);
    // } // Temporarily commented
  }

  @override
  void dispose() {
    _tabController.dispose();
    // _subscription?.cancel(); // Temporarily commented
    super.dispose();
  }

  // void _handleExecutionEvent(ExecutionEvent event) {
  //   setState(() {
  //     if (event is ArbitrationEvent) {
  //       _arbitrationHistory.add(event);
  //     } else if (event is EvaluationEvent) {
  //       _evaluationHistory.add(event);
  //     } else if (event is RecoveryEvent) {
  //       _recoveryHistory.add(event);
  //     }
  //   });
  // } // Temporarily commented

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, size: 20, color: colors.primary),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Agency Insights',
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                _buildConfidenceIndicator(colors),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_tree, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      const Text('Arbitration'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      const Text('Evaluation'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.healing, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      const Text('Recovery'),
                    ],
                  ),
                ),
              ],
              indicatorColor: colors.primary,
              labelColor: colors.onSurface,
              unselectedLabelColor: colors.onSurfaceVariant,
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildArbitrationTab(colors),
                  _buildEvaluationTab(colors),
                  _buildRecoveryTab(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(ThemeColors colors) {
    final overallConfidence = _calculateOverallConfidence();
    final confidenceColor = _getConfidenceColor(overallConfidence, colors);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 14, color: confidenceColor),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            '${(overallConfidence * 100).toStringAsFixed(0)}% confidence',
            style: TextStyles.caption.copyWith(
              color: confidenceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArbitrationTab(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Decision paths and reasoning evidence',
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Expanded(
          child: _arbitrationHistory.isEmpty
              ? _buildEmptyState('No arbitration decisions yet', colors)
              : ListView.builder(
                  itemCount: _arbitrationHistory.length,
                  itemBuilder: (context, index) {
                    final event = _arbitrationHistory[index];
                    return _buildArbitrationItem(event, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEvaluationTab(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Quality gates and validation results',
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Expanded(
          child: _evaluationHistory.isEmpty
              ? _buildEmptyState('No evaluations performed yet', colors)
              : ListView.builder(
                  itemCount: _evaluationHistory.length,
                  itemBuilder: (context, index) {
                    final event = _evaluationHistory[index];
                    return _buildEvaluationItem(event, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecoveryTab(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Recovery attempts and fallback strategies',
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Expanded(
          child: _recoveryHistory.isEmpty
              ? _buildEmptyState('No recovery actions needed', colors)
              : ListView.builder(
                  itemCount: _recoveryHistory.length,
                  itemBuilder: (context, index) {
                    final event = _recoveryHistory[index];
                    return _buildRecoveryItem(event, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArbitrationItem(ArbitrationEvent event, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, size: 16, color: colors.primary),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  'Path Selection: ${event.chosenPath}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(event.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyles.caption.copyWith(
                  color: _getConfidenceColor(event.confidence, colors),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          
          if (event.alternatives.isNotEmpty) ...[
            Text(
              'Alternatives considered:',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.xs),
            ...event.alternatives.map((alt) => Container(
              margin: const EdgeInsets.only(left: SpacingTokens.md, bottom: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 4, color: colors.onSurfaceVariant),
                  const SizedBox(width: SpacingTokens.xs),
                  Expanded(
                    child: Text(
                      '${alt.path} (${(alt.score * 100).toStringAsFixed(0)}%)',
                      style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          if (event.evidence.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Evidence: ${event.evidence}',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvaluationItem(EvaluationEvent event, ThemeColors colors) {
    final isPass = event.result == EvaluationResult.pass;
    final resultColor = isPass ? colors.success : colors.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: resultColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPass ? Icons.check_circle : Icons.error,
                size: 16,
                color: resultColor,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  event.criteria,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isPass ? 'PASS' : 'FAIL',
                style: TextStyles.caption.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          if (event.details.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(
              event.details,
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          
          if (event.score != null) ...[
            const SizedBox(height: SpacingTokens.xs),
            Row(
              children: [
                Text(
                  'Score: ',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  '${(event.score! * 100).toStringAsFixed(1)}%',
                  style: TextStyles.caption.copyWith(
                    color: _getConfidenceColor(event.score!, colors),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoveryItem(RecoveryEvent event, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 16, color: colors.warning),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  'Recovery: ${event.strategy}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  'Step ${event.step}',
                  style: TextStyles.caption.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          if (event.attempt > 1) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Attempt ${event.attempt} of ${event.maxAttempts}',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          
          if (event.reason.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Reason: ${event.reason}',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateOverallConfidence() {
    if (_arbitrationHistory.isEmpty && _evaluationHistory.isEmpty) {
      return 1.0;
    }
    
    double totalScore = 0.0;
    int count = 0;
    
    for (final event in _arbitrationHistory) {
      totalScore += event.confidence;
      count++;
    }
    
    for (final event in _evaluationHistory) {
      if (event.score != null) {
        totalScore += event.score!;
        count++;
      }
    }
    
    return count > 0 ? totalScore / count : 1.0;
  }

  Color _getConfidenceColor(double confidence, ThemeColors colors) {
    if (confidence >= 0.8) return colors.success;
    if (confidence >= 0.6) return colors.warning;
    return colors.error;
  }
}

// Supporting event classes
// Temporarily commented out ExecutionEvent classes due to import conflicts
// class ArbitrationEvent extends ExecutionEvent {
//   final String chosenPath;
//   final double confidence;
//   final List<PathAlternative> alternatives;
//   final String evidence;
//   
//   ArbitrationEvent({
//     required String executionId,
//     required String blockId,
//     required this.chosenPath,
//     required this.confidence,
//     required this.alternatives,
//     required this.evidence,
//   }) : super(executionId, DateTime.now());
// }

// class EvaluationEvent extends ExecutionEvent {
//   final String criteria;
//   final EvaluationResult result;
//   final String details;
//   final double? score;
//   
//   EvaluationEvent({
//     required String executionId,
//     required String blockId,
//     required this.criteria,
//     required this.result,
//     required this.details,
//     this.score,
//   }) : super(executionId, DateTime.now());
// }

// class RecoveryEvent extends ExecutionEvent {
//   final String strategy;
//   final int step;
//   final int attempt;
//   final int maxAttempts;
//   final String reason;
//   
//   RecoveryEvent({
//     required String executionId,
//     required String blockId,
//     required this.strategy,
//     required this.step,
//     required this.attempt,
//     required this.maxAttempts,
//     required this.reason,
//   }) : super(executionId, DateTime.now());
// }

// Extensions to existing execution event types
enum ExecutionEventType {
  started,
  blockStarted,
  blockCompleted,
  blockError,
  completed,
  failed,
  arbitration,
  evaluation,
  recovery,
}