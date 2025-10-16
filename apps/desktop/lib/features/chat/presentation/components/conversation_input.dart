import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

/// Conversation input component - design system compliant
class ConversationInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmit;

  const ConversationInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  ConsumerState<ConversationInput> createState() => _ConversationInputState();
}

class _ConversationInputState extends ConsumerState<ConversationInput> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: ThemeColors(context).border,
            width: 1,
          ),
        ),
      ),
      child: AsmblCard(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: _keyboardListenerFocusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                      
                      if (isEnterPressed && isShiftPressed && !isLoading) {
                        // Shift+Enter: send message
                        _handleSubmit();
                        return;
                      }
                      // Enter alone: let TextField handle naturally for new line
                    }
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type your message... (Shift+Enter to send, Enter for new line)',
                      hintStyle: TextStyles.bodyMedium.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.lg,
                        vertical: SpacingTokens.md,
                      ),
                    ),
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) => setState(() {}),
                    enabled: !isLoading,
                  ),
                ),
              ),
              
              const SizedBox(width: SpacingTokens.md),
              
              // Send button
              Container(
                decoration: BoxDecoration(
                  color: hasText && !isLoading
                      ? ThemeColors(context).primary
                      : ThemeColors(context).surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(
                    color: ThemeColors(context).border,
                  ),
                ),
                child: IconButton(
                  onPressed: hasText && !isLoading ? _handleSubmit : null,
                  icon: isLoading 
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColors(context).onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          size: 18,
                          color: hasText && !isLoading
                              ? ThemeColors(context).onPrimary
                              : ThemeColors(context).onSurfaceVariant,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !ref.read(isLoadingProvider)) {
      widget.onSubmit(text);
      _focusNode.requestFocus(); // Keep focus for continued typing
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }
}