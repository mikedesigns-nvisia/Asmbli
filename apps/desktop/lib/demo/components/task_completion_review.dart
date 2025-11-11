import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/design_system/design_system.dart';

/// Task completion review screen with confidence-based approval
class TaskCompletionReview extends StatefulWidget {
  final String agentName;
  final IconData agentIcon; 
  final Color agentColor;
  final List<CompletedTask> tasks;
  final VoidCallback? onApproveAll;
  final VoidCallback? onRejectAll;
  final Function(String taskId)? onApproveTask;
  final Function(String taskId)? onRejectTask;
  final VoidCallback? onRestart;

  const TaskCompletionReview({
    super.key,
    required this.agentName,
    required this.agentIcon,
    required this.agentColor,
    required this.tasks,
    this.onApproveAll,
    this.onRejectAll,
    this.onApproveTask,
    this.onRejectTask,
    this.onRestart,
  });

  @override
  State<TaskCompletionReview> createState() => _TaskCompletionReviewState();
}

class _TaskCompletionReviewState extends State<TaskCompletionReview>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final Map<String, bool> _taskApprovals = {};
  bool _showSuccessAnimation = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    
    // Initialize all tasks as approved by default if confidence > 0.8
    for (final task in widget.tasks) {
      _taskApprovals[task.id] = task.confidence > 0.8;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double get _overallConfidence {
    if (widget.tasks.isEmpty) return 0.0;
    final sum = widget.tasks.fold<double>(
      0.0,
      (prev, task) => prev + task.confidence,
    );
    return sum / widget.tasks.length;
  }

  int get _approvedTaskCount {
    return _taskApprovals.values.where((approved) => approved).length;
  }

  void _handleApproveAll() {
    setState(() {
      _showSuccessAnimation = true;
      for (final task in widget.tasks) {
        _taskApprovals[task.id] = true;
      }
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onApproveAll?.call();
    });
  }

  void _handleRejectAll() {
    setState(() {
      for (final task in widget.tasks) {
        _taskApprovals[task.id] = false;
      }
    });
    widget.onRejectAll?.call();
  }

  void _toggleTaskApproval(String taskId) {
    setState(() {
      _taskApprovals[taskId] = !(_taskApprovals[taskId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(colors),
              
              // Task list
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xxl,
                    ),
                    child: Column(
                      children: [
                        // Overall summary card
                        _buildSummaryCard(colors),
                        
                        const SizedBox(height: SpacingTokens.xl),
                        
                        // Tasks
                        ...widget.tasks.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                          child: _buildTaskCard(task, colors),
                        )),
                        
                        const SizedBox(height: SpacingTokens.xxl),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Actions footer
              _buildActionsFooter(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: widget.agentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Icon(
              widget.agentIcon,
              color: widget.agentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Review',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 24,
                  ),
                ),
                Text(
                  '${widget.agentName} completed ${widget.tasks.length} tasks',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRestart != null)
            IconButton(
              onPressed: widget.onRestart,
              icon: Icon(Icons.refresh, color: colors.onSurfaceVariant),
              tooltip: 'Start new demo',
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeColors colors) {
    final confidenceColor = _overallConfidence > 0.9
        ? colors.success
        : _overallConfidence > 0.7
            ? colors.warning
            : colors.error;
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.agentColor.withOpacity(0.05),
            widget.agentColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(color: widget.agentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Overall Confidence',
                '${(_overallConfidence * 100).toStringAsFixed(0)}%',
                confidenceColor,
                colors,
              ),
              Container(
                width: 1,
                height: 40,
                color: colors.border.withOpacity(0.5),
              ),
              _buildStatItem(
                'Tasks Approved',
                '$_approvedTaskCount/${widget.tasks.length}',
                colors.primary,
                colors,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Confidence indicator bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _overallConfidence,
              child: Container(
                decoration: BoxDecoration(
                  color: confidenceColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            _overallConfidence > 0.9
                ? 'High confidence - All systems performed optimally'
                : _overallConfidence > 0.7
                    ? 'Moderate confidence - Human review recommended'
                    : 'Low confidence - Careful review required',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color valueColor,
    ThemeColors colors,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.sectionTitle.copyWith(
            color: valueColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(CompletedTask task, ThemeColors colors) {
    final isApproved = _taskApprovals[task.id] ?? false;
    final confidenceColor = task.confidence > 0.9
        ? colors.success
        : task.confidence > 0.7
            ? colors.warning
            : colors.error;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: isApproved
              ? colors.success.withOpacity(0.5)
              : colors.border,
          width: isApproved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Task header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: task.confidence < 0.7
                  ? colors.error.withOpacity(0.05)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.lg),
                topRight: Radius.circular(BorderRadiusTokens.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  task.icon,
                  color: widget.agentColor,
                  size: 24,
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.subtitle != null) ...[
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          task.subtitle!,
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Confidence chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Text(
                    '${(task.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyles.bodySmall.copyWith(
                      color: confidenceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Task details
          if (task.details.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.lg,
                vertical: SpacingTokens.md,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: colors.border.withOpacity(0.5)),
                  bottom: BorderSide(color: colors.border.withOpacity(0.5)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: task.details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Expanded(
                        child: Text(
                          detail,
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          
          // Approval actions
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                if (task.confidence < 0.7)
                  Icon(
                    Icons.warning_amber_outlined,
                    color: colors.warning,
                    size: 20,
                  ),
                if (task.confidence < 0.7)
                  const SizedBox(width: SpacingTokens.sm),
                if (task.confidence < 0.7)
                  Expanded(
                    child: Text(
                      'Review recommended',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
                if (task.confidence >= 0.7)
                  const Spacer(),
                
                // Approval toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isApproved ? 'Approved' : 'Rejected',
                      style: TextStyles.bodySmall.copyWith(
                        color: isApproved ? colors.success : colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Switch(
                      value: isApproved,
                      onChanged: (_) => _toggleTaskApproval(task.id),
                      activeColor: colors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsFooter(ThemeColors colors) {
    final allApproved = _taskApprovals.values.every((approved) => approved);
    final someApproved = _taskApprovals.values.any((approved) => approved);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          // Confidence-based recommendation
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: _overallConfidence > 0.8
                    ? colors.success.withOpacity(0.1)
                    : colors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Row(
                children: [
                  Icon(
                    _overallConfidence > 0.8
                        ? Icons.recommend
                        : Icons.preview,
                    color: _overallConfidence > 0.8
                        ? colors.success
                        : colors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      _overallConfidence > 0.8
                          ? 'AI recommends approval'
                          : 'Manual review suggested',
                      style: TextStyles.bodyMedium.copyWith(
                        color: _overallConfidence > 0.8
                            ? colors.success
                            : colors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          // Action buttons
          if (!allApproved && widget.onRejectAll != null)
            AsmblButton.destructive(
              text: 'Reject All',
              onPressed: _handleRejectAll,
              size: AsmblButtonSize.medium,
            ),
          
          if (!allApproved && someApproved)
            const SizedBox(width: SpacingTokens.sm),
          
          if (widget.onApproveAll != null)
            AsmblButton.primary(
              text: allApproved ? 'Deploy All' : 'Approve All',
              icon: allApproved ? Icons.rocket_launch : Icons.check_circle,
              onPressed: _handleApproveAll,
              size: AsmblButtonSize.medium,
            ),
        ],
      ),
    );
  }
}

class CompletedTask {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final double confidence;
  final List<String> details;

  const CompletedTask({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.confidence,
    this.details = const [],
  });
}