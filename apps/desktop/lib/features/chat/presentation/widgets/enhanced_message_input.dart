import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';

class EnhancedMessageInput extends ConsumerStatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final bool isLoading;

  const EnhancedMessageInput({
    super.key,
    required this.messageController,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  ConsumerState<EnhancedMessageInput> createState() => _EnhancedMessageInputState();
}

class _EnhancedMessageInputState extends ConsumerState<EnhancedMessageInput> {
  bool _isComposing = false;
  
  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = widget.messageController.text.trim().isNotEmpty;
    if (_isComposing != isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  bool get _canSend => _isComposing && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
      child: Column(
        children: [
          // Character count indicator (shown when typing)
          if (_isComposing && widget.messageController.text.length > 100)
            Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
              alignment: Alignment.centerRight,
              child: Text(
                '${widget.messageController.text.length} characters',
                style: TextStyles.caption.copyWith(
                  color: widget.messageController.text.length > 2000
                    ? ThemeColors(context).error
                    : ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ),
          
          // Main input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors(context).surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(
                      color: _isComposing 
                        ? ThemeColors(context).primary.withValues(alpha: 0.5)
                        : ThemeColors(context).border,
                      width: _isComposing ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: widget.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message... (Enter to send, Shift+Enter for new line)',
                      hintStyle: TextStyles.bodyMedium.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.lg,
                        vertical: SpacingTokens.md,
                      ),
                      suffixIcon: _isComposing
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: ThemeColors(context).onSurfaceVariant,
                            ),
                            onPressed: () {
                              widget.messageController.clear();
                              setState(() {
                                _isComposing = false;
                              });
                            },
                            tooltip: 'Clear message',
                          )
                        : null,
                    ),
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    maxLength: 4000, // Reasonable limit
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Hide counter
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (value) {
                      if (_canSend) {
                        widget.onSendMessage();
                      }
                    },
                    onTapOutside: (event) {
                      // Remove focus when tapping outside
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: SpacingTokens.md),
              
              // Send button with enhanced states
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _canSend
                    ? LinearGradient(
                        colors: [
                          ThemeColors(context).primary,
                          ThemeColors(context).primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                  color: _canSend 
                    ? null
                    : ThemeColors(context).surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  boxShadow: _canSend
                    ? [
                        BoxShadow(
                          color: ThemeColors(context).primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    onTap: _canSend ? widget.onSendMessage : null,
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.md),
                      child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _canSend
                              ? Colors.white
                              : ThemeColors(context).onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Helpful shortcuts info (shown when focused)
          if (_isComposing)
            Container(
              margin: const EdgeInsets.only(top: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: ThemeColors(context).onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    'Press Enter to send • Shift+Enter for new line',
                    style: TextStyles.caption.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                      fontSize: 11,
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