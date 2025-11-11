import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

/// Persistent AI collaboration panel that appears after intervention
class PersistentAIPanel extends StatefulWidget {
  final String scenario;
  final Function(String message)? onMessageSent;
  final Function()? onClose;
  final bool isVisible;

  const PersistentAIPanel({
    super.key,
    required this.scenario,
    this.onMessageSent,
    this.onClose,
    this.isVisible = false,
  });

  @override
  State<PersistentAIPanel> createState() => _PersistentAIPanelState();
}

class _PersistentAIPanelState extends State<PersistentAIPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _panelMessages = [];
  bool _isAgentTyping = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.isVisible) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(PersistentAIPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
        _addWelcomeMessage();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _panelMessages.add({
            'content': 'I\'m ready to continue our collaboration! What would you like to explore next?',
            'isUser': false,
            'timestamp': DateTime.now(),
            'agent': 'AI Coordinator',
          });
        });
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _panelMessages.add({
        'content': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
      _isAgentTyping = true;
    });

    // Notify parent
    widget.onMessageSent?.call(message);

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAgentTyping = false;
          _panelMessages.add({
            'content': _generateAIResponse(message),
            'isUser': false,
            'timestamp': DateTime.now(),
            'agent': 'AI Coordinator',
          });
        });
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    // Simple response generation based on scenario
    switch (widget.scenario) {
      case 'infrastructure_monitoring':
        return 'I\'ll monitor the infrastructure changes and keep you updated on system performance. Would you like me to set up automated alerts?';
      case 'loan_analysis':
        return 'I\'ll continue analyzing the loan application. Should I focus on any specific risk factors?';
      case 'document_review':
        return 'I\'ll review the document changes. Would you like me to check for any specific compliance issues?';
      default:
        return 'I understand. I\'ll continue with the analysis and keep you informed of any significant findings.';
    }
  }

  List<Map<String, dynamic>> _getActiveAgents() {
    switch (widget.scenario) {
      case 'infrastructure_monitoring':
        return [
          {
            'name': 'Monitor',
            'status': 'active',
            'confidence': 0.97,
            'icon': Icons.monitor_heart,
            'task': 'Real-time monitoring'
          },
          {
            'name': 'Incident Response',
            'status': 'active',
            'confidence': 0.94,
            'icon': Icons.emergency,
            'task': 'Issue resolution'
          },
        ];
      case 'loan_analysis':
        return [
          {
            'name': 'Loan Officer',
            'status': 'active',
            'confidence': 0.96,
            'icon': Icons.account_balance,
            'task': 'Application review'
          },
          {
            'name': 'Risk Specialist',
            'status': 'active',
            'confidence': 0.94,
            'icon': Icons.assessment,
            'task': 'Risk assessment'
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
    
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideController.value) * 400),
          child: Opacity(
            opacity: _slideController.value,
            child: Container(
              height: 400,
              margin: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.onSurface.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(BorderRadiusTokens.lg),
                        topRight: Radius.circular(BorderRadiusTokens.lg),
                      ),
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(SpacingTokens.sm),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(
                                  alpha: 0.1 + (_pulseController.value * 0.1)
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: colors.primary,
                                size: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Collaboration Active',
                                style: TextStyles.cardTitle.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Continue your conversation with AI agents',
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        const SizedBox(width: SpacingTokens.sm),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                          tooltip: 'Close AI Panel',
                        ),
                      ],
                    ),
                  ),

                  // Content area with tabs
                  Expanded(
                    child: Row(
                      children: [
                        // Left: Active Agents
                        Container(
                          width: 200,
                          padding: const EdgeInsets.all(SpacingTokens.md),
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: colors.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Agents',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.md),
                              ..._getActiveAgents().map((agent) => _buildAgentCard(agent, colors)),
                            ],
                          ),
                        ),

                        // Right: Chat area
                        Expanded(
                          child: Column(
                            children: [
                              // Messages
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(SpacingTokens.md),
                                  itemCount: _panelMessages.length + (_isAgentTyping ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _panelMessages.length && _isAgentTyping) {
                                      return _buildTypingIndicator(colors);
                                    }
                                    return _buildMessage(_panelMessages[index], colors);
                                  },
                                ),
                              ),

                              // Input area
                              Container(
                                padding: const EdgeInsets.all(SpacingTokens.md),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: colors.border)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Continue the conversation...',
                                          hintStyle: TextStyle(color: colors.onSurfaceVariant),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                                            borderSide: BorderSide(color: colors.border),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                                            borderSide: BorderSide(color: colors.border),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                                            borderSide: BorderSide(color: colors.primary),
                                          ),
                                          filled: true,
                                          fillColor: colors.surfaceVariant,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: SpacingTokens.md,
                                            vertical: SpacingTokens.sm,
                                          ),
                                        ),
                                        style: TextStyle(color: colors.onSurface),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: SpacingTokens.sm),
                                    AsmblButton.primary(
                                      text: 'Send',
                                      icon: Icons.send,
                                      onPressed: _sendMessage,
                                      size: AsmblButtonSize.small,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                agent['icon'] as IconData,
                color: colors.primary,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  agent['name'],
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            agent['task'],
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, ThemeColors colors) {
    final isUser = message['isUser'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: colors.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.psychology,
                size: 12,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && message['agent'] != null) ...[
                  Text(
                    message['agent'],
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                ],
                
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: isUser 
                        ? Border.all(color: colors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(
                    message['content'],
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: SpacingTokens.sm),
            CircleAvatar(
              radius: 12,
              backgroundColor: colors.surfaceVariant,
              child: Icon(
                Icons.person,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.psychology,
              size: 12,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI is thinking',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}