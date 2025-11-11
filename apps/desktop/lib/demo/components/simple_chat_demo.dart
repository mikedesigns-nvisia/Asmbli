import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/design_system/design_system.dart';
import '../models/demo_models.dart';

/// Simplified chat demo for testing
class SimpleChatDemo extends StatefulWidget {
  final String scenario;
  final Function(HumanIntervention)? onInterventionNeeded;

  const SimpleChatDemo({
    super.key,
    required this.scenario,
    this.onInterventionNeeded,
  });

  @override
  State<SimpleChatDemo> createState() => SimpleChatDemoState();
}

class SimpleChatDemoState extends State<SimpleChatDemo> {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startDemo();
  }

  void _startDemo() {
    // AI greets first
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showTypingIndicator(false);
        _addMessage(_getInitialMessage(), isUser: false);
      }
    });

    // User responds after reading
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _addMessage(_getUserMessage(), isUser: true);
      }
    });

    // AI thinks and responds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _showTypingIndicator(false);
      }
    });
    
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _hideTypingIndicator();
        _addMessage(_getAnalysisMessage(), isUser: false);
      }
    });

    // Optional intervention (only sometimes)
    if (widget.scenario.contains('operations')) {
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted && widget.onInterventionNeeded != null) {
          widget.onInterventionNeeded!(
            HumanIntervention(
              reason: 'Validation needed for resource allocation changes',
              confidence: 0.68,
              recommendation: 'Review proposed schedule modifications',
            ),
          );
        }
      });
    }
  }
  
  void _showTypingIndicator(bool isUser) {
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
    }
  }
  
  void _hideTypingIndicator() {
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  String _getInitialMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'Hello! I am your Operations Manager AI. I can help optimize scheduling, set up smart notifications, and streamline your operational workflows.';
      case 'business-analyst':
        return 'Hello! I am your Business Analyst AI. I can transform data into actionable insights with real-time visualization and predictive analytics.';
      case 'design-assistant':
        return 'Hello! I am your Design Assistant AI. I can create visual designs from your conversations and generate components instantly.';
      default:
        return 'Hello! I am your AI assistant. How can I help you today?';
    }
  }

  String _getUserMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'I need help optimizing our team schedules and setting up automated notifications for project deadlines.';
      case 'business-analyst':
        return 'Can you analyze our sales performance data and identify key trends for Q4 planning?';
      case 'design-assistant':
        return 'I need to create a dashboard interface for our project management tool. Can you help design it?';
      default:
        return 'Can you help me analyze this data?';
    }
  }

  String _getAnalysisMessage() {
    switch (widget.scenario) {
      case 'operations-manager':
        return 'I have analyzed your current scheduling patterns and identified 3 optimization opportunities. I am setting up smart notifications for critical deadlines and resource conflicts. Confidence: 94%';
      case 'business-analyst':
        return 'Based on your Q3 data, I have identified a 23% increase in conversion rates for mobile users. I am generating predictive models for Q4 forecasting. Confidence: 97%';
      case 'design-assistant':
        return 'I am creating your dashboard design with modern card layouts, data visualizations, and responsive components. The design will appear on the canvas shortly. Confidence: 91%';
      default:
        return 'I am analyzing the data and will provide insights shortly...';
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, color: colors.primary),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'AI Chat - ${widget.scenario}',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message, colors);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    'AI is thinking...',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: colors.surface,
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: message.isUser 
                  ? colors.primary 
                  : colors.background,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                border: message.isUser 
                  ? null 
                  : Border.all(color: colors.border),
              ),
              child: Text(
                message.text,
                style: TextStyles.bodyMedium.copyWith(
                  color: message.isUser 
                    ? colors.surface 
                    : colors.onSurface,
                ),
              ),
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: SpacingTokens.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.accent,
              child: Icon(
                Icons.person,
                size: 16,
                color: colors.surface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}