import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

/// Editable conversation title widget with click-to-edit functionality
class EditableConversationTitle extends ConsumerStatefulWidget {
  final Conversation conversation;
  final TextStyle? style;
  
  const EditableConversationTitle({
    super.key,
    required this.conversation,
    this.style,
  });

  @override
  ConsumerState<EditableConversationTitle> createState() => _EditableConversationTitleState();
}

class _EditableConversationTitleState extends ConsumerState<EditableConversationTitle> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _originalTitle = '';
  
  @override
  void initState() {
    super.initState();
    _originalTitle = widget.conversation.title;
    _controller = TextEditingController(text: _originalTitle);
    _focusNode = FocusNode();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(EditableConversationTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversation.title != oldWidget.conversation.title) {
      _originalTitle = widget.conversation.title;
      if (!_isEditing) {
        _controller.text = _originalTitle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isEditing) {
      return _buildEditingMode(theme);
    } else {
      return _buildDisplayMode(theme);
    }
  }

  Widget _buildDisplayMode(ThemeData theme) {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.conversation.title,
                style: widget.style ??
                    GoogleFonts.fustat(
                                            fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            // Edit hint icon
            Icon(
              Icons.edit,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingMode(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ThemeColors(context).primary,
          width: 2,
        ),
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: widget.style ??
                  GoogleFonts.fustat(
                                        fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                hintText: 'Enter conversation title',
                hintStyle: GoogleFonts.fustat(
                                    fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveTitle(),
              onTapOutside: (_) => _cancelEditing(),
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Save button
              IconButton(
                onPressed: _isSaving ? null : _saveTitle,
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeColors(context).success,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.check,
                        size: 18,
                        color: ThemeColors(context).success,
                      ),
                style: IconButton.styleFrom(
                  minimumSize: Size(32, 32),
                  padding: EdgeInsets.all(4),
                ),
                tooltip: 'Save',
              ),
              
              // Cancel button
              IconButton(
                onPressed: _isSaving ? null : _cancelEditing,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                style: IconButton.styleFrom(
                  minimumSize: Size(32, 32),
                  padding: EdgeInsets.all(4),
                ),
                tooltip: 'Cancel',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    if (_isSaving) return;
    
    setState(() {
      _isEditing = true;
      _controller.text = widget.conversation.title;
      _originalTitle = widget.conversation.title;
    });
    
    // Focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _cancelEditing() {
    if (_isSaving) return;
    
    setState(() {
      _isEditing = false;
      _controller.text = _originalTitle;
    });
  }

  void _saveTitle() async {
    if (_isSaving) return;
    
    final newTitle = _controller.text.trim();
    
    // Validate title
    if (newTitle.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }
    
    if (newTitle == _originalTitle) {
      // No change, just exit editing mode
      setState(() {
        _isEditing = false;
      });
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Update conversation title
      final updateConversation = ref.read(updateConversationProvider);
      await updateConversation(
        widget.conversation.id,
        widget.conversation.copyWith(title: newTitle),
      );
      
      // Refresh the conversation data
      ref.invalidate(conversationProvider(widget.conversation.id));
      ref.invalidate(conversationsProvider);
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _originalTitle = newTitle;
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Conversation renamed to "$newTitle"',
                  style: GoogleFonts.fustat(),
                ),
              ],
            ),
            backgroundColor: ThemeColors(context).success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showError('Failed to save title: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.fustat(),
                ),
              ),
            ],
          ),
          backgroundColor: ThemeColors(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}