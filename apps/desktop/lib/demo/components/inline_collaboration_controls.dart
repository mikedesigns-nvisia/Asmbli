import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import 'persistent_ai_panel.dart';

/// Inline collaboration controls that appear as part of chat messages
class InlineCollaborationControls extends StatefulWidget {
  final String scenario;
  final Function(String agentName)? onAgentSelected;
  final Function(Map<String, dynamic>)? onSettingsChanged;

  const InlineCollaborationControls({
    super.key,
    required this.scenario,
    this.onAgentSelected,
    this.onSettingsChanged,
  });

  @override
  State<InlineCollaborationControls> createState() => _InlineCollaborationControlsState();
}

class _InlineCollaborationControlsState extends State<InlineCollaborationControls>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getScenarioAgents() {
    switch (widget.scenario) {
      case 'loan_analysis':
        return [
          {
            'name': 'Loan Officer',
            'status': 'active',
            'confidence': 0.96,
            'icon': Icons.account_balance,
            'task': 'Analyzing application'
          },
          {
            'name': 'Risk Specialist',
            'status': 'queued',
            'confidence': 0.94,
            'icon': Icons.assessment,
            'task': 'Risk assessment'
          },
          {
            'name': 'Compliance',
            'status': 'standby',
            'confidence': 0.91,
            'icon': Icons.verified_user,
            'task': 'Regulatory check'
          },
        ];
      case 'infrastructure_monitoring':
        return [
          {
            'name': 'Monitor',
            'status': 'active',
            'confidence': 0.97,
            'icon': Icons.monitor_heart,
            'task': 'Analyzing alerts'
          },
          {
            'name': 'Incident Response',
            'status': 'active',
            'confidence': 0.94,
            'icon': Icons.emergency,
            'task': 'Investigating issue'
          },
          {
            'name': 'Performance',
            'status': 'queued',
            'confidence': 0.92,
            'icon': Icons.analytics,
            'task': 'Performance analysis'
          },
        ];
      default:
        return [
          {
            'name': 'Assistant',
            'status': 'active',
            'confidence': 0.90,
            'icon': Icons.smart_toy,
            'task': 'Processing request'
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final agents = _getScenarioAgents();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(SpacingTokens.xs),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: 0.1 + (_pulseController.value * 0.1)
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: colors.primary,
                      size: 16,
                    ),
                  );
                },
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'AI Collaboration Active',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.success),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyles.caption.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Active agents
          ...agents.map((agent) => _buildAgentCard(agent, colors)).toList(),
          
          const SizedBox(height: SpacingTokens.sm),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAgentSelector(context, colors),
                  icon: Icon(Icons.add, size: 16, color: colors.primary),
                  label: Text(
                    'Add Agent',
                    style: TextStyles.bodySmall.copyWith(color: colors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSettings(context, colors),
                  icon: Icon(Icons.tune, size: 16, color: colors.onSurfaceVariant),
                  label: Text(
                    'Settings',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent, ThemeColors colors) {
    final status = agent['status'] as String;
    final isActive = status == 'active';
    final confidence = agent['confidence'] as double;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isActive 
          ? colors.primary.withValues(alpha: 0.05)
          : colors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: isActive 
          ? Border.all(color: colors.primary.withValues(alpha: 0.3))
          : null,
      ),
      child: Row(
        children: [
          // Agent icon with status
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: _getStatusColor(status, colors).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  agent['icon'] as IconData,
                  color: _getStatusColor(status, colors),
                  size: 16,
                ),
              ),
              if (isActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.success.withValues(
                          alpha: 0.7 + (_pulseController.value * 0.3)
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
            ],
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Agent info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent['name'],
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  agent['task'],
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Confidence and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status.toUpperCase(),
                style: TextStyles.caption.copyWith(
                  color: _getStatusColor(status, colors),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 10,
                    color: _getConfidenceColor(confidence, colors),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${(confidence * 100).toInt()}%',
                    style: TextStyles.caption.copyWith(
                      color: _getConfidenceColor(confidence, colors),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeColors colors) {
    switch (status) {
      case 'active':
        return colors.success;
      case 'queued':
        return colors.warning;
      case 'standby':
        return colors.primary;
      default:
        return colors.onSurfaceVariant;
    }
  }

  Color _getConfidenceColor(double confidence, ThemeColors colors) {
    if (confidence >= 0.9) return colors.success;
    if (confidence >= 0.8) return colors.warning;
    return colors.error;
  }

  void _showAgentSelector(BuildContext context, ThemeColors colors) {
    // Show a bottom sheet with available agents
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Additional Agent',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            // List of available agents...
            AsmblButton.primary(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, ThemeColors colors) {
    // Show collaboration settings
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collaboration Settings',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            // Settings options...
            AsmblButton.primary(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Agent collaboration message that appears in chat
class AgentCollaborationMessage extends StatefulWidget {
  final String type; // 'thinking', 'handoff', 'consensus', 'intervention'
  final Map<String, dynamic> data;
  final VoidCallback? onInterventionTrigger;

  const AgentCollaborationMessage({
    super.key,
    required this.type,
    required this.data,
    this.onInterventionTrigger,
  });

  @override
  State<AgentCollaborationMessage> createState() => _AgentCollaborationMessageState();
}

class _AgentCollaborationMessageState extends State<AgentCollaborationMessage> {
  bool _modalShown = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    switch (widget.type) {
      case 'thinking':
        return _buildThinkingMessage(colors);
      case 'handoff':
        return _buildHandoffMessage(colors);
      case 'consensus':
        return _buildConsensusMessage(colors);
      case 'intervention':
        return _buildInterventionMessage(context, colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildThinkingMessage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: colors.primary, size: 20),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.data['agent']} is analyzing...',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.data['task'] ?? 'Processing your request',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoffMessage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: colors.accent, size: 20),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              '${widget.data['from']} → ${widget.data['to']}: ${widget.data['reason']}',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsensusMessage(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.success, size: 20),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent Consensus Reached',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Confidence: ${widget.data['confidence']}% across ${widget.data['agents']} agents',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPersistentAIPanel(BuildContext context) {
    print('🎉 Showing persistent AI panel from intervention!');
    final colors = ThemeColors(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => PersistentAIPanel(
          scenario: widget.data['scenario'] ?? 'general',
          isVisible: true,
          onClose: () => Navigator.pop(context),
          onMessageSent: (message) {
            print('Message sent from persistent panel: $message');
          },
        ),
      ),
    );
  }

  Widget _buildInterventionMessage(BuildContext context, ThemeColors colors) {
    // Trigger the modal immediately when this message is built, but only once
    if (!_modalShown) {
      _modalShown = true;
      print('🔔 Showing intervention modal dialog');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
        context: context,
        barrierDismissible: false, // Require user action
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(SpacingTokens.xl),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: colors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Human Input Needed',
                            style: TextStyles.cardTitle.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AI collaboration paused',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Question/Issue
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent Question:',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        widget.data['question'] ?? 'The AI agents need guidance to proceed with the analysis. How would you like them to continue?',
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Input field for user response
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your response or guidance...',
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  style: TextStyle(color: colors.onSurface),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: AsmblButton.secondary(
                        text: 'Continue Auto',
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Continue without intervention
                          widget.onInterventionTrigger?.call();
                          
                          // Show persistent AI panel directly
                          _showPersistentAIPanel(context);
                        },
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      flex: 2,
                      child: AsmblButton.primary(
                        text: 'Send Response',
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Handle user input
                          widget.onInterventionTrigger?.call();
                          
                          // Show persistent AI panel directly
                          _showPersistentAIPanel(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
    }

    // Return a subtle inline indicator that intervention is needed
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.pause_circle_filled, color: colors.warning, size: 20),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              'AI agents paused - awaiting human input...',
              style: TextStyles.bodySmall.copyWith(
                color: colors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Icon(Icons.more_horiz, color: colors.warning, size: 16),
        ],
      ),
    );
  }

}