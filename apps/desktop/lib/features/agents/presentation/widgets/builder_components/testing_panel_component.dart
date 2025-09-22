import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';

/// Testing Panel Component for live agent testing
class TestingPanelComponent extends ConsumerStatefulWidget {
  const TestingPanelComponent({super.key});

  @override
  ConsumerState<TestingPanelComponent> createState() => _TestingPanelComponentState();
}

class _TestingPanelComponentState extends ConsumerState<TestingPanelComponent> {
  final _testMessageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTestRunning = false;

  final List<TestMessage> _testMessages = [];

  @override
  void dispose() {
    _testMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final builderState = ref.watch(agentBuilderStateProvider);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Test chat interface
                Expanded(
                  flex: 2,
                  child: _buildTestChatInterface(builderState, colors),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - Test scenarios and controls
                Expanded(
                  flex: 1,
                  child: _buildTestControls(builderState, colors),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Icon(
            Icons.bug_report,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Testing',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Test your agent configuration before creation',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const Spacer(),
        if (_isTestRunning)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Testing...',
                style: TextStyles.bodySmall.copyWith(color: colors.primary),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTestChatInterface(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Test Conversation',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                AsmblButton.secondary(
                  text: 'Clear Chat',
                  onPressed: _testMessages.isEmpty ? null : _clearChat,
                  icon: Icons.clear_all,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Chat messages area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: _testMessages.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildMessagesList(colors),
              ),
            ),

            const SizedBox(height: SpacingTokens.md),

            // Message input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testMessageController,
                    decoration: InputDecoration(
                      hintText: 'Type a test message...',
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
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: colors.primary),
                        onPressed: _isTestRunning || _testMessageController.text.trim().isEmpty
                            ? null
                            : _sendTestMessage,
                      ),
                    ),
                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    onSubmitted: _isTestRunning ? null : (_) => _sendTestMessage(),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControls(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Quick test scenarios
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Quick Tests',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                ..._getTestScenarios(builderState.category).map((scenario) =>
                  _buildTestScenarioButton(scenario, colors)
                ).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Test results summary
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: colors.accent, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Test Results',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                _buildTestMetric('Messages Sent', _testMessages.where((m) => m.isUser).length.toString(), Icons.send, colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildTestMetric('Responses', _testMessages.where((m) => !m.isUser).length.toString(), Icons.reply, colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildTestMetric('Avg Response Time', '1.2s', Icons.timer, colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildTestMetric('Success Rate', '100%', Icons.check_circle, colors),

                const SizedBox(height: SpacingTokens.md),

                if (_testMessages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.primary, size: 16),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: Text(
                            'Agent responding normally',
                            style: TextStyles.caption.copyWith(color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Agent configuration summary
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: colors.accent, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Current Config',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                _buildConfigItem('Model', '${builderState.modelProvider} ${builderState.modelName}', colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildConfigItem('Category', builderState.category, colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildConfigItem('Tools', '${builderState.selectedTools.length} selected', colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildConfigItem('Files', '${builderState.contextDocuments.length + builderState.knowledgeFiles.length} uploaded', colors),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Start testing your agent',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Send a message or use a quick test scenario',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeColors colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(SpacingTokens.md),
      itemCount: _testMessages.length,
      itemBuilder: (context, index) {
        final message = _testMessages[index];
        return _buildMessageBubble(message, colors);
      },
    );
  }

  Widget _buildMessageBubble(TestMessage message, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xs),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, size: 16, color: colors.accent),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colors.primary
                    : colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                border: message.isUser
                    ? null
                    : Border.all(color: colors.border),
              ),
              child: Text(
                message.content,
                style: TextStyles.bodyMedium.copyWith(
                  color: message.isUser
                      ? Colors.white
                      : colors.onSurface,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xs),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 16, color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestScenarioButton(String scenario, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: SizedBox(
        width: double.infinity,
        child: AsmblButton.secondary(
          text: scenario,
          onPressed: _isTestRunning ? null : () => _runTestScenario(scenario),
          icon: Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildTestMetric(String label, String value, IconData icon, ThemeColors colors) {
    return Row(
      children: [
        Icon(icon, color: colors.accent, size: 16),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
          ),
        ),
        Text(
          value,
          style: TextStyles.bodySmall.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value, ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<String> _getTestScenarios(String category) {
    switch (category) {
      case 'Research':
        return [
          'Find recent studies on AI',
          'Analyze market trends',
          'Compare different solutions',
        ];
      case 'Development':
        return [
          'Review this code snippet',
          'Debug an error',
          'Suggest optimizations',
        ];
      case 'Data Analysis':
        return [
          'Analyze this dataset',
          'Create visualizations',
          'Find correlations',
        ];
      case 'Writing':
        return [
          'Write a blog post intro',
          'Improve this text',
          'Check grammar',
        ];
      default:
        return [
          'Hello, introduce yourself',
          'What can you help me with?',
          'Test your capabilities',
        ];
    }
  }

  Future<void> _sendTestMessage() async {
    final message = _testMessageController.text.trim();
    if (message.isEmpty || _isTestRunning) return;

    setState(() {
      _isTestRunning = true;
      _testMessages.add(TestMessage(content: message, isUser: true));
      _testMessageController.clear();
    });

    _scrollToBottom();

    // Simulate agent response
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _testMessages.add(TestMessage(
          content: _generateMockResponse(message),
          isUser: false,
        ));
        _isTestRunning = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> _runTestScenario(String scenario) async {
    _testMessageController.text = scenario;
    await _sendTestMessage();
  }

  void _clearChat() {
    setState(() {
      _testMessages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateMockResponse(String message) {
    final builderState = ref.read(agentBuilderStateProvider);

    // Generate contextual response based on agent configuration
    final responses = [
      'I understand you\'re asking about "${message.toLowerCase()}". Based on my ${builderState.category.toLowerCase()} specialization, I can help you with that.',
      'Thanks for the question! With my current configuration (${builderState.modelProvider} ${builderState.modelName}), I can provide detailed assistance.',
      'Great question! I have access to ${builderState.selectedTools.length} tools that can help me provide a comprehensive response.',
      'I\'m configured as a ${builderState.category.toLowerCase()} agent with ${builderState.personality.toLowerCase()} personality. Let me help you with that.',
    ];

    return responses[_testMessages.length % responses.length];
  }
}

class TestMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  TestMessage({
    required this.content,
    required this.isUser,
  }) : timestamp = DateTime.now();
}