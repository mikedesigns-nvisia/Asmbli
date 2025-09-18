import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/agent_terminal.dart';
import '../../../../core/services/agent_terminal_manager.dart';
import '../../../../core/services/terminal_output_service.dart';
import 'dart:async';

/// Widget that displays agent terminal output and allows command execution
class AgentTerminalWidget extends ConsumerStatefulWidget {
  final String agentId;
  final bool showCommandInput;
  final double height;

  const AgentTerminalWidget({
    super.key,
    required this.agentId,
    this.showCommandInput = true,
    this.height = 400,
  });

  @override
  ConsumerState<AgentTerminalWidget> createState() => _AgentTerminalWidgetState();
}

class _AgentTerminalWidgetState extends ConsumerState<AgentTerminalWidget> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TerminalOutput> _outputs = [];
  
  StreamSubscription<TerminalOutput>? _outputSubscription;
  bool _isExecuting = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
    _setupScrollListener();
  }

  void _initializeTerminal() {
    // Load existing output history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOutputHistory();
      _listenToTerminalOutput();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Disable auto-scroll if user scrolls up
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.position.pixels >= 
            _scrollController.position.maxScrollExtent - 50;
        if (_autoScroll != isAtBottom) {
          setState(() {
            _autoScroll = isAtBottom;
          });
        }
      }
    });
  }

  void _loadOutputHistory() {
    final outputService = ref.read(terminalOutputServiceProvider);
    final history = outputService.getOutputHistory(widget.agentId, limit: 100);
    
    if (history.isNotEmpty && mounted) {
      setState(() {
        _outputs.addAll(history);
      });
      _scrollToBottom();
    }
  }

  void _listenToTerminalOutput() {
    final terminalManager = ref.read(agentTerminalManagerProvider);
    
    try {
      final stream = terminalManager.streamOutput(widget.agentId);
      _outputSubscription = stream.listen(
        (output) {
          if (mounted) {
            setState(() {
              _outputs.add(output);
              
              // Keep output list manageable
              if (_outputs.length > 1000) {
                _outputs.removeRange(0, _outputs.length - 1000);
              }
            });
            
            if (_autoScroll) {
              _scrollToBottom();
            }
          }
        },
        onError: (error) {
          print('Terminal output stream error: $error');
          if (mounted) {
            setState(() {
              _outputs.add(TerminalOutput(
                agentId: widget.agentId,
                content: 'Stream error: $error',
                type: TerminalOutputType.error,
                timestamp: DateTime.now(),
              ));
            });
          }
        },
      );
    } catch (e) {
      print('Failed to initialize terminal stream: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand() async {
    if (_commandController.text.trim().isEmpty) {
      return;
    }

    final command = _commandController.text.trim();
    _commandController.clear();

    setState(() {
      _isExecuting = true;
      _autoScroll = true; // Re-enable auto-scroll when executing commands
    });

    try {
      final terminalManager = ref.read(agentTerminalManagerProvider);
      await terminalManager.executeCommand(widget.agentId, command);
    } catch (e) {
      if (mounted) {
        final outputService = ref.read(terminalOutputServiceProvider);
        outputService.addOutput(
          widget.agentId,
          TerminalOutput(
            agentId: widget.agentId,
            content: 'Command execution failed: $e',
            type: TerminalOutputType.error,
            timestamp: DateTime.now(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  void _clearTerminal() {
    setState(() {
      _outputs.clear();
    });
    
    final outputService = ref.read(terminalOutputServiceProvider);
    outputService.clearOutput(widget.agentId);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Terminal header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.md),
                topRight: Radius.circular(BorderRadiusTokens.md),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Agent Terminal',
                  style: TextStyles.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Terminal controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_autoScroll)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _autoScroll = true;
                          });
                          _scrollToBottom();
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: colors.primary,
                        ),
                        tooltip: 'Scroll to bottom',
                      ),
                    IconButton(
                      onPressed: _scrollToTop,
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      tooltip: 'Scroll to top',
                    ),
                    IconButton(
                      onPressed: _clearTerminal,
                      icon: Icon(
                        Icons.clear_all,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      tooltip: 'Clear terminal',
                    ),
                    if (_isExecuting)
                      Padding(
                        padding: const EdgeInsets.only(left: SpacingTokens.xs),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Terminal output
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              child: _outputs.isEmpty
                  ? Center(
                      child: Text(
                        'Terminal ready. Execute commands to see output.',
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _outputs.length,
                      itemBuilder: (context, index) {
                        final output = _outputs[index];
                        return _buildOutputLine(output, colors);
                      },
                    ),
            ),
          ),

          // Command input
          if (widget.showCommandInput)
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.border),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '> ',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      enabled: !_isExecuting,
                      style: TextStyles.bodyMedium.copyWith(
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter command...',
                        border: InputBorder.none,
                        hintStyle: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      onSubmitted: (_) => _executeCommand(),
                    ),
                  ),
                  IconButton(
                    onPressed: _isExecuting ? null : _executeCommand,
                    icon: Icon(
                      Icons.send,
                      size: 16,
                      color: _isExecuting ? colors.onSurfaceVariant : colors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputLine(TerminalOutput output, ThemeColors colors) {
    Color textColor;
    String prefix;

    switch (output.type) {
      case TerminalOutputType.command:
        textColor = colors.primary;
        prefix = '> ';
        break;
      case TerminalOutputType.stdout:
        textColor = colors.onSurface;
        prefix = '';
        break;
      case TerminalOutputType.stderr:
        textColor = colors.error;
        prefix = '';
        break;
      case TerminalOutputType.error:
        textColor = colors.error;
        prefix = '❌ ';
        break;
      case TerminalOutputType.system:
        textColor = colors.onSurfaceVariant;
        prefix = '🔧 ';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        '$prefix${output.content}',
        style: TextStyles.bodySmall.copyWith(
          color: textColor,
          fontFamily: 'monospace',
          height: 1.2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}